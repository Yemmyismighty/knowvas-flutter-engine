import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/security/secure_storage.dart';
import '../../../../core/services/device_service.dart';
import '../../../../shared/models/auth_response.dart';
import '../../../../shared/models/reading_stats.dart';
import '../../../../shared/models/user.dart';
import '../../../../shared/models/user_preferences.dart';

enum SessionCheckResult { ok, sessionExpired, deviceRemoved }

/// Repository for authentication operations
/// Handles sign in, sign up, token refresh, and sign out
class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureStorage secureStorage,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage;

  final ApiClient _apiClient;
  final SecureStorage _secureStorage;

  /// Sign in with email and password
  /// Returns AuthResponse with tokens and user data
  /// Throws AuthFailure on authentication errors
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
          'use_jwt': true,
          'deviceName': await DeviceService.instance.getDeviceName(),
        },
      );

      // Handle successful response
      if (response.statusCode == 200 && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        
        // Store tokens securely
        await _storeTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          userId: authResponse.user.id,
        );

        // Store user data
        await _storeUserData(authResponse.user);

        return authResponse;
      }
      
      // Handle error responses
      final statusCode = response.statusCode;
      final data = response.data;
      String errorMessage = 'Sign in failed';
      String errorCode = 'SIGN_IN_FAILED';

      if (data is Map<String, dynamic>) {
        // Extract error message from response
        errorMessage = data['error'] as String? ?? 
                     data['message'] as String? ?? 
                     data['detail'] as String? ?? 
                     errorMessage;
        
        // Handle specific error cases
        if (statusCode == 403 && data['manage_devices'] == true) {
          final token = data['device_management_token'] as String? ?? '';
          throw DeviceLimitFailure(token);
        } else if (statusCode == 401) {
          errorCode = 'INVALID_CREDENTIALS';
        } else if (statusCode == 400) {
          errorCode = 'INVALID_REQUEST';
        }
      }

      if (statusCode == 401 || statusCode == 403) {
        throw AuthFailure(errorMessage, code: errorCode);
      } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        throw AuthFailure(errorMessage, code: errorCode);
      } else if (statusCode != null && statusCode >= 500) {
        throw ServerFailure(
          errorMessage,
          statusCode: statusCode,
          code: errorCode,
        );
      } else {
        throw AuthFailure(errorMessage, code: errorCode);
      }
    } on Failure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure(
        'An unexpected error occurred during sign in: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Sign up with user details
  /// Sends verification code to email
  /// Does NOT return tokens - user must verify email first
  /// Throws AuthFailure on validation or registration errors
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<void> signUp({
    required SignUpData signUpData,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.signup,
        data: signUpData.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Signup successful - verification code sent to email
        // Don't store tokens yet - user needs to verify email
        return;
      }
      
      // Handle error response
      final data = response.data;
      String errorMessage = 'Sign up failed';
      
      if (data is Map<String, dynamic>) {
        errorMessage = data['error'] as String? ?? 
                     data['message'] as String? ?? 
                     errorMessage;
      }
      
      throw AuthFailure(errorMessage, code: 'SIGN_UP_FAILED');
    } on Failure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure(
        'An unexpected error occurred during sign up: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Verify email with code
  /// Returns AuthResponse with tokens and user data
  /// Throws AuthFailure on invalid code or verification errors
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<AuthResponse> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.verifyEmail,
        data: {
          'email': email,
          'code': code,
          'use_jwt': true, // Request JWT tokens for mobile
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);
        
        // Store tokens securely
        await _storeTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          userId: authResponse.user.id,
        );

        // Store user data
        await _storeUserData(authResponse.user);

        return authResponse;
      }
      
      // Handle error response
      final data = response.data;
      String errorMessage = 'Email verification failed';
      
      if (data is Map<String, dynamic>) {
        errorMessage = data['error'] as String? ?? 
                     data['message'] as String? ?? 
                     errorMessage;
      }
      
      throw AuthFailure(errorMessage, code: 'VERIFICATION_FAILED');
    } on Failure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure(
        'An unexpected error occurred during email verification: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Resend verification code to email
  /// Throws AuthFailure on errors
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<void> resendVerificationCode({
    required String email,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.resendVerification,
        data: {
          'email': email,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        // Handle error response
        final data = response.data;
        String errorMessage = 'Failed to resend verification code';
        
        if (data is Map<String, dynamic>) {
          errorMessage = data['error'] as String? ?? 
                       data['message'] as String? ?? 
                       errorMessage;
        }
        
        throw AuthFailure(errorMessage, code: 'RESEND_FAILED');
      }
    } on Failure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure(
        'An unexpected error occurred while resending verification code: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Refresh access token using refresh token
  /// Returns TokenResponse with new tokens
  /// Throws AuthFailure if refresh token is invalid or expired
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<TokenResponse> refreshToken() async {
    try {
      // Get stored refresh token
      final refreshToken = await _secureStorage.read(
        key: StorageKeys.refreshToken,
      );

      if (refreshToken == null) {
        throw const AuthFailure(
          'No refresh token found',
          code: 'NO_REFRESH_TOKEN',
        );
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.refresh,
        data: {
          'refresh_token': refreshToken,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $refreshToken',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final tokenResponse = TokenResponse.fromJson(response.data!);
        
        // Update stored tokens
        await _updateTokens(
          accessToken: tokenResponse.accessToken,
          refreshToken: tokenResponse.refreshToken,
        );

        return tokenResponse;
      } else {
        throw const AuthFailure(
          'Token refresh failed',
          code: 'REFRESH_FAILED',
        );
      }
    } on Failure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on CacheException catch (e) {
      throw AuthFailure(
        'Failed to access stored tokens: ${e.message}',
        code: e.code,
      );
    } on AppException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure(
        'An unexpected error occurred during token refresh: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Request password reset
  /// Sends password reset email to the provided email address
  /// Throws AuthFailure on validation errors
  /// Throws NetworkFailure on network errors
  /// Throws ServerFailure on server errors
  Future<void> requestPasswordReset({
    required String email,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.forgotPassword,
        data: {
          'email': email,
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw const AuthFailure(
          'Password reset request failed',
          code: 'PASSWORD_RESET_FAILED',
        );
      }
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw AuthFailure(
        'An unexpected error occurred during password reset request: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Check session validity by hitting /api/auth/me.
  /// Equivalent to the web's checkSessionValidity() in auth-context.tsx.
  /// Returns ok, sessionExpired, or deviceRemoved.
  Future<SessionCheckResult> checkSession() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.profile,
      );

      if (response.statusCode == 200) return SessionCheckResult.ok;

      if (response.statusCode == 401) {
        final reason = response.data?['reason'] as String?;
        if (reason == 'device_removed') return SessionCheckResult.deviceRemoved;
        return SessionCheckResult.sessionExpired;
      }

      // Any other non-200 — treat as temporary, don't kill the session
      return SessionCheckResult.ok;
    } catch (e) {
      // Network error — don't kill the session
      return SessionCheckResult.ok;
    }
  }

  /// Sign out and clear all stored tokens
  /// Optionally calls backend logout endpoint
  /// Always clears local tokens even if backend call fails
  Future<void> signOut() async {
    try {
      // Try to call backend logout endpoint
      // Don't throw if this fails - we still want to clear local tokens
      try {
        final accessToken = await _secureStorage.read(
          key: StorageKeys.accessToken,
        );
        final deviceId = await DeviceService.instance.getDeviceId();
        final deviceName = await DeviceService.instance.getDeviceName();

        if (accessToken != null) {
          // Must include Authorization, X-Device-ID, and X-Device-Name so the
          // backend can identify and delete the correct UserDevice record.
          await _apiClient.post<Map<String, dynamic>>(
            ApiConstants.logout,
            options: Options(
              headers: {
                'Authorization': 'Bearer $accessToken',
                'X-Device-ID': deviceId,
                'X-Device-Name': deviceName,
              },
            ),
          );
          debugPrint('✅ signOut: device $deviceId removed from backend');
        }
      } catch (e) {
        debugPrint('⚠️ signOut: backend call failed (continuing): $e');
      }

      // Clear all stored tokens and user data
      await _clearTokens();
    } on CacheException catch (e) {
      throw AuthFailure(
        'Failed to clear stored tokens: ${e.message}',
        code: e.code,
      );
    } catch (e) {
      throw AuthFailure(
        'An unexpected error occurred during sign out: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get stored access token
  /// Returns null if no token is stored
  Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: StorageKeys.accessToken);
    } on CacheException {
      return null;
    }
  }

  /// Get stored refresh token
  /// Returns null if no token is stored
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: StorageKeys.refreshToken);
    } on CacheException {
      return null;
    }
  }

  /// Get stored user ID
  /// Returns null if no user ID is stored
  Future<String?> getUserId() async {
    try {
      return await _secureStorage.read(key: StorageKeys.userId);
    } on CacheException {
      return null;
    }
  }

  /// Get current user profile from the server.
  /// Throws [AuthFailure] on 401 so the caller can sign the user out.
  /// Throws [NetworkFailure] on network errors.
  Future<User> getCurrentUser() async {
    try {
      debugPrint('🔄 Fetching user profile from: ${ApiConstants.profile}');

      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.profile,
      );

      debugPrint('📡 Profile response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final user = User.fromJson(response.data!);
        await _storeUserData(user);
        return user;
      }

      if (response.statusCode == 401) {
        // Session is invalid — caller must sign the user out
        final reason = response.data?['reason'] as String? ?? 'invalid';
        throw AuthFailure('Session invalid: $reason', code: reason);
      }

      debugPrint('⚠️ Profile fetch failed with status: ${response.statusCode}');
      throw AuthFailure('Profile fetch failed', code: 'PROFILE_FAILED');
    } on Failure {
      rethrow;
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } catch (e) {
      if (e is Failure) rethrow;
      throw NetworkFailure('Profile fetch error: $e', code: 'NETWORK_ERROR');
    }
  }

  /// Create a fallback user when server profile fetch fails
  /// Uses stored user ID and creates basic user data
  Future<User> createFallbackUser() async {
    final userId = await getUserId();
    const preferences = UserPreferences();
    const stats = ReadingStats();

    // Safe substring — userId may be short (e.g. "12")
    final suffix = userId != null && userId.length >= 4
        ? userId.substring(0, 4)
        : (userId ?? '0000').padRight(4, '0');

    final fallbackUser = User(
      id: userId ?? 'unknown',
      email: 'user@example.com',
      username: 'user$suffix',
      firstName: 'User',
      lastName: '',
      preferences: preferences,
      stats: stats,
    );

    debugPrint('✅ Created fallback user: ${fallbackUser.username}');
    await _storeUserData(fallbackUser);
    return fallbackUser;
  }

  /// Check if user is authenticated (has valid tokens)
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    
    if (accessToken == null || refreshToken == null) {
      return false;
    }

    // Check if session is still valid (within 30 days)
    return await isSessionValid();
  }

  /// Check if the current session is still valid (within 30 days of last login)
  Future<bool> isSessionValid() async {
    try {
      final lastLoginTimeStr = await _secureStorage.read(key: StorageKeys.lastLoginTime);
      if (lastLoginTimeStr == null) {
        return false;
      }

      final lastLoginTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(lastLoginTimeStr),
      );
      final now = DateTime.now();
      final sessionDuration = now.difference(lastLoginTime);

      // Session is valid for 30 days
      return sessionDuration.inDays < 30;
    } catch (e) {
      return false;
    }
  }

  /// Check if access token is expired
  Future<bool> isAccessTokenExpired() async {
    try {
      final expiryStr = await _secureStorage.read(key: StorageKeys.accessTokenExpiry);
      if (expiryStr == null) {
        return true; // Assume expired if no expiry time stored
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
      final now = DateTime.now();
      
      // Add 5 minute buffer to avoid edge cases
      return now.isAfter(expiry.subtract(const Duration(minutes: 5)));
    } catch (e) {
      return true; // Assume expired on error
    }
  }

  /// Check if refresh token is expired
  Future<bool> isRefreshTokenExpired() async {
    try {
      final expiryStr = await _secureStorage.read(key: StorageKeys.refreshTokenExpiry);
      if (expiryStr == null) {
        return true; // Assume expired if no expiry time stored
      }

      final expiry = DateTime.fromMillisecondsSinceEpoch(int.parse(expiryStr));
      final now = DateTime.now();
      
      return now.isAfter(expiry);
    } catch (e) {
      return true; // Assume expired on error
    }
  }

  /// Store tokens securely with expiry times
  Future<void> _storeTokens({
    required String accessToken,
    required String refreshToken,
    required String userId,
  }) async {
    // Calculate expiry times
    final now = DateTime.now();
    final accessTokenExpiry = now.add(const Duration(hours: 1)); // Access token expires in 1 hour
    final refreshTokenExpiry = now.add(const Duration(days: 30)); // Refresh token expires in 30 days
    final lastLoginTime = now;

    await Future.wait([
      _secureStorage.write(
        key: StorageKeys.accessToken,
        value: accessToken,
      ),
      _secureStorage.write(
        key: StorageKeys.refreshToken,
        value: refreshToken,
      ),
      _secureStorage.write(
        key: StorageKeys.userId,
        value: userId,
      ),
      _secureStorage.write(
        key: StorageKeys.accessTokenExpiry,
        value: accessTokenExpiry.millisecondsSinceEpoch.toString(),
      ),
      _secureStorage.write(
        key: StorageKeys.refreshTokenExpiry,
        value: refreshTokenExpiry.millisecondsSinceEpoch.toString(),
      ),
      _secureStorage.write(
        key: StorageKeys.lastLoginTime,
        value: lastLoginTime.millisecondsSinceEpoch.toString(),
      ),
    ]);
  }

  /// Store user data from login/signup response
  Future<void> _storeUserData(User user) async {
    try {
      await _secureStorage.write(
        key: StorageKeys.userData,
        value: jsonEncode(user.toJson()),
      );
    } catch (e) {
      debugPrint('Failed to store user data: $e');
      // Don't throw - this is not critical
    }
  }

  /// Get stored user data
  Future<User?> getStoredUserData() async {
    try {
      final userDataStr = await _secureStorage.read(key: StorageKeys.userData);
      if (userDataStr != null) {
        final userJson = jsonDecode(userDataStr) as Map<String, dynamic>;
        return User.fromJson(userJson);
      }
    } catch (e) {
      debugPrint('Failed to read stored user data: $e');
    }
    return null;
  }

  /// Update stored tokens with new expiry times
  Future<void> _updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // Calculate new expiry times
    final now = DateTime.now();
    final accessTokenExpiry = now.add(const Duration(hours: 1));
    final refreshTokenExpiry = now.add(const Duration(days: 30));

    await Future.wait([
      _secureStorage.write(
        key: StorageKeys.accessToken,
        value: accessToken,
      ),
      _secureStorage.write(
        key: StorageKeys.refreshToken,
        value: refreshToken,
      ),
      _secureStorage.write(
        key: StorageKeys.accessTokenExpiry,
        value: accessTokenExpiry.millisecondsSinceEpoch.toString(),
      ),
      _secureStorage.write(
        key: StorageKeys.refreshTokenExpiry,
        value: refreshTokenExpiry.millisecondsSinceEpoch.toString(),
      ),
    ]);
  }

  /// Clear all stored tokens and user data
  Future<void> _clearTokens() async {
    await Future.wait([
      _secureStorage.delete(key: StorageKeys.accessToken),
      _secureStorage.delete(key: StorageKeys.refreshToken),
      _secureStorage.delete(key: StorageKeys.userId),
      _secureStorage.delete(key: StorageKeys.accessTokenExpiry),
      _secureStorage.delete(key: StorageKeys.refreshTokenExpiry),
      _secureStorage.delete(key: StorageKeys.lastLoginTime),
      _secureStorage.delete(key: StorageKeys.userData),
    ]);
  }

  /// Sign in / sign up with Google ID token
  /// Sends the Google idToken to the backend which verifies it and returns JWT tokens
  Future<AuthResponse> googleSignIn({
    required String idToken,
    String deviceName = 'Mobile Device',
  }) async {
    try {
      // Get the real device name from hardware
      final realDeviceName = await DeviceService.instance.getDeviceName();

      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.googleLogin,
        data: {
          'idToken': idToken,
          'deviceName': realDeviceName,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final authResponse = AuthResponse.fromJson(response.data!);

        await _storeTokens(
          accessToken: authResponse.accessToken,
          refreshToken: authResponse.refreshToken,
          userId: authResponse.user.id,
        );
        await _storeUserData(authResponse.user);

        return authResponse;
      }

      final data = response.data;
      debugPrint('🔵 googleSignIn: status=${response.statusCode} body=$data');
      String errorMessage = 'Google sign in failed';

      if (data is Map<String, dynamic>) {
        errorMessage = data['error'] as String? ?? data['message'] as String? ?? errorMessage;

        if (response.statusCode == 403 && data['manage_devices'] == true) {
          final token = data['device_management_token'] as String? ?? '';
          debugPrint('🔵 googleSignIn: device limit reached, token=$token');
          throw DeviceLimitFailure(token);
        }
      }

      debugPrint('❌ googleSignIn: throwing AuthFailure: $errorMessage');
      throw AuthFailure(errorMessage, code: 'GOOGLE_SIGN_IN_FAILED');
    } on Failure {
      rethrow;
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      if (e is AuthFailure || e is NetworkFailure || e is ServerFailure || e is DeviceLimitFailure) rethrow;
      throw AuthFailure('An unexpected error occurred during Google sign in: $e', code: 'UNKNOWN_ERROR');
    }
  }

  /// Complete user profile with DOB, gender, and city  /// Matches web app's /api/auth/complete-profile endpoint
  Future<void> completeProfile({
    required String dateOfBirth,
    required String gender,
    required String city,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.completeProfile,
        data: {
          'dateOfBirth': dateOfBirth,
          'gender': gender,
          'city': city,
        },
      );

      if (response.statusCode == 200) return;

      final msg = response.data?['error'] as String? ?? 'Failed to complete profile';
      throw AuthFailure(msg, code: 'COMPLETE_PROFILE_FAILED');
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      if (e is AuthFailure || e is NetworkFailure || e is ServerFailure) rethrow;
      throw AuthFailure('Failed to complete profile: $e', code: 'UNKNOWN_ERROR');
    }
  }
}
