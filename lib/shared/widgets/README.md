# Shared Widgets

This directory contains reusable UI components for loading states, error handling, empty states, and skeleton loaders.

## Loading Indicators

### LoadingIndicator
A centered loading indicator with optional message.

```dart
LoadingIndicator(
  message: 'Loading content...',
  size: 40.0,
)
```

### InlineLoadingIndicator
A small inline loading indicator for use within other widgets.

```dart
InlineLoadingIndicator(size: 20.0)
```

### OverlayLoadingIndicator
A full-screen overlay loading indicator for blocking operations.

```dart
OverlayLoadingIndicator(
  message: 'Processing...',
)
```

## Error Views

### ErrorView
A comprehensive error view with retry functionality.

```dart
ErrorView(
  title: 'Something went wrong',
  message: 'Unable to load data',
  icon: Icons.error_outline,
  onRetry: () {
    // Retry logic
  },
)
```

### InlineErrorView
A compact error view for inline display.

```dart
InlineErrorView(
  message: 'Failed to load',
  onRetry: () {
    // Retry logic
  },
)
```

### NetworkErrorView
Pre-configured error view for network errors.

```dart
NetworkErrorView(
  onRetry: () {
    // Retry logic
  },
)
```

### ServerErrorView
Pre-configured error view for server errors.

```dart
ServerErrorView(
  onRetry: () {
    // Retry logic
  },
)
```

## Empty States

### EmptyState
A generic empty state widget.

```dart
EmptyState(
  icon: Icons.inbox_outlined,
  title: 'No items',
  message: 'Add items to get started',
  action: () {
    // Action logic
  },
  actionLabel: 'Add Item',
)
```

### Pre-configured Empty States

- `EmptyLibraryState` - For empty library
- `EmptySearchState` - For no search results
- `EmptyCartState` - For empty cart
- `EmptyBookmarksState` - For no bookmarks
- `EmptyHighlightsState` - For no highlights
- `EmptyCollectionsState` - For no collections
- `EmptyDownloadsState` - For no downloads

Example:
```dart
EmptyLibraryState(
  onExplore: () {
    context.push('/discover');
  },
)
```

## Skeleton Loaders

### SkeletonLoader
A wrapper that adds shimmer effect to any widget.

```dart
SkeletonLoader(
  enabled: isLoading,
  child: YourWidget(),
)
```

### SkeletonBox
A basic skeleton placeholder box.

```dart
SkeletonBox(
  width: 100,
  height: 20,
  borderRadius: 8.0,
)
```

### Pre-built Skeleton Components

- `SkeletonContentCard` - For content cards in grid view
- `SkeletonListItem` - For list items
- `SkeletonCarousel` - For content carousels
- `SkeletonGrid` - For grid layouts
- `SkeletonList` - For list layouts

Example:
```dart
// Show skeleton while loading
if (isLoading) {
  return const SkeletonGrid(itemCount: 6);
}
```

## AsyncValue Widgets

### AsyncValueWidget
Automatically handles AsyncValue states from Riverpod.

```dart
AsyncValueWidget<ContentDetail>(
  value: contentDetailAsync,
  data: (contentDetail) => ContentView(contentDetail),
  loading: () => LoadingIndicator(message: 'Loading...'),
  error: (error, stack) => ErrorView(message: error.toString()),
)
```

### AsyncListWidget
Handles AsyncValue for lists with empty state support.

```dart
AsyncListWidget<Content>(
  value: contentListAsync,
  data: (items) => ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => ContentCard(items[index]),
  ),
  emptyState: EmptySearchState(),
  loading: () => SkeletonList(),
)
```

### AsyncNullableWidget
Handles AsyncValue for nullable data with empty state support.

```dart
AsyncNullableWidget<User>(
  value: userAsync,
  data: (user) => UserProfile(user),
  emptyState: EmptyState(
    icon: Icons.person_outline,
    title: 'No user found',
    message: 'Please sign in',
  ),
)
```

## Usage Examples

### Basic Loading State
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dataProvider);
    
    return Scaffold(
      body: dataAsync.when(
        data: (data) => DataView(data),
        loading: () => const LoadingIndicator(
          message: 'Loading data...',
        ),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(dataProvider);
          },
        ),
      ),
    );
  }
}
```

### Skeleton Loading
```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    
    if (state.isLoading && state.items.isEmpty) {
      return const SkeletonGrid(itemCount: 6);
    }
    
    if (state.items.isEmpty) {
      return const EmptyLibraryState();
    }
    
    return GridView.builder(
      itemCount: state.items.length,
      itemBuilder: (context, index) => ItemCard(state.items[index]),
    );
  }
}
```

### Inline Error
```dart
Column(
  children: [
    if (hasError)
      InlineErrorView(
        message: errorMessage,
        onRetry: () => retry(),
      ),
    // Rest of content
  ],
)
```

## Best Practices

1. **Use skeleton loaders for initial loads** - They provide better UX than spinners
2. **Show inline errors for non-critical failures** - Don't block the entire screen
3. **Always provide retry functionality** - Let users recover from errors
4. **Use appropriate empty states** - Help users understand what to do next
5. **Keep loading messages concise** - "Loading..." is often enough
6. **Use AsyncValueWidget for simple cases** - It reduces boilerplate
7. **Customize error messages** - Make them user-friendly and actionable

## Accessibility

All widgets include:
- Semantic labels for screen readers
- Sufficient color contrast
- Appropriate touch target sizes
- Keyboard navigation support (where applicable)

## Theming

All widgets respect the app's theme:
- Colors from `Theme.of(context).colorScheme`
- Text styles from `Theme.of(context).textTheme`
- Consistent spacing and sizing

## Testing

When testing screens that use these widgets:

```dart
testWidgets('shows loading indicator', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataProvider.overrideWith((ref) => AsyncValue.loading()),
      ],
      child: MyApp(),
    ),
  );
  
  expect(find.byType(LoadingIndicator), findsOneWidget);
});

testWidgets('shows error view with retry', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dataProvider.overrideWith(
          (ref) => AsyncValue.error('Error', StackTrace.empty),
        ),
      ],
      child: MyApp(),
    ),
  );
  
  expect(find.byType(ErrorView), findsOneWidget);
  expect(find.text('Retry'), findsOneWidget);
});
```
