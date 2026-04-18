import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import 'auth_interceptor.dart';
import 'retry_interceptor.dart';

/// API client for making HTTP requests to the backend
/// Configured with authentication, retry logic, and error handling
class ApiClient {
  ApiClient({
    required String baseUrl,
    Dio? dio,
    AuthInterceptor? authInterceptor,
    RetryInterceptor? retryInterceptor,
    Logger? logger,
  })  : _dio = dio ?? Dio(),
        _logger = logger ?? Logger() {
    _dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) {
        // Accept all status codes to handle them in interceptors
        return status != null && status < 500;
      },
    );

    // Add interceptors in order
    if (authInterceptor != null) {
      _dio.interceptors.add(authInterceptor);
    }
    if (retryInterceptor != null) {
      _dio.interceptors.add(retryInterceptor);
    }

    // Interceptors added above handle auth and retry.
  }

  final Dio _dio;
  final Logger _logger;

  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Download file
  Future<Response<dynamic>> download(
    String urlPath,
    dynamic savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    dynamic data,
    Options? options,
  }) async {
    try {
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        data: data,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Handle DioException and convert to app-specific exceptions
  AppException _handleDioException(DioException error) {
    _logger.e('DioException: ${error.type} - ${error.message}');

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(
          'Connection timeout. Please check your internet connection.',
          code: 'TIMEOUT',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;

        if (statusCode == 401) {
          return AuthException(
            _extractErrorMessage(data) ?? 'Authentication failed',
            code: 'UNAUTHORIZED',
          );
        } else if (statusCode == 403) {
          return AuthException(
            _extractErrorMessage(data) ?? 'Access forbidden',
            code: 'FORBIDDEN',
          );
        } else if (statusCode == 404) {
          return ServerException(
            _extractErrorMessage(data) ?? 'Resource not found',
            statusCode: statusCode,
            code: 'NOT_FOUND',
          );
        } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
          return ServerException(
            _extractErrorMessage(data) ?? 'Client error occurred',
            statusCode: statusCode,
            code: 'CLIENT_ERROR',
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            _extractErrorMessage(data) ?? 'Server error occurred',
            statusCode: statusCode,
            code: 'SERVER_ERROR',
          );
        }

        return ServerException(
          _extractErrorMessage(data) ?? 'An error occurred',
          statusCode: statusCode,
        );

      case DioExceptionType.cancel:
        return const NetworkException(
          'Request was cancelled',
          code: 'CANCELLED',
        );

      case DioExceptionType.connectionError:
        return const NetworkException(
          'No internet connection. Please check your network.',
          code: 'NO_CONNECTION',
        );

      case DioExceptionType.badCertificate:
        return const NetworkException(
          'Invalid SSL certificate',
          code: 'BAD_CERTIFICATE',
        );

      case DioExceptionType.unknown:
        return NetworkException(
          error.message ?? 'An unexpected error occurred',
          code: 'UNKNOWN',
        );
    }
  }

  /// Extract error message from response data
  String? _extractErrorMessage(dynamic data) {
    if (data == null) return null;

    if (data is Map<String, dynamic>) {
      // Try common error message keys
      return data['message'] as String? ?? data['error'] as String? ?? data['detail'] as String? ?? data['msg'] as String?;
    }

    if (data is String) {
      return data;
    }

    return null;
  }

  /// Close the client and clean up resources
  void close({bool force = false}) {
    _dio.close(force: force);
  }
}
