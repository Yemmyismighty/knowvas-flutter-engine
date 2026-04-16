import 'package:equatable/equatable.dart';

import '../../../../shared/models/user.dart';

/// Authentication state
class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.deviceManagementToken,
  });

  factory AuthState.initial() {
    return const AuthState(isLoading: true);
  }

  factory AuthState.authenticated(User user) {
    return AuthState(user: user, isAuthenticated: true, isInitialized: true);
  }

  factory AuthState.unauthenticated() {
    return const AuthState(isInitialized: true);
  }

  /// Device limit reached - user must manage devices before signing in
  factory AuthState.deviceLimitReached(String token) {
    return AuthState(
      isInitialized: true,
      deviceManagementToken: token,
    );
  }

  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  /// Non-null when the backend returns a device limit error.
  /// The sign-in screen should navigate to manage-devices with this token.
  final String? deviceManagementToken;

  bool get requiresDeviceManagement => deviceManagementToken != null;

  AuthState copyWithLoading() {
    return AuthState(
      user: user,
      isAuthenticated: isAuthenticated,
      isLoading: true,
      isInitialized: isInitialized,
    );
  }

  AuthState copyWithError(String error) {
    return AuthState(
      user: user,
      isAuthenticated: isAuthenticated,
      error: error,
      isInitialized: isInitialized,
    );
  }

  AuthState copyWith({
    User? user,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    bool? isInitialized,
    String? deviceManagementToken,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      deviceManagementToken: deviceManagementToken ?? this.deviceManagementToken,
    );
  }

  @override
  List<Object?> get props => [
        user, isAuthenticated, isLoading, error, isInitialized, deviceManagementToken,
      ];
}