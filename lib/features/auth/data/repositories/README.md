# Authentication Repository

## Overview

The `AuthRepository` handles all authentication-related operations for the Knowvas Flutter client. It provides methods for user sign-in, sign-up, token refresh, and sign-out, with secure token storage using platform-specific secure storage (Android Keystore, iOS Keychain).

## Features

- **Sign In**: Authenticate users with email and password
- **Sign Up**: Register new users with required profile information
- **Token Refresh**: Automatically refresh expired access tokens
- **Sign Out**: Clear all stored tokens and optionally notify backend
- **Secure Token Storage**: Store JWT tokens using platform secure storage
- **Error Handling**: Comprehensive error handling with specific failure types

## Usage

### Dependency Injection

The repository is provided via Riverpod:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_repository_provider.dart';

// In your widget or provider
final authRepo = ref.read(authRepositoryProvider);
```

### Sign In

```dart
try {
  final authResponse = await authRepo.signIn(
    email: 'user@example.com',
    password: 'securePassword123',
  );
  
  // Access user data
  print('Welcome ${authResponse.user.firstName}!');
  print('Access Token: ${authResponse.accessToken}');
} on AuthFailure catch (e) {
  print('Authentication failed: ${e.message}');
} on NetworkFailure catch (e) {
  print('Network error: ${e.message}');
}
```

### Sign Up

```dart
try {
  final signUpData = SignUpData(
    email: 'newuser@example.com',
    password: 'securePassword123',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
  );
  
  final authResponse = await authRepo.signUp(signUpData: signUpData);
  print('Account created successfully!');
} on AuthFailure catch (e) {
  print('Sign up failed: ${e.message}');
}
```

### Token Refresh

```dart
try {
  final tokenResponse = await authRepo.refreshToken();
  print('Token refreshed successfully');
} on AuthFailure catch (e) {
  if (e.code == 'NO_REFRESH_TOKEN' || e.code == 'REFRESH_FAILED') {
    // Redirect to login
    print('Please sign in again');
  }
}
```

### Sign Out

```dart
try {
  await authRepo.signOut();
  print('Signed out successfully');
} on AuthFailure catch (e) {
  print('Sign out error: ${e.message}');
  // Even if backend call fails, local tokens are cleared
}
```

### Check Authentication Status

```dart
final isAuthenticated = await authRepo.isAuthenticated();
if (isAuthenticated) {
  print('User is authenticated');
} else {
  print('User needs to sign in');
}
```

### Get Stored Tokens

```dart
final accessToken = await authRepo.getAccessToken();
final refreshToken = await authRepo.getRefreshToken();
final userId = await authRepo.getUserId();
```

## API Endpoints

The repository interacts with the following backend endpoints:

- **POST /api/auth/login**: Sign in with email and password
- **POST /api/auth/signup**: Register new user account
- **POST /api/auth/refresh**: Refresh access token
- **POST /api/auth/logout**: Logout (optional backend notification)

## Error Handling

The repository throws specific failure types for different error scenarios:

### AuthFailure
- Invalid credentials
- Sign up validation errors
- Token refresh failures
- Missing refresh token

### NetworkFailure
- Connection timeout
- No internet connection
- Network errors

### ServerFailure
- Server errors (5xx)
- Client errors (4xx)
- Invalid responses

## Token Storage

Tokens are stored securely using `SecureStorage`:

- **Access Token**: JWT token for API authentication
- **Refresh Token**: Long-lived token for refreshing access token
- **User ID**: Current user's unique identifier

Storage keys are defined in `StorageKeys`:
- `StorageKeys.accessToken`
- `StorageKeys.refreshToken`
- `StorageKeys.userId`

## Security Considerations

1. **Secure Storage**: All tokens are stored using platform-specific secure storage (Android Keystore, iOS Keychain)
2. **HTTPS Only**: All API calls use HTTPS for transport security
3. **Token Cleanup**: Sign out clears all stored tokens, even if backend call fails
4. **No Token Logging**: Tokens are never logged or exposed in error messages

## Requirements Satisfied

This implementation satisfies the following requirements from the spec:

- **Requirement 1.2**: Authentication via POST /api/auth/login with JWT token storage
- **Requirement 1.3**: Session persistence across app restarts
- **Requirement 1.4**: Automatic token refresh using POST /api/auth/refresh
- **Requirement 1.5**: Logout with token cleanup
- **Requirement 1.10**: Sign out clears all tokens and returns to sign-in screen

## Testing

Unit tests for this repository should mock:
- `ApiClient` for network calls
- `SecureStorage` for token storage

Example test structure:

```dart
void main() {
  late AuthRepository repository;
  late MockApiClient mockApiClient;
  late MockSecureStorage mockSecureStorage;
  
  setUp(() {
    mockApiClient = MockApiClient();
    mockSecureStorage = MockSecureStorage();
    repository = AuthRepository(
      apiClient: mockApiClient,
      secureStorage: mockSecureStorage,
    );
  });
  
  group('signIn', () {
    test('should return AuthResponse on successful sign in', () async {
      // Test implementation
    });
    
    test('should throw AuthFailure on invalid credentials', () async {
      // Test implementation
    });
  });
}
```

## Future Enhancements

- Biometric authentication support
- Multi-factor authentication (MFA)
- Social login (Google, Apple, Facebook)
- Remember me functionality
- Token expiration monitoring
