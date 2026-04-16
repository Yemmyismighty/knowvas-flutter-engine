# Knowvas Flutter Client - Domain Models and DTOs

This directory contains all domain models and Data Transfer Objects (DTOs) used throughout the Knowvas Flutter client application.

## Domain Models

### Core User Models
- **User** (`user.dart`) - User account information with preferences and stats
- **UserPreferences** (`user_preferences.dart`) - User settings and preferences
- **ReadingStats** (`reading_stats.dart`) - User reading statistics and achievements

### Content Models
- **Content** (`content.dart`) - Digital content (ebooks, PDFs, comics, magazines, audiobooks)
- **LibraryItem** (`library_item.dart`) - Content in user's library with reading progress
- **Author** (`author.dart`) - Author profile information
- **Review** (`review.dart`) - User reviews and ratings for content

### Reading Models
- **Bookmark** (`bookmark.dart`) - Saved reading positions
- **Highlight** (`highlight.dart`) - Highlighted text with color
- **Note** (`note.dart`) - User notes attached to content

### Engagement Models
- **EngagementEvent** (`engagement_event.dart`) - User interaction events for analytics

## API Response Models (DTOs)

### Authentication
- **AuthResponse** (`auth_response.dart`) - Login/signup response with tokens
- **TokenResponse** (`auth_response.dart`) - Token refresh response
- **SignUpData** (`auth_response.dart`) - Sign up request data

### Content Discovery
- **ContentDetail** (`content_detail.dart`) - Detailed content view with similar items
- **SearchFilters** (`search_filters.dart`) - Search and filter parameters
- **SearchResponse** (`search_filters.dart`) - Search results with pagination

### Library
- **LibraryResponse** (`library_response.dart`) - User library with pagination

### Downloads
- **DownloadRequest** (`download_request.dart`) - Download request with quality
- **DownloadResponse** (`download_request.dart`) - Signed URL for download

### Cart and Purchase
- **CartItem** (`cart_item.dart`) - Item in shopping cart
- **CartResponse** (`cart_item.dart`) - Cart contents with total price
- **PurchaseRequest** (`purchase_request.dart`) - Purchase request data
- **PurchaseResponse** (`purchase_request.dart`) - Purchase confirmation

### Subscription
- **SubscriptionPlan** (`subscription.dart`) - Available subscription plans
- **ActiveSubscription** (`subscription.dart`) - User's active subscription

## Features

### JSON Serialization
All models implement:
- `fromJson()` - Deserialize from JSON
- `toJson()` - Serialize to JSON

### Immutability
All models extend `Equatable` for:
- Value equality comparison
- Immutable data structures
- Easy testing

### Type Safety
- Null safety enabled
- Proper type conversions
- Default values for optional fields

### Validation
- Required field validation
- Type checking
- Safe null handling

## Usage

Import all models using the barrel file:

```dart
import 'package:knowvas_flutter_client/shared/models/models.dart';
```

Or import specific models:

```dart
import 'package:knowvas_flutter_client/shared/models/user.dart';
import 'package:knowvas_flutter_client/shared/models/content.dart';
```

## Example

```dart
// Create a user from JSON
final json = {
  'id': '123',
  'email': 'user@example.com',
  'username': 'johndoe',
  'first_name': 'John',
  'last_name': 'Doe',
  'preferences': {},
  'stats': {},
};

final user = User.fromJson(json);

// Serialize to JSON
final userJson = user.toJson();

// Create modified copy
final updatedUser = user.copyWith(
  firstName: 'Jane',
);
```

## Testing

All models have comprehensive unit tests in `test/shared/models/models_test.dart` covering:
- JSON serialization/deserialization
- Null value handling
- Type safety
- Default values
- Model equality

Run tests with:
```bash
flutter test test/shared/models/models_test.dart
```
