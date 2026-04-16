import 'package:knowvas/shared/models/user.dart';
import 'package:knowvas/shared/models/user_preferences.dart';
import 'package:knowvas/shared/models/reading_stats.dart';
import 'package:knowvas/shared/models/auth_response.dart';

/// Test data helpers for creating mock objects
class TestData {
  /// Creates a test user with default values
  static User createTestUser({
    String id = '1',
    String email = 'test@example.com',
    String username = 'testuser',
    String firstName = 'Test',
    String lastName = 'User',
    String? profilePicture,
    String? bio,
    String? preferredCurrency,
    UserPreferences? preferences,
    ReadingStats? stats,
    int followerCount = 0,
    int followingCount = 0,
  }) {
    return User(
      id: id,
      email: email,
      username: username,
      firstName: firstName,
      lastName: lastName,
      profilePicture: profilePicture,
      bio: bio,
      preferredCurrency: preferredCurrency,
      preferences: preferences ?? const UserPreferences(),
      stats: stats ?? const ReadingStats(),
      followerCount: followerCount,
      followingCount: followingCount,
    );
  }

  /// Creates a test auth response
  static AuthResponse createTestAuthResponse({
    String accessToken = 'test_access_token',
    String refreshToken = 'test_refresh_token',
    User? user,
    int expiresIn = 3600,
  }) {
    return AuthResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user ?? createTestUser(),
      expiresIn: expiresIn,
    );
  }

  /// Creates a test token response
  static TokenResponse createTestTokenResponse({
    String accessToken = 'test_access_token',
    String refreshToken = 'test_refresh_token',
    int expiresIn = 3600,
  }) {
    return TokenResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresIn: expiresIn,
    );
  }
}
