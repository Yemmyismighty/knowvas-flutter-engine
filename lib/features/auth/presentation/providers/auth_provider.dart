import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../shared/models/auth_response.dart';
import '../../../../shared/models/user.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_provider.dart';
import 'auth_state.dart';

part 'auth_provider.g.dart';

/// AuthNotifier manages authentication state
/// Handles sign in, sign up, sign out, and token refresh
/// Persists authentication state across app restarts
@riverpod
class Auth extends _$Auth {
  @override
  AuthState build() {
    // Initialize by checking for existing session
    // Use Future.microtask to avoid calling async in build
    Future.microtask(() => _initializeAuth());
    return AuthState.initial();
  }

  /// Initialize authentication state by checking for stored tokens
  Future<void> _initializeAuth() async {
    try {
      final repository = ref.read<AuthRepository>(authRepositoryProvider);
      
      // Check if we have tokens
      final accessToken = await repository.getAccessToken();
      final refreshToken = await repository.getRefreshToken();
      
      debugPrint('🔐 Auth init: accessToken=${accessToken != null}, refreshToken=${refreshToken != null}');

      if (accessToken == null || refreshToken == null) {
        debugPrint('ℹ️ No tokens found - user is not authenticated');
        state = AuthState.unauthenticated();
        return;
      }

      // Check if session is still valid (within 30 days)
      final isSessionValid = await repository.isSessionValid();
      if (!isSessionValid) {
        debugPrint('❌ Session expired (>30 days) - clearing tokens');
        await repository.signOut();
        state = AuthState.unauthenticated();
        return;
      }

      // Check if refresh token is expired
      final isRefreshTokenExpired = await repository.isRefreshTokenExpired();
      if (isRefreshTokenExpired) {
        debugPrint('❌ Refresh token expired - clearing session');
        await repository.signOut();
        state = AuthState.unauthenticated();
        return;
      }

      // Check if access token needs refresh
      final isAccessTokenExpired = await repository.isAccessTokenExpired();
      if (isAccessTokenExpired) {
        debugPrint('🔄 Access token expired - attempting refresh');
        try {
          await repository.refreshToken();
          debugPrint('✅ Token refresh successful - user is authenticated');
        } catch (e) {
          debugPrint('❌ Token refresh failed: $e - but keeping session (might be network issue)');
          // Don't clear session immediately - could be a network issue
          // The auth interceptor will handle this when making actual requests
        }
      }

      // User is authenticated - tokens exist and session is valid
      debugPrint('✅ User is authenticated');
      
      // Try to load stored user data first
      final storedUser = await repository.getStoredUserData();
      if (storedUser != null) {
        debugPrint('✅ Loaded stored user data: ${storedUser.email}');
        state = AuthState.authenticated(storedUser);
        
        // Try to refresh user data in background
        _fetchUserProfileInBackground();
      } else {
        debugPrint('ℹ️ No stored user data, will fetch from server');
        // Mark as authenticated but try to fetch user data
        state = const AuthState(
          isAuthenticated: true,
          isInitialized: true,
        );
        
        // Try to fetch current user data (don't await to avoid blocking)
        _fetchUserProfileInBackground();
      }
      
    } catch (e) {
      // If initialization fails, assume unauthenticated
      debugPrint('⚠️ Auth initialization error: $e');
      state = AuthState.unauthenticated();
    }
  }

  /// Called by the AuthInterceptor when a token refresh fails (401 on /me or /refresh).
  /// Equivalent to the web's auth:session-expired event handler.
  void handleSessionExpired() {
    debugPrint('🔴 Session expired — clearing auth state');
    state = AuthState.sessionExpired();
  }

  /// Called by the AuthInterceptor when /api/auth/me returns device_removed.
  void handleDeviceRemoved() {
    debugPrint('🔴 Device removed — clearing auth state');
    state = AuthState.deviceRemoved();
  }

