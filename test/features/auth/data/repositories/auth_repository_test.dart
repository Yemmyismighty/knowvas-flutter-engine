import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/constants/api_constants.dart';
import 'package:knowvas/core/constants/storage_keys.dart';
import 'package:knowvas/core/errors/exceptions.dart';
import 'package:knowvas/core/errors/failures.dart';
import 'package:knowvas/core/network/api_client.dart';
import 'package:knowvas/core/security/secure_storage.dart';
import 'package:knowvas/features/auth/data/repositories/auth_repository.dart';
import 'package:knowvas/shared/models/auth_response.dart';
import 'package:knowvas/shared/models/user.dart';
import 'package:knowvas/shared/models/user_preferences.dart';
import 'package:knowvas/shared/models/reading_stats.dart';

// Fake implementations for testing
class FakeApiClient implements ApiClient {
  Response<Map<String, dynamic>>? nextResponse;
  Exception? nextException;
  String? lastPath;
  dynamic lastData;
  Options? lastOptions;

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    lastPath = path;
    lastData = data;
    lastOptions = options;

    if (nextException != null) {
      throw nextException!;
    }
    return nextResponse as Response<T>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSecureStorage implements SecureStorage {
  final Map<String, String> _storage = {};
  Exception? nextException;

  @override
  Future<void> write({required String key, required String value}) async {
    if (nextException != null) {
      throw nextException!;
    }
    _storage[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    if (nextException != null) {
      throw nextException!;
    }
    return _storage[key];
  }

  @override
  Future<void> delete({required String key}) async {
    if (nextException != null) {
      throw nextException!;
    }
    _storage.remove(key);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AuthRepository authRepository;
  late FakeApiClient fakeApiClient;
  late FakeSecureStorage fakeSecureStorage;

  setUp(() {
    fakeApiClient = FakeApiClient();
    fakeSecureStorage = FakeSecureStorage();
    authRepository = AuthRepository(
      apiClient: fakeApiClient,
      secureStorage: fakeSecureStorage,
    );
  });

  group('signIn', () {
    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testAccessToken = 'test_access_token';
    const testRefreshToken = 'test_refresh_token';
    const testUserId = 'user_123';

    final testUser = User(
      id: testUserId,
      email: testEmail,
      username: 'testuser',
      firstName: 'Test',
      lastName: 'User',
      preferences: const UserPreferences(),
      stats: const ReadingStats(),
    );

    final testAuthResponse = AuthResponse(
      accessToken: testAccessToken,
      refreshToken: testRefreshToken,
      user: testUser,
      expiresIn: 3600,
    );

    test('should return AuthResponse when sign in is successful', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testAuthResponse.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.login),
      );

      // Act
      final result = await authRepository.signIn(
        email: testEmail,
        password: testPassword,
      );

      // Assert
      expect(result, equals(testAuthResponse));
      expect(fakeApiClient.lastPath, equals(ApiConstants.login));
      expect(fakeApiClient.lastData, equals({
        'email': testEmail,
        'password': testPassword,
      }));
      expect(await fakeSecureStorage.read(key: StorageKeys.accessToken), equals(testAccessToken));
      expect(await fakeSecureStorage.read(key: StorageKeys.refreshToken), equals(testRefreshToken));
      expect(await fakeSecureStorage.read(key: StorageKeys.userId), equals(testUserId));
    });

    test('should throw AuthFailure when credentials are invalid', () async {
      // Arrange
      fakeApiClient.nextException = const AuthException(
        'Invalid credentials',
        code: 'INVALID_CREDENTIALS',
      );

      // Act & Assert
      expect(
        () => authRepository.signIn(
          email: testEmail,
          password: testPassword,
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.code,
          'code',
          'INVALID_CREDENTIALS',
        )),
      );
    });

    test('should throw NetworkFailure when network error occurs', () async {
      // Arrange
      fakeApiClient.nextException = const NetworkException(
        'No internet connection',
        code: 'NO_CONNECTION',
      );

      // Act & Assert
      expect(
        () => authRepository.signIn(
          email: testEmail,
          password: testPassword,
        ),
        throwsA(isA<NetworkFailure>().having(
          (e) => e.code,
          'code',
          'NO_CONNECTION',
        )),
      );
    });

    test('should throw ServerFailure when server error occurs', () async {
      // Arrange
      fakeApiClient.nextException = const ServerException(
        'Internal server error',
        statusCode: 500,
        code: 'SERVER_ERROR',
      );

      // Act & Assert
      expect(
        () => authRepository.signIn(
          email: testEmail,
          password: testPassword,
        ),
        throwsA(isA<ServerFailure>().having(
          (e) => e.statusCode,
          'statusCode',
          500,
        )),
      );
    });

    test('should throw AuthFailure when response status is not 200', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 400,
        requestOptions: RequestOptions(path: ApiConstants.login),
      );

      // Act & Assert
      expect(
        () => authRepository.signIn(
          email: testEmail,
          password: testPassword,
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.code,
          'code',
          'SIGN_IN_FAILED',
        )),
      );
    });
  });

  group('signUp', () {
    const testSignUpData = SignUpData(
      email: 'newuser@example.com',
      password: 'password123',
      firstName: 'New',
      lastName: 'User',
      username: 'newuser',
    );

    const testAccessToken = 'new_access_token';
    const testRefreshToken = 'new_refresh_token';
    const testUserId = 'user_456';

    final testUser = User(
      id: testUserId,
      email: testSignUpData.email,
      username: testSignUpData.username,
      firstName: testSignUpData.firstName,
      lastName: testSignUpData.lastName,
      preferences: const UserPreferences(),
      stats: const ReadingStats(),
    );

    final testAuthResponse = AuthResponse(
      accessToken: testAccessToken,
      refreshToken: testRefreshToken,
      user: testUser,
      expiresIn: 3600,
    );

    test('should return AuthResponse when sign up is successful with status 200', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testAuthResponse.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.signup),
      );

      // Act
      final result = await authRepository.signUp(signUpData: testSignUpData);

      // Assert
      expect(result, equals(testAuthResponse));
      expect(fakeApiClient.lastPath, equals(ApiConstants.signup));
      expect(fakeApiClient.lastData, equals(testSignUpData.toJson()));
      expect(await fakeSecureStorage.read(key: StorageKeys.accessToken), equals(testAccessToken));
      expect(await fakeSecureStorage.read(key: StorageKeys.refreshToken), equals(testRefreshToken));
      expect(await fakeSecureStorage.read(key: StorageKeys.userId), equals(testUserId));
    });

    test('should return AuthResponse when sign up is successful with status 201', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testAuthResponse.toJson(),
        statusCode: 201,
        requestOptions: RequestOptions(path: ApiConstants.signup),
      );

      // Act
      final result = await authRepository.signUp(signUpData: testSignUpData);

      // Assert
      expect(result, equals(testAuthResponse));
    });

    test('should throw AuthFailure when email already exists', () async {
      // Arrange
      fakeApiClient.nextException = const AuthException(
        'Email already exists',
        code: 'EMAIL_EXISTS',
      );

      // Act & Assert
      expect(
        () => authRepository.signUp(signUpData: testSignUpData),
        throwsA(isA<AuthFailure>().having(
          (e) => e.code,
          'code',
          'EMAIL_EXISTS',
        )),
      );
    });

    test('should throw ServerFailure when validation fails', () async {
      // Arrange
      fakeApiClient.nextException = const ServerException(
        'Validation failed',
        statusCode: 400,
        code: 'VALIDATION_ERROR',
      );

      // Act & Assert
      expect(
        () => authRepository.signUp(signUpData: testSignUpData),
        throwsA(isA<ServerFailure>()),
      );
    });

    test('should throw AuthFailure when response data is null', () async {
      // Arrange
      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.signup),
      );

      // Act & Assert
      expect(
        () => authRepository.signUp(signUpData: testSignUpData),
        throwsA(isA<AuthFailure>().having(
          (e) => e.code,
          'code',
          'SIGN_UP_FAILED',
        )),
      );
    });
  });

  group('refreshToken', () {
    const testRefreshToken = 'stored_refresh_token';
    const testNewAccessToken = 'new_access_token';
    const testNewRefreshToken = 'new_refresh_token';

    final testTokenResponse = TokenResponse(
      accessToken: testNewAccessToken,
      refreshToken: testNewRefreshToken,
      expiresIn: 3600,
    );

    test('should return TokenResponse when token refresh is successful', () async {
      // Arrange
      await fakeSecureStorage.write(
        key: StorageKeys.refreshToken,
        value: testRefreshToken,
      );

      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: testTokenResponse.toJson(),
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.refresh),
      );

      // Act
      final result = await authRepository.refreshToken();

      // Assert
      expect(result, equals(testTokenResponse));
      expect(fakeApiClient.lastPath, equals(ApiConstants.refresh));
      expect(fakeApiClient.lastData, equals({'refresh_token': testRefreshToken}));
      expect(await fakeSecureStorage.read(key: StorageKeys.accessToken), equals(testNewAccessToken));
      expect(await fakeSecureStorage.read(key: StorageKeys.refreshToken), equals(testNewRefreshToken));
    });

    test('should throw AuthFailure when no refresh token is stored', () async {
      // Act & Assert
      expect(
        () => authRepository.refreshToken(),
        throwsA(isA<AuthFailure>().having(
          (e) => e.code,
          'code',
          'NO_REFRESH_TOKEN',
        )),
      );
    });

    test('should throw AuthFailure when refresh token is invalid', () async {
      // Arrange
      await fakeSecureStorage.write(
        key: StorageKeys.refreshToken,
        value: testRefreshToken,
      );

      fakeApiClient.nextException = const AuthException(
        'Invalid refresh token',
        code: 'INVALID_TOKEN',
      );

      // Act & Assert
      expect(
        () => authRepository.refreshToken(),
        throwsA(isA<AuthFailure>().having(
          (e) => e.code,
          'code',
          'INVALID_TOKEN',
        )),
      );
    });

    test('should throw AuthFailure when storage read fails', () async {
      // Arrange
      fakeSecureStorage.nextException = const CacheException(
        'Failed to read from storage',
        code: 'STORAGE_ERROR',
      );

      // Act & Assert
      expect(
        () => authRepository.refreshToken(),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('should throw AuthFailure when response status is not 200', () async {
      // Arrange
      await fakeSecureStorage.write(
        key: StorageKeys.refreshToken,
        value: testRefreshToken,
      );

      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: null,
        statusCode: 401,
        requestOptions: RequestOptions(path: ApiConstants.refresh),
      );

      // Act & Assert
      expect(
        () => authRepository.refreshToken(),
        throwsA(isA<AuthFailure>().having(
          (e) => e.code,
          'code',
          'REFRESH_FAILED',
        )),
      );
    });
  });

  group('signOut', () {
    const testAccessToken = 'test_access_token';

    test('should clear all tokens when sign out is successful', () async {
      // Arrange
      await fakeSecureStorage.write(key: StorageKeys.accessToken, value: testAccessToken);
      await fakeSecureStorage.write(key: StorageKeys.refreshToken, value: 'refresh');
      await fakeSecureStorage.write(key: StorageKeys.userId, value: 'user_id');

      fakeApiClient.nextResponse = Response<Map<String, dynamic>>(
        data: {},
        statusCode: 200,
        requestOptions: RequestOptions(path: ApiConstants.logout),
      );

      // Act
      await authRepository.signOut();

      // Assert
      expect(await fakeSecureStorage.read(key: StorageKeys.accessToken), isNull);
      expect(await fakeSecureStorage.read(key: StorageKeys.refreshToken), isNull);
      expect(await fakeSecureStorage.read(key: StorageKeys.userId), isNull);
    });

    test('should clear tokens even when backend logout fails', () async {
      // Arrange
      await fakeSecureStorage.write(key: StorageKeys.accessToken, value: testAccessToken);
      await fakeSecureStorage.write(key: StorageKeys.refreshToken, value: 'refresh');
      await fakeSecureStorage.write(key: StorageKeys.userId, value: 'user_id');

      fakeApiClient.nextException = const NetworkException(
        'Network error',
        code: 'NO_CONNECTION',
      );

      // Act
      await authRepository.signOut();

      // Assert
      expect(await fakeSecureStorage.read(key: StorageKeys.accessToken), isNull);
      expect(await fakeSecureStorage.read(key: StorageKeys.refreshToken), isNull);
      expect(await fakeSecureStorage.read(key: StorageKeys.userId), isNull);
    });

    test('should clear tokens when no access token is stored', () async {
      // Arrange
      await fakeSecureStorage.write(key: StorageKeys.refreshToken, value: 'refresh');
      await fakeSecureStorage.write(key: StorageKeys.userId, value: 'user_id');

      // Act
      await authRepository.signOut();

      // Assert
      expect(await fakeSecureStorage.read(key: StorageKeys.accessToken), isNull);
      expect(await fakeSecureStorage.read(key: StorageKeys.refreshToken), isNull);
      expect(await fakeSecureStorage.read(key: StorageKeys.userId), isNull);
    });

    test('should throw AuthFailure when token deletion fails', () async {
      // Arrange
      fakeSecureStorage.nextException = const CacheException(
        'Failed to delete from storage',
        code: 'STORAGE_ERROR',
      );

      // Act & Assert
      expect(
        () => authRepository.signOut(),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('getAccessToken', () {
    test('should return access token when it exists', () async {
      // Arrange
      const testToken = 'test_access_token';
      await fakeSecureStorage.write(key: StorageKeys.accessToken, value: testToken);

      // Act
      final result = await authRepository.getAccessToken();

      // Assert
      expect(result, equals(testToken));
    });

    test('should return null when no access token exists', () async {
      // Act
      final result = await authRepository.getAccessToken();

      // Assert
      expect(result, isNull);
    });

    test('should return null when storage read fails', () async {
      // Arrange
      fakeSecureStorage.nextException = const CacheException(
        'Storage error',
        code: 'STORAGE_ERROR',
      );

      // Act
      final result = await authRepository.getAccessToken();

      // Assert
      expect(result, isNull);
    });
  });

  group('isAuthenticated', () {
    test('should return true when both tokens exist', () async {
      // Arrange
      await fakeSecureStorage.write(key: StorageKeys.accessToken, value: 'access_token');
      await fakeSecureStorage.write(key: StorageKeys.refreshToken, value: 'refresh_token');

      // Act
      final result = await authRepository.isAuthenticated();

      // Assert
      expect(result, isTrue);
    });

    test('should return false when access token is missing', () async {
      // Arrange
      await fakeSecureStorage.write(key: StorageKeys.refreshToken, value: 'refresh_token');

      // Act
      final result = await authRepository.isAuthenticated();

      // Assert
      expect(result, isFalse);
    });

    test('should return false when refresh token is missing', () async {
      // Arrange
      await fakeSecureStorage.write(key: StorageKeys.accessToken, value: 'access_token');

      // Act
      final result = await authRepository.isAuthenticated();

      // Assert
      expect(result, isFalse);
    });

    test('should return false when both tokens are missing', () async {
      // Act
      final result = await authRepository.isAuthenticated();

      // Assert
      expect(result, isFalse);
    });
  });
}
