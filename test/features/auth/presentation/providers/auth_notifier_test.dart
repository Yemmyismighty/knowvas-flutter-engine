import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/features/auth/data/repositories/auth_repository.dart';
import 'package:knowvas/features/auth/data/repositories/auth_repository_provider.dart';
import 'package:knowvas/features/auth/presentation/providers/auth_provider.dart';
import 'package:knowvas/shared/models/auth_response.dart';
import 'package:riverpod/riverpod.dart';

import '../../../helpers/test_data.dart';

// Manual mock for AuthRepository
class MockAuthRepository implements AuthRepository {
  bool _isAuthenticated = false;
  String? _userId;
  String? _accessToken;
  String? _refreshToken;
  AuthResponse? _authResponse;
  TokenResponse? _tokenResponse;
  Exception? _signInException;
  Exception? _signUpException;
  Exception? _refreshException;
  bool _signOutCalled = false;
  bool _requestPasswordResetCalled = false;
  
  void setAuthenticated(bool value) => _isAuthenticated = value;
  void setUserId(String? value) => _userId = value;
  void setAccessToken(String? value) => _accessToken = value;
  void setRefreshToken(String? value) => _refreshToken = value;
  void setAuthResponse(AuthResponse? value) => _authResponse = value;
  void setTokenResponse(TokenResponse? value) => _tokenResponse = value;
  void setSignInException(Exception? value) => _signInException = value;
  void setSignUpException(Exception? value) => _signUpException = value;
  void setRefreshException(Exception? value) => _refreshException = value;
  
  bool get signOutCalled => _signOutCalled;
  bool get requestPasswordResetCalled => _requestPasswordResetCalled;
  
  @override
  Future<bool> isAuthenticated() async => _isAuthenticated;
  
  @override
  Future<String?> getUserId() async => _userId;
  
  @override
  Future<String?> getAccessToken() async => _accessToken;
  
  @override
  Future<String?> getRefreshToken() async => _refreshToken;
  
  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    if (_signInException != null) throw _signInException!;
    return _authResponse ?? TestData.createTestAuthResponse();
  }
  
  @override
  Future<AuthResponse> signUp({required SignUpData signUpData}) async {
    if (_signUpException != null) throw _signUpException!;
    return _authResponse ?? TestData.createTestAuthResponse();
  }
  
  @override
  Future<void> signOut() async {
    _signOutCalled = true;
  }
  
  @override
  Future<TokenResponse> refreshToken() async {
    if (_refreshException != null) throw _refreshException!;
    return _tokenResponse ?? TestData.createTestTokenResponse();
  }
  
  @override
  Future<void> requestPasswordReset({required String email}) async {
    _requestPasswordResetCalled = true;
  }
}

