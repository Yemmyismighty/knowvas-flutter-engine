import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/reading_goal.dart';

/// Repository for reading goal operations
/// Handles creating, updating, and fetching reading goals
class ReadingGoalRepository {
  ReadingGoalRepository({
    required ApiClient apiClient,
  }) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Create a new reading goal
  /// Returns created ReadingGoal object
  /// Throws ServerFailure on server errors
  /// Throws NetworkFailure on network errors
  Future<ReadingGoal> createGoal({
    required int year,
    int? targetBooks,
    int? targetPages,
    int? targetReadingTimeMinutes,
  }) async {
    try {
      final data = <String, dynamic>{
        'year': year,
      };

      if (targetBooks != null) data['target_books'] = targetBooks;
      if (targetPages != null) data['target_pages'] = targetPages;
      if (targetReadingTimeMinutes != null) {
        data['target_reading_time_minutes'] = targetReadingTimeMinutes;
      }

      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/reading-goals',
        data: data,
      );

      if (response.statusCode == 201 && response.data != null) {
        return ReadingGoal.fromJson(response.data!);
      } else {
        throw const ServerFailure(
          'Failed to create reading goal',
          code: 'CREATE_GOAL_FAILED',
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
        'An unexpected error occurred while creating reading goal: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Update reading goal progress
  /// Returns updated ReadingGoal object
  /// Throws ServerFailure on server errors
  /// Throws NetworkFailure on network errors
  Future<ReadingGoal> updateGoalProgress({
    required int goalId,
    int? currentBooks,
    int? currentPages,
    int? currentReadingTimeMinutes,
  }) async {
    try {
      final data = <String, dynamic>{};

      if (currentBooks != null) data['current_books'] = currentBooks;
      if (currentPages != null) data['current_pages'] = currentPages;
      if (currentReadingTimeMinutes != null) {
        data['current_reading_time_minutes'] = currentReadingTimeMinutes;
      }

      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/reading-goals/$goalId/progress',
        data: data,
      );

      if (response.statusCode == 200 && response.data != null) {
        return ReadingGoal.fromJson(response.data!);
      } else {
        throw const ServerFailure(
          'Failed to update goal progress',
          code: 'UPDATE_PROGRESS_FAILED',
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
        'An unexpected error occurred while updating goal progress: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get all reading goals for the current user
  /// Returns list of ReadingGoal objects
  /// Throws ServerFailure on server errors
  /// Throws NetworkFailure on network errors
  Future<List<ReadingGoal>> getGoals() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/reading-goals',
      );

      if (response.statusCode == 200 && response.data != null) {
        final goals = response.data!['goals'] as List<dynamic>?;
        if (goals != null) {
          return goals
              .map((json) => ReadingGoal.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return [];
      } else {
        throw const ServerFailure(
          'Failed to fetch reading goals',
          code: 'FETCH_GOALS_FAILED',
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
        'An unexpected error occurred while fetching reading goals: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get reading goal for a specific year
  /// Returns ReadingGoal object or null if not found
  /// Throws ServerFailure on server errors
  /// Throws NetworkFailure on network errors
  Future<ReadingGoal?> getGoalByYear(int year) async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/reading-goals/$year',
      );

      if (response.statusCode == 200 && response.data != null) {
        return ReadingGoal.fromJson(response.data!);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw const ServerFailure(
          'Failed to fetch reading goal',
          code: 'FETCH_GOAL_FAILED',
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
        'An unexpected error occurred while fetching reading goal: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Delete a reading goal
  /// Throws ServerFailure on server errors
  /// Throws NetworkFailure on network errors
  Future<void> deleteGoal(int goalId) async {
    try {
      final response = await _apiClient.delete<void>(
        '/api/reading-goals/$goalId',
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw const ServerFailure(
          'Failed to delete reading goal',
          code: 'DELETE_GOAL_FAILED',
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
        'An unexpected error occurred while deleting reading goal: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }
}