  /// Equivalent to the web's checkSessionValidity().
  /// Hits /api/auth/me and reacts to the response.
  /// Called on app resume and periodically while authenticated.
  Future<void> checkSessionValidity() async {
    if (!state.isAuthenticated) return;

    try {
      final repository = ref.read<AuthRepository>(authRepositoryProvider);
      final response = await repository.checkSession();

      if (response == SessionCheckResult.ok) return;

      if (response == SessionCheckResult.deviceRemoved) {
        debugPrint('🔴 Session check: device removed');
        state = AuthState.deviceRemoved();
      } else if (response == SessionCheckResult.sessionExpired) {
        debugPrint('🔴 Session check: session expired');
        state = AuthState.sessionExpired();
      }
    } catch (e) {
      // Network error — don't sign out, same as web behaviour
      debugPrint('⚠️ Session check failed (network?): $e');
    }
  }

  /// Clear the session-terminated flag after the user has acknowledged it
  /// and been redirected to the sign-in screen.
  void clearSessionTermination() {
    state = AuthState.unauthenticated();
  }

  /// Sign in with Google
  /// Gets Google ID token natively, sends to backend, authenticates user
  Future<void> googleSignIn() async {
    state = state.copyWithLoading();

    try {
      // Step 1: get the Google ID token from the device
      final idToken = await GoogleAuthService.getIdToken();
      if (idToken == null) {
        // User cancelled the Google sign-in dialog — just reset, no error
        state = AuthState.unauthenticated();
        return;
      }

      debugPrint('🔵 Google Sign-In: sending idToken to backend');

      // Step 2: send the token to our backend
      final repository = ref.read<AuthRepository>(authRepositoryProvider);
      final authResponse = await repository.googleSignIn(
        idToken: idToken,
        deviceName: 'Mobile Device',
      );

      debugPrint('✅ Google Sign-In: backend success, user=${authResponse.user.email}');
      state = AuthState.authenticated(authResponse.user);
    } on DeviceLimitFailure catch (e) {
      state = AuthState.deviceLimitReached(e.deviceManagementToken);
    } on AuthFailure catch (e) {
      debugPrint('❌ Google Sign-In AuthFailure: ${e.message}');
      state = state.copyWithError(e.message);
    } on NetworkFailure catch (e) {
      debugPrint('❌ Google Sign-In NetworkFailure: ${e.message}');
      state = state.copyWithError(e.message);
    } on ServerFailure catch (e) {
      debugPrint('❌ Google Sign-In ServerFailure: ${e.message}');
      state = state.copyWithError(e.message);
    } catch (e) {
      debugPrint('❌ Google Sign-In unexpected error: $e');
      state = state.copyWithError(e.toString());
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWithLoading();

    try {
      final repository = ref.read<AuthRepository>(authRepositoryProvider);
      final authResponse = await repository.signIn(
        email: email,
        password: password,
      );

      state = AuthState.authenticated(authResponse.user);
    } on DeviceLimitFailure catch (e) {
      // Backend returned 403 with manage_devices: true
      state = AuthState.deviceLimitReached(e.deviceManagementToken);
    } on AuthFailure catch (e) {
      state = state.copyWithError(e.message);
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
    } catch (e) {
      state = state.copyWithError('An unexpected error occurred: $e');
    }
  }

  /// Sign up with user details
  /// Sends verification code to email
  /// Does NOT authenticate user - they must verify email first
  Future<void> signUp({
    required SignUpData signUpData,
  }) async {
    state = state.copyWithLoading();

    try {
      final repository = ref.read<AuthRepository>(authRepositoryProvider);
      await repository.signUp(
        signUpData: signUpData,
      );

      // Don't authenticate yet - user needs to verify email
      // Clear loading state but keep unauthenticated
      state = AuthState.unauthenticated();
    } on AuthFailure catch (e) {
      state = state.copyWithError(e.message);
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
    } catch (e) {
      state = state.copyWithError('An unexpected error occurred: $e');
    }
  }

  /// Verify email with code
  /// Authenticates user on success
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWithLoading();

    try {
      final repository = ref.read<AuthRepository>(authRepositoryProvider);
      final authResponse = await repository.verifyEmail(
        email: email,
        code: code,
      );

      state = AuthState.authenticated(authResponse.user);
    } on AuthFailure catch (e) {
      state = state.copyWithError(e.message);
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
    } catch (e) {
      state = state.copyWithError('An unexpected error occurred: $e');
    }
  }

