import 'dart:async';
import 'package:flutter/services.dart';
import 'reader_dtos.dart';

/// Platform channel interface for communicating with native reader modules
/// Handles method calls and event streams between Flutter and native code
class ReaderChannel {
  static const MethodChannel _methodChannel =
      MethodChannel('com.knowvas.reader/channel');
  static const EventChannel _eventChannel =
      EventChannel('com.knowvas.reader/events');

  Stream<ReaderEvent>? _eventStream;

  /// Opens a reader for the specified content
  /// 
  /// Sends an [OpenReaderRequest] to the native platform and returns
  /// a [ReaderResponse] indicating success or failure
  /// 
  /// Throws [PlatformException] if the platform channel communication fails
  Future<ReaderResponse> openReader(OpenReaderRequest request) async {
    try {
      final result = await _methodChannel.invokeMethod<Map<Object?, Object?>>(
        'openReader',
        request.toMap(),
      );

      if (result == null) {
        return ReaderResponse(
          status: 'error',
          errorCode: 'NULL_RESPONSE',
          errorMessage: 'Received null response from native platform',
        );
      }

      return ReaderResponse.fromMap(result);
    } on PlatformException catch (e) {
      return ReaderResponse(
        status: 'error',
        errorCode: e.code,
        errorMessage: e.message ?? 'Platform exception occurred',
      );
    } catch (e) {
      return ReaderResponse(
        status: 'error',
        errorCode: 'UNKNOWN_ERROR',
        errorMessage: e.toString(),
      );
    }
  }

  /// Closes the reader for the specified session
  /// 
  /// Sends a close request to the native platform with the [sessionId]
  /// 
  /// Throws [PlatformException] if the platform channel communication fails
  Future<void> closeReader(String sessionId) async {
    try {
      await _methodChannel.invokeMethod<void>(
        'closeReader',
        {'session_id': sessionId},
      );
    } on PlatformException catch (e) {
      throw Exception('Failed to close reader: ${e.message}');
    }
  }

  /// Sets reader preferences for the current reading session
  /// 
  /// Sends [ReaderPreferences] to the native platform to update
  /// reader settings like font size, theme, layout, etc.
  /// 
  /// Throws [PlatformException] if the platform channel communication fails
  Future<void> setReaderPrefs(ReaderPreferences prefs) async {
    try {
      await _methodChannel.invokeMethod<void>(
        'setReaderPrefs',
        prefs.toMap(),
      );
    } on PlatformException catch (e) {
      throw Exception('Failed to set reader preferences: ${e.message}');
    }
  }

  /// Stream of reader events from the native platform
  /// 
  /// Listens to events like reader ready, page turns, bookmarks, highlights,
  /// and errors from the native reader modules
  /// 
  /// Returns a broadcast stream that can be listened to by multiple subscribers
  Stream<ReaderEvent> get readerEvents {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .map((dynamic event) => ReaderEvent.fromMap(event as Map<Object?, Object?>))
        .handleError((error) {
      // Log error but don't break the stream
      print('Error in reader event stream: $error');
    });

    return _eventStream!;
  }
}
