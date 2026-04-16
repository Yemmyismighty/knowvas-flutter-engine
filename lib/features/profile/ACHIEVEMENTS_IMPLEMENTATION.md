# Achievements System Implementation

## Overview
This document describes the implementation of the achievements system for the Knowvas Flutter client (Task 72).

## Components Implemented

### 1. Data Model
**File**: `lib/shared/models/achievement.dart`

The `Achievement` model represents user achievements with the following properties:
- `id`: Unique identifier
- `name`: Achievement name
- `description`: Achievement description
- `iconUrl`: URL to achievement icon
- `category`: Achievement category (reading, collection, social, streak, milestone, exploration)
- `targetValue`: Target value to unlock the achievement
- `currentValue`: Current progress value
- `isUnlocked`: Whether the achievement is unlocked
- `unlockedAt`: Timestamp when unlocked
- `createdAt`: Creation timestamp

The model includes helper methods:
- `progress`: Returns progress as a decimal (0.0 to 1.0)
- `progressPercentage`: Returns progress as a percentage (0 to 100)

### 2. Repository
**File**: `lib/features/profile/data/repositories/achievement_repository.dart`

The `AchievementRepository` handles all achievement-related API calls:

#### Methods:
- `getAchievements()`: Fetches all achievements (locked and unlocked)
- `unlockAchievement(int achievementId)`: Unlocks a specific achievement
- `getUnlockedAchievements()`: Fetches only unlocked achievements
- `getLockedAchievements()`: Fetches only locked achievements
- `getAchievementsByCategory(String category)`: Fetches achievements by category

#### API Endpoints:
- `GET /api/achievements` - Get all achievements
- `POST /api/achievements/{id}/unlock` - Unlock an achievement

### 3. State Management
**File**: `lib/features/profile/presentation/providers/achievements_provider.dart`

Riverpod providers for managing achievement state:

- `achievementsProvider`: Fetches all achievements
- `unlockedAchievementsProvider`: Fetches unlocked achievements
- `lockedAchievementsProvider`: Fetches locked achievements
- `achievementUnlockerProvider`: Handles unlocking achievements and refreshing state

### 4. UI Components

#### AchievementsScreen
**File**: `lib/features/profile/presentation/screens/achievements_screen.dart`

Main screen for displaying achievements with:
- Three tabs: All, Unlocked, Locked
- Grouped by category
- Pull-to-refresh functionality
- Error handling with retry
- Achievement detail dialog showing progress

#### AchievementCard
**File**: `lib/features/profile/presentation/widgets/achievement_card.dart`

Card widget displaying individual achievements with:
- Icon based on category
- Visual distinction between locked/unlocked
- Progress bar for locked achievements
- Unlock date for unlocked achievements
- Tap to view details

#### AchievementUnlockNotification
**File**: `lib/features/profile/presentation/widgets/achievement_unlock_notification.dart`

Animated notification overlay for achievement unlocks with:
- Slide-in animation from top
- Trophy icon with scale animation
- Auto-dismiss after 4 seconds
- Manual dismiss option
- Gradient background

## Usage

### Displaying Achievements Screen
```dart
// Navigate to achievements screen
context.push('/achievements');

// Or use Navigator
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const AchievementsScreen(),
  ),
);
```

### Unlocking an Achievement
```dart
// In a widget with WidgetRef
final unlocker = ref.read(achievementUnlockerProvider.notifier);

try {
  final achievement = await unlocker.unlockAchievement(achievementId);
  
  // Show notification
  if (context.mounted) {
    AchievementUnlockNotification.show(context, achievement);
  }
} catch (e) {
  // Handle error
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Failed to unlock achievement: $e')),
  );
}
```

### Watching Achievement State
```dart
// Watch all achievements
final achievementsAsync = ref.watch(achievementsProvider);

achievementsAsync.when(
  data: (achievements) {
    // Display achievements
  },
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('Error: $error'),
);

// Watch only unlocked achievements
final unlockedAsync = ref.watch(unlockedAchievementsProvider);
```