  /// Resend verification code to email
  Future<void> resendVerificationCode({
    required String email,
  }) async {
    try {
      final repository = ref.read<AuthRepository>(authRepositoryProvider);
      await repository.resendVerificationCode(email: email);
    } on AuthFailure catch (e) {
      state = state.copyWithError(e.message);
      rethrow;
    } on NetworkFailure catch (e) {
      state = state.copyWithError(e.message);
      rethrow;
    } on ServerFailure catch (e) {
      state = state.copyWithError(e.message);
      rethrow;
    } catch (e) {
      state = state.copyWithError('An unexpected error occurred: $e');
      rethrow;
    }
  }

  /// Sign out and clear authentication state
  /// Always clears local state even if backend call fails
  Future<void> signOut() async {
    try {
      final repository = ref.read<AuthRepository>(authRepositoryProvider);
      await repository.signOut();
      
      // Delete FCM token on logout
      try {
        final pushService = PushNotificationService();
        await pushService.deleteToken();
        debugPrint('✅ FCM token deleted on logout');
      } catch (e) {
        debugPrint('⚠️ Failed to delete FCM token: $e');
      }
    } catch (_) {
      // Log error but continue with local sign out
      // In production, you might want to log this to analytics
    } finally {
      // Always clear local state
      state = AuthState.unauthenticated();
    }
  }

  /// Refresh access token using refresh token
  /// Updates stored tokens on success
  /// Signs out user on failure (invalid/expired refresh token)
  Future<bool> refreshToken() async {
    try {
      final repository = ref.read<AuthRepository>(authRepositoryProvider);
      await repository.refreshToken();
      return true;
    } on AuthFailure catch (_) {
      // Refresh token is invalid or expired
      // Sign out the user
      await signOut();
      return false;
    } catch (_) {
      // Other errors - don't sign out, might be temporary network issue
      return false;
    }
  }

  /// Update user data in state
  /// Used when user profile is updated
  void updateUser(User user) {
    if (state.isAuthenticated) {
      state = AuthState.authenticated(user);
    }
  }

  /// Clear error message
  void clearError() {
    if (state.error != null) {
      state = state.copyWith();
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated;

  /// Get current user
  User? get currentUser => state.user;

  /// Fetch current user profile
  /// Used to load user data when not available in state
  Future<void> fetchUserProfile() async {
    if (!state.isAuthenticated) return;

    try {
      final repository = ref.read<AuthRepository>(authRepositoryProvider);
      final user = await repository.getCurrentUser();
      
      state = AuthState.authenticated(user);
    } catch (e) {
      debugPrint('Failed to fetch user profile: $e');
      // Don't update state on error - keep existing state
    }
  }

  /// Fetch user profile in background without blocking authentication
  Future<void> _fetchUserProfileInBackground() async {
    try {
      final repository = ref.read<AuthRepository>(authRepositoryProvider);
      final user = await repository.getCurrentUser();
      debugPrint('✅ User profile loaded in background: ${user.email}');
      if (state.isAuthenticated) {
        state = AuthState.authenticated(user);
      }
    } on AuthFailure catch (e) {
      // 401 from /api/auth/me — session is invalid, sign out
      debugPrint('🔴 Profile fetch returned 401 (${e.code}) — signing out');
      await signOut();
    } catch (e) {
      // Network error — keep existing state, don't sign out
      debugPrint('⚠️ Failed to load user profile in background (network?): $e');
    }
  }
}
