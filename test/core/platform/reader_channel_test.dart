import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knowvas/core/platform/platform.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderChannel', () {
    late ReaderChannel readerChannel;
    const methodChannel = MethodChannel('com.knowvas.reader/channel');
    const eventChannel = EventChannel('com.knowvas.reader/events');

    setUp(() {
      readerChannel = ReaderChannel();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(eventChannel, null);
    });

    group('openReader', () {
      test('should return success response when native call succeeds', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'openReader') {
            return {'status': 'ok'};
          }
          return null;
        });

        final request = OpenReaderRequest(
          contentId: 123,
          type: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test-token',
          sessionId: 'session-123',
        );

        // Act
        final response = await readerChannel.openReader(request);

        // Assert
        expect(response.status, 'ok');
        expect(response.isSuccess, true);
        expect(response.isError, false);
      });

      test('should return error response when native call fails', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'openReader') {
            return {
              'status': 'error',
              'error_code': 'FILE_NOT_FOUND',
              'error_message': 'File not found',
            };
          }
          return null;
        });

        final request = OpenReaderRequest(
          contentId: 123,
          type: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test-token',
          sessionId: 'session-123',
        );

        // Act
        final response = await readerChannel.openReader(request);

        // Assert
        expect(response.status, 'error');
        expect(response.isError, true);
        expect(response.errorCode, 'FILE_NOT_FOUND');
        expect(response.errorMessage, 'File not found');
      });

      test('should handle PlatformException gracefully', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'openReader') {
            throw PlatformException(
              code: 'NATIVE_ERROR',
              message: 'Native error occurred',
            );
          }
          return null;
        });

        final request = OpenReaderRequest(
          contentId: 123,
          type: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test-token',
          sessionId: 'session-123',
        );

        // Act
        final response = await readerChannel.openReader(request);

        // Assert
        expect(response.status, 'error');
        expect(response.errorCode, 'NATIVE_ERROR');
        expect(response.errorMessage, 'Native error occurred');
      });

      test('should handle null response', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          return null;
        });

        final request = OpenReaderRequest(
          contentId: 123,
          type: 'epub',
          fileUrl: 'https://example.com/book.epub',
          token: 'test-token',
          sessionId: 'session-123',
        );

        // Act
        final response = await readerChannel.openReader(request);

        // Assert
        expect(response.status, 'error');
        expect(response.errorCode, 'NULL_RESPONSE');
      });
    });

    group('closeReader', () {
      test('should call native closeReader method', () async {
        // Arrange
        bool methodCalled = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'closeReader') {
            methodCalled = true;
            expect(methodCall.arguments['session_id'], 'session-123');
          }
          return null;
        });

        // Act
        await readerChannel.closeReader('session-123');

        // Assert
        expect(methodCalled, true);
      });

      test('should throw exception when native call fails', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'closeReader') {
            throw PlatformException(
              code: 'CLOSE_ERROR',
              message: 'Failed to close',
            );
          }
          return null;
        });

        // Act & Assert
        expect(
          () => readerChannel.closeReader('session-123'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('setReaderPrefs', () {
      test('should call native setReaderPrefs method with preferences', () async {
        // Arrange
        bool methodCalled = false;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'setReaderPrefs') {
            methodCalled = true;
            final args = methodCall.arguments as Map;
            expect(args['font_size'], 18);
            expect(args['theme'], 'dark');
            expect(args['layout'], 'single');
          }
          return null;
        });

        final prefs = ReaderPreferences(
          fontSize: 18,
          theme: 'dark',
          layout: 'single',
        );

        // Act
        await readerChannel.setReaderPrefs(prefs);

        // Assert
        expect(methodCalled, true);
      });

      test('should throw exception when native call fails', () async {
        // Arrange
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (MethodCall methodCall) async {
          if (methodCall.method == 'setReaderPrefs') {
            throw PlatformException(
              code: 'PREFS_ERROR',
              message: 'Failed to set preferences',
            );
          }
          return null;
        });

        final prefs = ReaderPreferences(fontSize: 18);

        // Act & Assert
        expect(
          () => readerChannel.setReaderPrefs(prefs),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('readerEvents', () {
      test('should receive ReaderReadyEvent from event stream', () async {
        // Arrange
        final eventData = {
          'type': 'ready',
          'session_id': 'session-123',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'total_pages': 250,
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(eventData);
              events.endOfStream();
            },
          ),
        );

        // Act
        final event = await readerChannel.readerEvents.first;

        // Assert
        expect(event, isA<ReaderReadyEvent>());
        final readyEvent = event as ReaderReadyEvent;
        expect(readyEvent.sessionId, 'session-123');
        expect(readyEvent.totalPages, 250);
      });

      test('should receive EngagementEvent from event stream', () async {
        // Arrange
        final eventData = {
          'type': 'engagement',
          'session_id': 'session-123',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'event': 'page_turn',
          'page_index': 42,
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(eventData);
              events.endOfStream();
            },
          ),
        );

        // Act
        final event = await readerChannel.readerEvents.first;

        // Assert
        expect(event, isA<EngagementEvent>());
        final engagementEvent = event as EngagementEvent;
        expect(engagementEvent.sessionId, 'session-123');
        expect(engagementEvent.eventType, 'page_turn');
        expect(engagementEvent.pageIndex, 42);
      });

      test('should receive ReaderErrorEvent from event stream', () async {
        // Arrange
        final eventData = {
          'type': 'error',
          'session_id': 'session-123',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'code': 'RENDER_ERROR',
          'message': 'Failed to render page',
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
          eventChannel,
          MockStreamHandler.inline(
            onListen: (arguments, events) {
              events.success(eventData);
              events.endOfStream();
            },
          ),
        );

        // Act
        final event = await readerChannel.readerEvents.first;

        // Assert
        expect(event, isA<ReaderErrorEvent>());
        final errorEvent = event as ReaderErrorEvent;
        expect(errorEvent.sessionId, 'session-123');
        expect(errorEvent.code, 'RENDER_ERROR');
        expect(errorEvent.message, 'Failed to render page');
      });
    });
  });

  group('OpenReaderRequest', () {
    test('should serialize to map correctly', () {
      final request = OpenReaderRequest(
        contentId: 123,
        type: 'epub',
        fileUrl: 'https://example.com/book.epub',
        token: 'test-token',
        sessionId: 'session-123',
      );

      final map = request.toMap();

      expect(map['content_id'], 123);
      expect(map['type'], 'epub');
      expect(map['file_url'], 'https://example.com/book.epub');
      expect(map['token'], 'test-token');
      expect(map['session_id'], 'session-123');
    });

    test('should deserialize from map correctly', () {
      final map = {
        'content_id': 123,
        'type': 'pdf',
        'file_url': 'https://example.com/doc.pdf',
        'token': 'test-token',
        'session_id': 'session-456',
      };

      final request = OpenReaderRequest.fromMap(map);

      expect(request.contentId, 123);
      expect(request.type, 'pdf');
      expect(request.fileUrl, 'https://example.com/doc.pdf');
      expect(request.token, 'test-token');
      expect(request.sessionId, 'session-456');
    });
  });

  group('ReaderResponse', () {
    test('should indicate success correctly', () {
      final response = ReaderResponse(status: 'ok');

      expect(response.isSuccess, true);
      expect(response.isError, false);
    });

    test('should indicate error correctly', () {
      final response = ReaderResponse(
        status: 'error',
        errorCode: 'TEST_ERROR',
        errorMessage: 'Test error message',
      );

      expect(response.isSuccess, false);
      expect(response.isError, true);
      expect(response.errorCode, 'TEST_ERROR');
      expect(response.errorMessage, 'Test error message');
    });
  });

  group('ReaderPreferences', () {
    test('should serialize only non-null values', () {
      final prefs = ReaderPreferences(
        fontSize: 18,
        theme: 'dark',
      );

      final map = prefs.toMap();

      expect(map['font_size'], 18);
      expect(map['theme'], 'dark');
      expect(map.containsKey('layout'), false);
      expect(map.containsKey('font_family'), false);
    });

    test('should support copyWith', () {
      final prefs = ReaderPreferences(
        fontSize: 16,
        theme: 'light',
        layout: 'single',
      );

      final updated = prefs.copyWith(
        fontSize: 20,
        theme: 'dark',
      );

      expect(updated.fontSize, 20);
      expect(updated.theme, 'dark');
      expect(updated.layout, 'single'); // unchanged
    });
  });
}