## Achievement Categories

The system supports the following categories with corresponding icons:
- **Reading**: Books read, pages read, reading time
- **Collection**: Library size, collections created
- **Social**: Followers, reviews written, authors followed
- **Streak**: Reading streaks, consecutive days
- **Milestone**: Special milestones reached
- **Exploration**: Genres explored, new authors discovered

## Backend Integration

### Expected API Response Format

#### GET /api/achievements
```json
{
  "achievements": [
    {
      "id": 1,
      "name": "First Book",
      "description": "Complete your first book",
      "icon_url": "https://example.com/icons/first-book.png",
      "category": "reading",
      "target_value": 1,
      "current_value": 0,
      "is_unlocked": false,
      "unlocked_at": null,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ]
}
```

#### POST /api/achievements/{id}/unlock
```json
{
  "id": 1,
  "name": "First Book",
  "description": "Complete your first book",
  "icon_url": "https://example.com/icons/first-book.png",
  "category": "reading",
  "target_value": 1,
  "current_value": 1,
  "is_unlocked": true,
  "unlocked_at": "2024-01-15T10:30:00Z",
  "created_at": "2024-01-01T00:00:00Z"
}
```

## Error Handling

The repository handles the following error scenarios:
- Network errors (no connection, timeout)
- Server errors (500, 503)
- Authentication errors (401, 403)
- Not found errors (404)
- Unexpected errors

All errors are converted to appropriate `Failure` objects:
- `NetworkFailure`: Network connectivity issues
- `ServerFailure`: Server-side errors
- `AuthFailure`: Authentication/authorization issues

## Testing Recommendations

### Unit Tests
- Test Achievement model serialization/deserialization
- Test progress calculation methods
- Test repository methods with mocked API client
- Test provider state management

### Widget Tests
- Test AchievementCard rendering for locked/unlocked states
- Test AchievementsScreen tab navigation
- Test error states and retry functionality
- Test achievement detail dialog

### Integration Tests
- Test full flow: fetch achievements → display → unlock → refresh
- Test notification display on unlock
- Test navigation to achievements screen

## Future Enhancements

1. **Local Caching**: Cache achievements in local database for offline access
2. **Push Notifications**: System notifications for achievement unlocks
3. **Sharing**: Share unlocked achievements on social media
4. **Leaderboards**: Compare achievements with friends
5. **Achievement Hints**: Show hints for locked achievements
6. **Rarity Indicators**: Show achievement rarity (common, rare, epic, legendary)
7. **Sound Effects**: Play sound when unlocking achievements
8. **Confetti Animation**: Add confetti effect for special achievements

## Requirements Satisfied

This implementation satisfies the following requirements from Requirement 10:

- **10.5**: Display unlocked and locked achievements with progress bars ✓
- **10.6**: Unlock achievements and update the achievements list ✓
- **10.7**: Display achievement unlock notifications ✓

## Files Created/Modified

### Created:
1. `lib/shared/models/achievement.dart`
2. `lib/features/profile/data/repositories/achievement_repository.dart`
3. `lib/features/profile/data/repositories/achievement_repository_provider.dart`
4. `lib/features/profile/data/repositories/achievement_repository_provider.g.dart`
5. `lib/features/profile/presentation/providers/achievements_provider.dart`
6. `lib/features/profile/presentation/providers/achievements_provider.g.dart`
7. `lib/features/profile/presentation/widgets/achievement_card.dart`
8. `lib/features/profile/presentation/widgets/achievement_unlock_notification.dart`

### Modified:
1. `lib/shared/models/models.dart` - Added achievement export
2. `lib/features/profile/presentation/screens/achievements_screen.dart` - Implemented full screen

## Dependencies

No new dependencies were added. The implementation uses existing packages:
- `flutter_riverpod` - State management
- `riverpod_annotation` - Code generation
- `equatable` - Value equality
- `dio` - HTTP client (via ApiClient)
