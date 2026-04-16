import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/achievement.dart';

/// Repository for achievement operations
/// Handles fetching and unlocking achievements
class AchievementRepository {
  AchievementRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Get all achievements for the current user
  /// Returns list of Achievement objects (both locked and unlocked)
  /// Throws ServerFailure on server errors
  /// Throws NetworkFailure on network errors
  Future<List<Achievement>> getAchievements() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/achievements',
      );

      if (response.statusCode == 200 && response.data != null) {
        final achievements = response.data!['achievements'] as List<dynamic>?;
        if (achievements != null) {
          return achievements
              .map((json) => Achievement.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        throw const ServerFailure(
          'Failed to fetch achievements',
          code: 'FETCH_ACHIEVEMENTS_FAILED',
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
        'An unexpected error occurred while fetching achievements: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Unlock an achievement
  /// Returns updated Achievement object
  /// Throws ServerFailure on server errors
  /// Throws NetworkFailure on network errors
  Future<Achievement> unlockAchievement(int achievementId) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/achievements/$achievementId/unlock',
      );

      if (response.statusCode == 200 && response.data != null) {
        return Achievement.fromJson(response.data!);
      } else {
        throw const ServerFailure(
          'Failed to unlock achievement',
          code: 'UNLOCK_ACHIEVEMENT_FAILED',
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
        'An unexpected error occurred while unlocking achievement: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get unlocked achievements only
  /// Returns list of unlocked Achievement objects
  /// Throws ServerFailure on server errors
  /// Throws NetworkFailure on network errors
  Future<List<Achievement>> getUnlockedAchievements() async {
    try {
      final achievements = await getAchievements();
      return achievements.where((achievement) => achievement.isUnlocked).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get locked achievements only
  /// Returns list of locked Achievement objects
  /// Throws ServerFailure on server errors
  /// Throws NetworkFailure on network errors
  Future<List<Achievement>> getLockedAchievements() async {
    try {
      final achievements = await getAchievements();
      return achievements.where((achievement) => !achievement.isUnlocked).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get achievements by category
  /// Returns list of Achievement objects filtered by category
  /// Throws ServerFailure on server errors
  /// Throws NetworkFailure on network errors
  Future<List<Achievement>> getAchievementsByCategory(String category) async {
    try {
      final achievements = await getAchievements();
      return achievements.where((achievement) => achievement.category == category).toList();
    } catch (e) {
      rethrow;
    }
  }
}
