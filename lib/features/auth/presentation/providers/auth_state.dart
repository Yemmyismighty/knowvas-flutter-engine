import 'package:equatable/equatable.dart';

import '../../../../shared/models/user.dart';

enum SessionTerminationReason { deviceRemoved, sessionExpired }

/// Authentication state
class AuthState extends Equatable {
  const AuthState({
    this.user,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
    this.deviceManagementToken,
    this.sessionTerminated = false,
    this.sessionTerminationReason,
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

  factory AuthState.deviceLimitReached(String token) {
    return AuthState(isInitialized: true, deviceManagementToken: token);
  }

  factory AuthState.sessionExpired() {
    return const AuthState(
      isInitialized: true,
      sessionTerminated: true,
      sessionTerminationReason: SessionTerminationReason.sessionExpired,
    );
  }

  factory AuthState.deviceRemoved() {
    return const AuthState(
      isInitialized: true,
      sessionTerminated: true,
      sessionTerminationReason: SessionTerminationReason.deviceRemoved,
    );
  }

  final User? user;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final bool isInitialized;
  final String? deviceManagementToken;

  /// True when the session was terminated externally (expired or device removed)
  final bool sessionTerminated;
  final SessionTerminationReason? sessionTerminationReason;

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
    bool? sessionTerminated,
    SessionTerminationReason? sessionTerminationReason,
  }) {
    return AuthState(
      user: user ?? this.user,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
      deviceManagementToken: deviceManagementToken ?? this.deviceManagementToken,
      sessionTerminated: sessionTerminated ?? this.sessionTerminated,
      sessionTerminationReason: sessionTerminationReason ?? this.sessionTerminationReason,
    );
  }

  @override
  List<Object?> get props => [
        user, isAuthenticated, isLoading, error, isInitialized,
        deviceManagementToken, sessionTerminated, sessionTerminationReason,
      ];
}