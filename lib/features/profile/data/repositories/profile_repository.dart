import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/models/profile_models.dart';
import '../../../../shared/models/user.dart';

/// Repository for profile operations
class ProfileRepository {
  ProfileRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Get profile header data
  Future<ProfileHeader> getProfileHeader() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/reading-progress/profile-header',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ProfileHeader.fromJson(data);
        }
        throw const ServerFailure(
          'Invalid response format',
          code: 'INVALID_RESPONSE',
        );
      } else {
        throw const ServerFailure(
          'Failed to fetch profile header',
          code: 'PROFILE_HEADER_FETCH_FAILED',
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

  /// Get reading goal
  Future<ReadingGoal?> getReadingGoal() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/reading-progress/reading-goal',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>?;
        if (data != null) {
          return ReadingGoal.fromJson(data);
        }
        return null;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Create reading goal
  Future<ReadingGoal> createReadingGoal(int targetBooks) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/reading-progress/reading-goal',
        data: {'targetBooks': targetBooks},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return ReadingGoal.fromJson(data);
      } else {
        throw const ServerFailure(
          'Failed to create reading goal',
          code: 'READING_GOAL_CREATE_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure(
        'Failed to create reading goal: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get quick stats
  Future<QuickStats> getQuickStats() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/reading-progress/quick-stats',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as Map<String, dynamic>;
        return QuickStats.fromJson(data);
      } else {
        throw const ServerFailure(
          'Failed to fetch quick stats',
          code: 'QUICK_STATS_FETCH_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure(
        'Failed to fetch quick stats: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get achievements
  Future<List<Achievement>> getAchievements() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/reading-progress/achievements',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as List<dynamic>?;
        return data
                ?.map((e) => Achievement.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      } else {
        throw const ServerFailure(
          'Failed to fetch achievements',
          code: 'ACHIEVEMENTS_FETCH_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure(
        'Failed to fetch achievements: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Get activity
  Future<List<Activity>> getActivity() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/reading-progress/activity',
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['data'] as List<dynamic>?;
        return data
                ?.map((e) => Activity.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
      } else {
        throw const ServerFailure(
          'Failed to fetch activity',
          code: 'ACTIVITY_FETCH_FAILED',
        );
      }
    } catch (e) {
      throw ServerFailure(
        'Failed to fetch activity: $e',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Upload avatar image
  Future<String?> uploadAvatar({required String filePath}) async {
    try {
      final formData = FormData.fromMap({
        'avatar': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/user/avatar',
        data: formData,
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data!['avatar_url'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update user profile
  Future<User> updateProfile({
    required String firstName,
    required String lastName,
    required String username,
    String? bio,
    String? profilePicture,
  }) async {
    try {
      final response = await _apiClient.put<Map<String, dynamic>>(
        '/api/user/profile',
        data: {
          'firstname': firstName,
          'lastname': lastName,
          'username': username,
          if (bio != null) 'bio': bio,
          if (profilePicture != null) 'profile_picture': profilePicture,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data!['user'] as Map<String, dynamic>? ?? response.data!;
        return User.fromJson(data);
      }
      throw const ServerFailure('Failed to update profile', code: 'UPDATE_FAILED');
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, code: e.code);
    } catch (e) {
      if (e is ServerFailure || e is NetworkFailure) rethrow;
      throw ServerFailure('Failed to update profile: $e', code: 'UNKNOWN_ERROR');
    }
  }
}
