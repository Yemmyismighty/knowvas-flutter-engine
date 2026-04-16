import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';

/// Repository for follow operations
class FollowRepository {
  FollowRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Toggle follow status for an author or user
  Future<FollowToggleResult> toggleFollow({
    required String followableType, // "author" or "user"
    required int followableId,
    required bool isCurrentlyFollowing,
  }) async {
    try {
      final method = isCurrentlyFollowing ? 'DELETE' : 'POST';
      
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/user/follow',
        data: isCurrentlyFollowing ? null : {
          'followableType': followableType,
          'followableId': followableId,
        },
        queryParameters: isCurrentlyFollowing ? {
          'followableType': followableType,
          'followableId': followableId.toString(),
        } : null,
      );

      if (response.statusCode == 200 && response.data != null) {
        return FollowToggleResult(
          isFollowing: response.data!['isFollowing'] as bool,
          followersCount: response.data!['followersCount'] as int,
          message: response.data!['message'] as String,
        );
      } else {
        throw const ServerFailure(
          'Failed to toggle follow',
          code: 'FOLLOW_TOGGLE_FAILED',
        );
      }
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(
        e.message,
        statusCode: e.statusCode,
        code: e.code,
      );
    } on AppException catch (e) {
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(
        'An unexpected error occurred: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}

/// Result of follow toggle operation
class FollowToggleResult {
  final bool isFollowing;
  final int followersCount;
  final String message;

  FollowToggleResult({
    required this.isFollowing,
    required this.followersCount,
    required this.message,
  });
}