void main() {
  late MockAuthRepository mockAuthRepository;
  late ProviderContainer container;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    
    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AuthNotifier', () {
    group('initialization', () {
      test('should start with initial state', () {
        // Arrange
        mockAuthRepository.setAuthenticated(false);

        // Act
        final state = container.read(authProvider);

        // Assert
        expect(state.isLoading, true);
        expect(state.isAuthenticated, false);
        expect(state.isInitialized, false);
      });

      test('should initialize as unauthenticated when no stored session', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(false);

        // Act
        container.read(authProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final state = container.read(authProvider);
        expect(state.isAuthenticated, false);
        expect(state.isInitialized, true);
        expect(state.user, null);
      });

      test('should initialize as authenticated when valid session exists', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(true);
        mockAuthRepository.setUserId('user123');

        // Act
        container.read(authProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        final state = container.read(authProvider);
        expect(state.isAuthenticated, true);
        expect(state.isInitialized, true);
      });
    });

    group('signIn', () {
      test('should update state to authenticated on successful sign in', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(false);
        
        final testUser = User(
          id: 'user123',
          email: 'test@example.com',
          username: 'testuser',
          firstName: 'Test',
          lastName: 'User',
        );
        
        final authResponse = AuthResponse(
          user: testUser,
          accessToken: 'access_token',
          refreshToken: 'refresh_token',
        );

        mockAuthRepository.setAuthResponse(authResponse);

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signIn(email: 'test@example.com', password: 'password123');

        // Assert
        final state = container.read(authProvider);
        expect(state.isAuthenticated, true);
        expect(state.isLoading, false);
        expect(state.user, testUser);
        expect(state.error, null);
      });

      test('should set error state on AuthFailure', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(false);
        mockAuthRepository.setSignInException(const AuthFailure('Invalid credentials'));

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signIn(email: 'test@example.com', password: 'wrong');

        // Assert
        final state = container.read(authProvider);
        expect(state.isAuthenticated, false);
        expect(state.isLoading, false);
        expect(state.error, 'Invalid credentials');
      });

      test('should set error state on NetworkFailure', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(false);
        mockAuthRepository.setSignInException(const NetworkFailure('No internet connection'));

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signIn(email: 'test@example.com', password: 'password');

        // Assert
        final state = container.read(authProvider);
        expect(state.error, 'No internet connection');
      });

      test('should set error state on ServerFailure', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(false);
        mockAuthRepository.setSignInException(const ServerFailure('Server error', statusCode: 500));

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signIn(email: 'test@example.com', password: 'password');

        // Assert
        final state = container.read(authProvider);
        expect(state.error, 'Server error');
      });
    });

    group('signUp', () {
      test('should update state to authenticated on successful sign up', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(false);
        
        final testUser = User(
          id: 'user123',
          email: 'newuser@example.com',
          username: 'newuser',
          firstName: 'New',
          lastName: 'User',
        );
        
        final authResponse = AuthResponse(
          user: testUser,
          accessToken: 'access_token',
          refreshToken: 'refresh_token',
        );

        mockAuthRepository.setAuthResponse(authResponse);

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signUp(
          signUpData: SignUpData(
            email: 'newuser@example.com',
            password: 'password123',
            firstName: 'New',
            lastName: 'User',
            username: 'newuser',
          ),
        );

        // Assert
        final state = container.read(authProvider);
        expect(state.isAuthenticated, true);
        expect(state.user, testUser);
        expect(state.error, null);
      });

      test('should set error state on sign up failure', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(false);
        mockAuthRepository.setSignUpException(const AuthFailure('Email already exists'));

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signUp(
          signUpData: SignUpData(
            email: 'existing@example.com',
            password: 'password123',
            firstName: 'Test',
            lastName: 'User',
            username: 'testuser',
          ),
        );

        // Assert
        final state = container.read(authProvider);
        expect(state.isAuthenticated, false);
        expect(state.error, 'Email already exists');
      });
    });

    group('signOut', () {
      test('should clear authentication state on sign out', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(true);
        mockAuthRepository.setUserId('user123');

        // Initialize as authenticated
        container.read(authProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signOut();

        // Assert
        final state = container.read(authProvider);
        expect(state.isAuthenticated, false);
        expect(state.user, null);
        expect(state.error, null);
        expect(mockAuthRepository.signOutCalled, true);
      });
    });

    group('refreshToken', () {
      test('should return true on successful token refresh', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(true);
        mockAuthRepository.setUserId('user123');

        // Act
        final notifier = container.read(authProvider.notifier);
        final result = await notifier.refreshToken();

        // Assert
        expect(result, true);
      });

      test('should sign out and return false on AuthFailure', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(true);
        mockAuthRepository.setUserId('user123');
        mockAuthRepository.setRefreshException(const AuthFailure('Invalid refresh token'));

        // Initialize as authenticated
        container.read(authProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        // Act
        final notifier = container.read(authProvider.notifier);
        final result = await notifier.refreshToken();

        // Assert
        expect(result, false);
        final state = container.read(authProvider);
        expect(state.isAuthenticated, false);
      });

      test('should return false on other errors without signing out', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(true);
        mockAuthRepository.setUserId('user123');
        mockAuthRepository.setRefreshException(const NetworkFailure('Network error'));

        // Initialize as authenticated
        container.read(authProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        // Act
        final notifier = container.read(authProvider.notifier);
        final result = await notifier.refreshToken();

        // Assert
        expect(result, false);
        final state = container.read(authProvider);
        expect(state.isAuthenticated, true); // Should still be authenticated
      });
    });

    group('updateUser', () {
      test('should update user in state when authenticated', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(true);
        mockAuthRepository.setUserId('user123');

        // Initialize as authenticated
        container.read(authProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        final updatedUser = User(
          id: 'user123',
          email: 'updated@example.com',
          username: 'updateduser',
          firstName: 'Updated',
          lastName: 'User',
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        notifier.updateUser(updatedUser);

        // Assert
        final state = container.read(authProvider);
        expect(state.user, updatedUser);
        expect(state.isAuthenticated, true);
      });

      test('should not update user when not authenticated', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(false);

        // Initialize as unauthenticated
        container.read(authProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        final updatedUser = User(
          id: 'user123',
          email: 'updated@example.com',
          username: 'updateduser',
          firstName: 'Updated',
          lastName: 'User',
        );

        // Act
        final notifier = container.read(authProvider.notifier);
        notifier.updateUser(updatedUser);

        // Assert
        final state = container.read(authProvider);
        expect(state.user, null);
        expect(state.isAuthenticated, false);
      });
    });

    group('clearError', () {
      test('should clear error message', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(false);
        mockAuthRepository.setSignInException(const AuthFailure('Invalid credentials'));

        // Set error state
        final notifier = container.read(authProvider.notifier);
        await notifier.signIn(email: 'test@example.com', password: 'wrong');
        
        var state = container.read(authProvider);
        expect(state.error, 'Invalid credentials');

        // Act
        notifier.clearError();

        // Assert
        state = container.read(authProvider);
        expect(state.error, null);
      });
    });

    group('getters', () {
      test('isAuthenticated should return correct value', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(true);
        mockAuthRepository.setUserId('user123');

        // Act
        final notifier = container.read(authProvider.notifier);
        container.read(authProvider);
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(notifier.isAuthenticated, true);
      });

      test('currentUser should return user when authenticated', () async {
        // Arrange
        mockAuthRepository.setAuthenticated(false);
        
        final testUser = User(
          id: 'user123',
          email: 'test@example.com',
          username: 'testuser',
          firstName: 'Test',
          lastName: 'User',
        );
        
        final authResponse = AuthResponse(
          user: testUser,
          accessToken: 'access_token',
          refreshToken: 'refresh_token',
        );

        mockAuthRepository.setAuthResponse(authResponse);

        // Act
        final notifier = container.read(authProvider.notifier);
        await notifier.signIn(email: 'test@example.com', password: 'password123');

        // Assert
        expect(notifier.currentUser, testUser);
      });
    });
  });
}
