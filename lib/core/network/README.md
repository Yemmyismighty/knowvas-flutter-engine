# Network Layer

This directory contains the network layer implementation for the Knowvas Flutter client, including API client configuration, authentication, retry logic, and error handling.

## Components

### ApiClient (`api_client.dart`)

The main HTTP client for making requests to the backend API. Built on top of Dio with the following features:

- **Automatic token injection** via AuthInterceptor
- **Retry logic with exponential backoff** via RetryInterceptor
- **Comprehensive error handling** with app-specific exceptions
- **Request/response logging** for debugging
- **Timeout configuration** for all request types

#### Usage

```dart
// Get the API client from Riverpod
final apiClient = ref.read(apiClientProvider);

// Make a GET request
final response = await apiClient.get('/api/content/123');

// Make a POST request
final response = await apiClient.post(
  '/api/auth/login',
  data: {
    'email': 'user@example.com',
    'password': 'password123',
  },
);

// Download a file
await apiClient.download(
  '/api/download/file',
  '/path/to/save/file.pdf',
  onReceiveProgress: (received, total) {
    print('Progress: ${(received / total * 100).toStringAsFixed(0)}%');
  },
);
```

### AuthInterceptor (`auth_interceptor.dart`)

Automatically injects JWT access tokens into request headers and handles token refresh on 401 responses.

**Features:**
- Adds `Authorization: Bearer <token>` header to all non-auth requests
- Automatically refreshes expired tokens on 401 errors
- Retries failed requests with new token after refresh
- Skips token injection for auth endpoints (login, signup, etc.)

**Token Refresh Flow:**
1. Request fails with 401 Unauthorized
2. Interceptor calls `onTokenRefresh` callback
3. New access token is obtained and stored
4. Original request is retried with new token
5. If refresh fails, error is propagated

### RetryInterceptor (`retry_interceptor.dart`)

Automatically retries failed requests with exponential backoff strategy.

**Features:**
- Retries up to 3 times by default (configurable)
- Exponential backoff: delay = initialDelay * 2^retryCount
- Random jitter to prevent thundering herd problem
- Smart retry logic based on error type and status code

**Retry Conditions:**
- ✅ Server errors (5xx)
- ✅ Timeout errors (connection, send, receive)
- ✅ Connection errors
- ✅ Rate limiting (429)
- ✅ Request timeout (408)
- ❌ Client errors (4xx except 408, 429)
- ❌ Cancelled requests
- ❌ Certificate errors

**Backoff Example:**
- Attempt 1: Wait ~1s (1000ms + jitter)
- Attempt 2: Wait ~2s (2000ms + jitter)
- Attempt 3: Wait ~4s (4000ms + jitter)
- Max delay capped at 10s

### NetworkInfo (`network_info.dart`)

Service for checking network connectivity status.

**Features:**
- Check if device is connected to internet
- Stream of connectivity changes
- Check connection type (WiFi, mobile, ethernet)

#### Usage

```dart
final networkInfo = ref.read(networkInfoProvider);

// Check if connected
final isConnected = await networkInfo.isConnected;

// Check if connected via WiFi
final isWifi = await networkInfo.isConnectedViaWifi;

// Listen to connectivity changes
networkInfo.onConnectivityChanged.listen((isConnected) {
  if (isConnected) {
    print('Connected to internet');
  } else {
    print('No internet connection');
  }
});
```

### Providers (`api_client_provider.dart`)

Riverpod providers for dependency injection of network components.

**Available Providers:**
- `secureStorageProvider` - Secure storage for tokens
- `loggerProvider` - Logger instance
- `networkInfoProvider` - Network connectivity service
- `authInterceptorProvider` - Authentication interceptor
- `retryInterceptorProvider` - Retry interceptor
- `apiClientProvider` - Configured API client

## Error Handling

The API client converts Dio exceptions into app-specific exceptions:

| Dio Error | App Exception | Description |
|-----------|---------------|-------------|
| Connection timeout | `NetworkException` | Connection took too long |
| Send/Receive timeout | `NetworkException` | Request/response timeout |
| Connection error | `NetworkException` | No internet connection |
| Bad certificate | `NetworkException` | Invalid SSL certificate |
| 401 Unauthorized | `AuthException` | Authentication failed |
| 403 Forbidden | `AuthException` | Access forbidden |
| 404 Not Found | `ServerException` | Resource not found |
| 4xx Client errors | `ServerException` | Client-side error |
| 5xx Server errors | `ServerException` | Server-side error |
| Request cancelled | `NetworkException` | Request was cancelled |

## Configuration

### Base URL

The base URL is configured via environment variable or defaults to production:

```dart
// In api_constants.dart
static const String baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://api.knowvas.com',
);
```

To use a different base URL:

```bash
flutter run --dart-define=API_BASE_URL=https://staging.api.knowvas.com
```

### Timeouts

Default timeouts are configured in `ApiConstants`:

```dart
static const Duration connectTimeout = Duration(seconds: 30);
static const Duration receiveTimeout = Duration(seconds: 30);
static const Duration sendTimeout = Duration(seconds: 30);
```

### Retry Configuration

Customize retry behavior when creating the interceptor:

```dart
RetryInterceptor(
  maxRetries: 3,           // Maximum retry attempts
  initialDelayMs: 1000,    // Initial delay before first retry
  maxDelayMs: 10000,       // Maximum delay between retries
)
```

## Security

### HTTPS

All requests use HTTPS by default. The client validates SSL certificates and rejects invalid or self-signed certificates (unless configured otherwise).

### Token Storage

JWT tokens are stored securely using platform-specific secure storage:
- **Android**: Android Keystore with encrypted shared preferences
- **iOS**: iOS Keychain with first_unlock accessibility

### Certificate Pinning

Certificate pinning can be added for additional security:

```dart
// In ApiClient constructor
_dio.httpClientAdapter = IOHttpClientAdapter(
  createHttpClient: () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) {
      // Implement certificate pinning logic
      return false;
    };
    return client;
  },
);
```

## Testing

### Mocking the API Client

```dart
class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;

  setUp(() {
    mockApiClient = MockApiClient();
  });

  test('should return data on successful request', () async {
    // Arrange
    when(mockApiClient.get('/api/content/123'))
        .thenAnswer((_) async => Response(
              data: {'id': 123, 'title': 'Test'},
              statusCode: 200,
              requestOptions: RequestOptions(path: '/api/content/123'),
            ));

    // Act
    final response = await mockApiClient.get('/api/content/123');

    // Assert
    expect(response.statusCode, 200);
    expect(response.data['title'], 'Test');
  });
}
```

## Requirements Satisfied

This implementation satisfies the following requirements:

- **1.2**: JWT token authentication with automatic injection
- **1.4**: Automatic token refresh on expiration
- **15.1**: HTTPS for all network requests
- **15.2**: SSL certificate validation

## Future Enhancements

- [ ] Certificate pinning for enhanced security
- [ ] Request caching for offline support
- [ ] Request deduplication
- [ ] GraphQL support
- [ ] WebSocket support for real-time features
