# Cart State Management

This directory contains the cart state management implementation using Riverpod.

## Files

### cart_state.dart
Defines the `CartState` class that holds:
- List of cart items
- Total price per currency
- Loading and error states
- Helper methods for cart operations

### cart_provider.dart
Implements the `Cart` notifier that manages cart state with:
- **State Management**: Uses Riverpod's `AutoDisposeNotifier` pattern
- **Persistence**: Saves cart to local storage using `SharedPreferences`
- **Sync**: Fetches cart from backend and syncs with local storage
- **Methods**:
  - `addToCart(contentId)` - Add content to cart
  - `removeFromCart(contentId)` - Remove content from cart
  - `updateQuantity(contentId, quantity)` - Update item quantity
  - `clearCart()` - Clear all items
  - `refresh()` - Sync with backend
  - `badgeCount` - Get number of items for badge display

### cart_provider.g.dart
Generated Riverpod provider code (do not modify manually)

## Usage

```dart
// In a widget
final cartState = ref.watch(cartProvider);

// Add to cart
await ref.read(cartProvider.notifier).addToCart(contentId);

// Get badge count
final count = ref.read(cartProvider.notifier).badgeCount;

// Check if item is in cart
final isInCart = ref.read(cartProvider.notifier).containsContent(contentId);

// Remove from cart
await ref.read(cartProvider.notifier).removeFromCart(contentId);
```

## Features

1. **Offline Support**: Cart is persisted locally and loaded on app start
2. **Auto-sync**: Automatically syncs with backend when operations are performed
3. **Error Handling**: Gracefully handles network and server errors
4. **Badge Count**: Provides easy access to cart item count for UI badges
5. **Currency Support**: Handles multiple currencies for pricing

## Requirements Satisfied

- Requirement 3.2: Add to cart functionality
- Requirement 3.3: View and manage cart items
