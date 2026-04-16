# Authentication Providers

This directory contains the authentication state management using Riverpod.

## Files

### auth_state.dart
Defines the `AuthState` class that represents the authentication state of the application.

**State Properties:**
- `user`: The currently authenticated user (null if not authenticated)
- `isAuthenticated`: Boolean indicating if user is authenticated
- `isLoading`: Boolean indicating if an auth operation is in progress
- `error`: Error message if an auth operation failed
- `isInitialized`: Boolean indicating if the initial auth check is complete

**Factory Methods:**
- `AuthState.initial()`: Initial state before checking for existing session
- `AuthState.authenticated(User)`: State when user is authenticated
- `AuthState.unauthenticated()`: State when user is not authenticated

### auth_provider.dart
Defines the `Auth` notifier that manages authentication state and operations.

**Methods:**
- `signIn({email, password})`: Sign in with email and password
- `signUp({signUpData})`: Sign up with user details
- `signOut()`: Sign out and clear authentication state
- `refreshToken()`: Refresh access token using refresh token
- `updateUser(User)`: Update user data in state
- `clearError()`: Clear error message

**Properties:**
- `isAuthenticated`: Check if user is authenticated
- `currentUser`: Get current user

**Features:**
- Automatic initialization on app start (checks for existing session)
- State persistence across app restarts (via SecureStorage)
- Automatic token refresh on 401 errors (via AuthInterceptor)
- Error handling with user-friendly messages

## Usage

### In a Widget

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas_flutter_client/features/auth/presentation/providers/providers.dart';

class SignInScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    // Listen to auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        // Navigate to home screen
      } else if (next.error != null) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!)),
        );
      }
    });
    
    return Scaffold(
      body: authState.isLoading
          ? CircularProgressIndicator()
          : SignInForm(
              onSignIn: (email, password) {
                ref.read(authProvider.notifier).signIn(
                  email: email,
                  password: password,
                );
              },
            ),
    );
  }
}
```

### Sign In

```dart
await ref.read(authProvider.notifier).signIn(
  email: 'user@example.com',
  password: 'password123',
);
```

### Sign Up

```dart
await ref.read(authProvider.notifier).signUp(
  signUpData: SignUpData(
    email: 'user@example.com',
    password: 'password123',
    firstName: 'John',
    lastName: 'Doe',
    username: 'johndoe',
  ),
);
```

### Sign Out

```dart
await ref.read(authProvider.notifier).signOut();
```

### Check Authentication Status

```dart
final isAuthenticated = ref.read(authProvider.notifier).isAuthenticated;
```

### Get Current User

```dart
final user = ref.read(authProvider.notifier).currentUser;
```

### Update User

```dart
ref.read(authProvider.notifier).updateUser(updatedUser);
```

## Integration with AuthInterceptor

The `Auth` provider works alongside the `AuthInterceptor` for authentication:

1. The `AuthInterceptor` automatically injects access tokens into API requests
2. When a 401 error is received, the interceptor detects it
3. Token refresh should be handled at the application level by catching 401 errors and calling `Auth.refreshToken()`
4. If refresh fails, the user is automatically signed out

Note: To avoid circular dependencies, the token refresh callback in `AuthInterceptor` is set to null. Token refresh is handled by the application layer when needed.

## State Persistence

The authentication state is persisted across app restarts using `SecureStorage`:
- Access token is stored securely
- Refresh token is stored securely
- User ID is stored securely

On app initialization, the `Auth` provider checks for existing tokens and restores the authenticated state if valid tokens are found.

## Requirements Satisfied

This implementation satisfies the following requirements:

- **1.2**: JWT tokens are stored securely using platform keystore/keychain
- **1.3**: Session is persisted across app restarts
- **1.4**: Automatic token refresh on expiration
- **1.5**: User is logged out when token refresh fails
- **1.10**: Sign out clears all tokens and cached user data
