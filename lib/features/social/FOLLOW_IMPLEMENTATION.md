# Follow Functionality Implementation

## Overview
This document describes the implementation of the follow functionality for the Knowvas Flutter client, allowing users to follow/unfollow authors and view their followers/following lists.

## Implementation Details

### Files Created
1. `lib/features/social/data/repositories/follow_repository.dart` - Main repository implementation
2. `lib/features/social/data/repositories/follow_repository_provider.dart` - Riverpod provider

### Files Modified
1. `lib/core/constants/api_constants.dart` - Added follow-related API endpoints

## Features Implemented

### 1. Follow Author (`followAuthor`)
- **Endpoint**: `POST /api/follow/author/{authorId}`
- **Functionality**: Allows users to follow an author
- **Error Handling**: Throws `FollowFailure` on errors, `NetworkFailure` when offline
- **Cache Management**: Invalidates following cache after successful follow

### 2. Unfollow Author (`unfollowAuthor`)
- **Endpoint**: `DELETE /api/follow/author/{authorId}`
- **Functionality**: Allows users to unfollow an author
- **Error Handling**: Throws `FollowFailure` on errors, `NetworkFailure` when offline
- **Cache Management**: Invalidates following cache after successful unfollow

### 3. Get Following List (`getFollowing`)
- **Endpoint**: `GET /api/follow/following`
- **Functionality**: Fetches list of authors and users that the current user follows
- **Parameters**: 
  - `page` (default: 1)
  - `limit` (default: 20)
  - `forceRefresh` (default: false)
- **Caching**: 5-minute cache duration
- **Offline Support**: Returns cached data when offline
- **Response Model**: `FollowingList` containing authors, users, and pagination info

### 4. Get Followers List (`getFollowers`)
- **Endpoint**: `GET /api/follow/followers`
- **Functionality**: Fetches list of users who follow the current user
- **Parameters**: 
  - `page` (default: 1)
  - `limit` (default: 20)
  - `forceRefresh` (default: false)
- **Caching**: 5-minute cache duration
- **Offline Support**: Returns cached data when offline
- **Response Model**: `FollowersList` containing followers and pagination info

## Data Models

### FollowingList
```dart
class FollowingList {
  final List<Author> authors;
  final List<User> users;
  final int totalCount;
  final int currentPage;
  final int totalPages;
}
```

### FollowersList
```dart
class FollowersList {
  final List<User> followers;
  final int totalCount;
  final int currentPage;
  final int totalPages;
}
```

### FollowFailure
```dart
class FollowFailure extends Failure {
  final int? targetId;
  const FollowFailure(String message, {String? code, this.targetId});
}
```

## API Endpoints Added

```dart
// Follow endpoints
static const String follow = '/api/follow';
static const String following = '/api/follow/following';
static const String followers = '/api/follow/followers';
```

## Error Handling

The repository handles the following error scenarios:
1. **Network Errors**: Throws `NetworkFailure` when no internet connection
2. **Server Errors**: Throws `ServerFailure` with status code
3. **Follow-Specific Errors**: Throws `FollowFailure` with error code and optional target ID
4. **Offline Mode**: Returns cached data when available, otherwise throws `NetworkFailure`

## Caching Strategy

- **Cache Duration**: 5 minutes
- **Cache Keys**: Based on page and limit parameters
- **Cache Invalidation**: 
  - Following cache cleared after follow/unfollow operations
  - Manual cache clearing available via `clearCache()`, `clearFollowingCache()`, `clearFollowersCache()`

## Usage Example

```dart
// Get the repository
final followRepository = ref.read(followRepositoryProvider);

// Follow an author
try {
  await followRepository.followAuthor(authorId);
  // Update UI to reflect follow status
} on FollowFailure catch (e) {
  // Handle follow error
} on NetworkFailure catch (e) {
  // Handle network error
}

// Get following list
try {
  final followingList = await followRepository.getFollowing(page: 1, limit: 20);
  // Display authors and users
} on FollowFailure catch (e) {
  // Handle error
}

// Get followers list
try {
  final followersList = await followRepository.getFollowers(page: 1, limit: 20);
  // Display followers
} on FollowFailure catch (e) {
  // Handle error
}
```

## Requirements Satisfied

- ✅ **Requirement 11.2**: Follow author functionality with backend API integration
- ✅ **Requirement 11.3**: Unfollow author functionality with backend API integration
- ✅ **Requirement 11.4**: Get following list displaying all followed authors and users
- ✅ **Additional**: Get followers list for viewing who follows the current user

## Testing Recommendations

1. **Unit Tests**:
   - Test follow/unfollow operations with mocked API client
   - Test caching behavior
   - Test error handling scenarios
   - Test offline mode with cached data

2. **Integration Tests**:
   - Test full follow/unfollow flow
   - Test pagination for following/followers lists
   - Test cache invalidation after follow/unfollow

3. **Widget Tests**:
   - Test UI updates after follow/unfollow
   - Test loading states
   - Test error message display

## Next Steps

To complete the social features implementation:
1. Create state management providers (FollowNotifier) for UI integration
2. Implement UI screens for following/followers lists
3. Add follow/unfollow buttons to author profile screens
4. Implement ratings and reviews functionality (Task 69)
5. Add unit tests for the repository
