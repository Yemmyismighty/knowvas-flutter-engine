# Router Configuration

This document describes the navigation setup for the Knowvas Flutter client using `go_router`.

## Overview

The router is configured with authentication-based route guards and supports deep linking for content and reader screens. It uses Riverpod for state management and watches the authentication state to control access to protected routes.

## Architecture

### Route Structure

```
/auth
  ├── /sign-in
  ├── /sign-up
  └── /forgot-password

/discover (with bottom nav shell)
  ├── /content/:id
  ├── /search
  └── /author/:id

/library (with bottom nav shell)
  ├── /collections
  └── /collection/:id

/profile (with bottom nav shell)
  ├── /edit
  ├── /reading-stats
  ├── /reading-goals
  ├── /achievements
  ├── /following
  └── /followers

/settings (with bottom nav shell)
  ├── /notifications
  └── /privacy

/reader/:contentId (full screen, outside shell)
  └── ?type=epub|pdf|comic

/cart
/downloads
/subscription
/content/:contentId/reviews
```

## Authentication Guards

The router implements automatic route guards based on authentication state:

1. **Unauthenticated users**: Redirected to `/auth/sign-in` when trying to access protected routes
2. **Authenticated users**: Redirected to `/discover` when trying to access auth routes
3. **Initialization**: Routes are blocked until auth state is initialized

## Deep Linking

The router supports deep linking for:

- **Content detail**: `/discover/content/:id`
- **Reader**: `/reader/:contentId?type=epub|pdf|comic`
- **Author profile**: `/discover/author/:id`
- **Collections**: `/library/collection/:id`
- **Reviews**: `/content/:contentId/reviews`

### Example Deep Links

```dart
// Open content detail
context.go('/discover/content/123');

// Open reader with content type
context.go('/reader/456?type=epub');

// Open author profile
context.go('/discover/author/789');
```

## Navigation Methods

### Declarative Navigation

```dart
// Navigate to a route
context.go('/discover');

// Navigate with parameters
context.go('/discover/content/$contentId');

// Navigate with query parameters
context.go('/reader/$contentId?type=epub');
```

### Named Routes

```dart
// Navigate using route name
context.goNamed('content-detail', pathParameters: {'id': '123'});

// Navigate to reader with query params
context.goNamed(
  'reader',
  pathParameters: {'contentId': '456'},
  queryParameters: {'type': 'epub'},
);
```

### Push Navigation (for stacking)

```dart
// Push a new route on the stack
context.push('/discover/content/123');

// Push with named route
context.pushNamed('content-detail', pathParameters: {'id': '123'});
```

## Bottom Navigation

The main app sections (Discover, Library, Profile, Settings) are wrapped in a `ShellRoute` that provides a persistent bottom navigation bar. The navigation bar automatically highlights the current section based on the route.

## Error Handling

The router includes a custom error screen that displays when:
- A route is not found
- Navigation fails
- Invalid parameters are provided

The error screen provides a "Go to Home" button to return to the discover screen.

## Usage Examples

### Navigate from Sign In to Discover

```dart
// After successful authentication
context.go('/discover');
```

### Open Content Detail

```dart
// From discover screen
onTap: () => context.push('/discover/content/$contentId');
```

### Open Reader

```dart
// From library or content detail
onTap: () => context.go('/reader/$contentId?type=$contentType');
```

### Navigate to Settings

```dart
// From profile or anywhere
context.go('/settings');
```

### Navigate Back

```dart
// Pop current route
context.pop();

// Pop with result
context.pop(result);
```

## Implementation Details

### Router Provider

The router is provided via Riverpod and watches the auth state:

```dart
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/discover',
    redirect: (context, state) {
      // Authentication guard logic
    },
    routes: [
      // Route definitions
    ],
  );
});
```

### Using the Router in App

```dart
class KnowvasApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      // ...
    );
  }
}
```

## Testing

When testing navigation:

1. Mock the auth provider state
2. Use `GoRouter.of(context)` to access router in tests
3. Test route guards with different auth states
4. Verify deep linking works correctly

## Future Enhancements

- [ ] Add route transitions/animations
- [ ] Implement route analytics tracking
- [ ] Add route-level loading states
- [ ] Support for nested navigation in tabs
- [ ] Add route-based permission checks beyond authentication

## Related Files

- `lib/app/router.dart` - Main router configuration
- `lib/app/app.dart` - App widget using the router
- `lib/features/auth/presentation/providers/auth_provider.dart` - Authentication state
- `lib/features/*/presentation/screens/` - Screen implementations
