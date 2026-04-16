/// Data Transfer Objects for platform channel communication
/// These classes handle serialization/deserialization between Flutter and native code

/// Request object for opening a reader
class OpenReaderRequest {
  final int contentId;
  final String type; // 'epub', 'pdf', 'comic'
  final String fileUrl;
  final String token;
  final String sessionId;

  const OpenReaderRequest({
    required this.contentId,
    required this.type,
    required this.fileUrl,
    required this.token,
    required this.sessionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'content_id': contentId,
      'type': type,
      'file_url': fileUrl,
      'token': token,
      'session_id': sessionId,
    };
  }

  factory OpenReaderRequest.fromMap(Map<Object?, Object?> map) {
    return OpenReaderRequest(
      contentId: map['content_id'] as int,
      type: map['type'] as String,
      fileUrl: map['file_url'] as String,
      token: map['token'] as String,
      sessionId: map['session_id'] as String,
    );
  }
}

/// Response object from native reader operations
class ReaderResponse {
  final String status; // 'ok' or 'error'
  final String? errorCode;
  final String? errorMessage;

  const ReaderResponse({
    required this.status,
    this.errorCode,
    this.errorMessage,
  });

  bool get isSuccess => status == 'ok';
  bool get isError => status == 'error';

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      if (errorCode != null) 'error_code': errorCode,
      if (errorMessage != null) 'error_message': errorMessage,
    };
  }

  factory ReaderResponse.fromMap(Map<Object?, Object?> map) {
    return ReaderResponse(
      status: map['status'] as String,
      errorCode: map['error_code'] as String?,
      errorMessage: map['error_message'] as String?,
    );
  }
}

/// Reader preferences for customizing the reading experience
class ReaderPreferences {
  // Display settings
  final int? fontSize; // 12-32px
  final String? theme; // 'light', 'dark', 'sepia', 'black'
  final String? fontFamily; // 'serif', 'sans-serif', 'monospace', 'dyslexic'
  final double? lineHeight; // 1.0-2.5
  final double? letterSpacing; // -1.0 to 3.0
  final double? wordSpacing; // -2.0 to 5.0
  final double? brightness; // 0.3-1.0
  
  // Layout settings
  final String? layout; // 'single', 'double', 'scroll'
  final String? scrollMode; // 'vertical', 'horizontal'
  final double? margin; // 0.5-2.0
  final String? orientation; // 'auto', 'portrait', 'landscape'
  
  // Behavior settings
  final bool? tapToTurn;
  final bool? volumeKeyNavigation;
  final bool? pageTransitionAnimation;
  final double? animationSpeed; // 0.5-2.0
  
  // Accessibility settings
  final bool? highContrast;
  final bool? reduceMotion;

  const ReaderPreferences({
    // Display
    this.fontSize,
    this.theme,
    this.fontFamily,
    this.lineHeight,
    this.letterSpacing,
    this.wordSpacing,
    this.brightness,
    // Layout
    this.layout,
    this.scrollMode,
    this.margin,
    this.orientation,
    // Behavior
    this.tapToTurn,
    this.volumeKeyNavigation,
    this.pageTransitionAnimation,
    this.animationSpeed,
    // Accessibility
    this.highContrast,
    this.reduceMotion,
  });

  Map<String, dynamic> toMap() {
    return {
      // Display
      if (fontSize != null) 'font_size': fontSize,
      if (theme != null) 'theme': theme,
      if (fontFamily != null) 'font_family': fontFamily,
      if (lineHeight != null) 'line_height': lineHeight,
      if (letterSpacing != null) 'letter_spacing': letterSpacing,
      if (wordSpacing != null) 'word_spacing': wordSpacing,
      if (brightness != null) 'brightness': brightness,
      // Layout
      if (layout != null) 'layout': layout,
      if (scrollMode != null) 'scroll_mode': scrollMode,
      if (margin != null) 'margin': margin,
      if (orientation != null) 'orientation': orientation,
      // Behavior
      if (tapToTurn != null) 'tap_to_turn': tapToTurn,
      if (volumeKeyNavigation != null) 'volume_key_navigation': volumeKeyNavigation,
      if (pageTransitionAnimation != null) 'page_transition_animation': pageTransitionAnimation,
      if (animationSpeed != null) 'animation_speed': animationSpeed,
      // Accessibility
      if (highContrast != null) 'high_contrast': highContrast,
      if (reduceMotion != null) 'reduce_motion': reduceMotion,
    };
  }

  factory ReaderPreferences.fromMap(Map<Object?, Object?> map) {
    return ReaderPreferences(
      // Display
      fontSize: map['font_size'] as int?,
      theme: map['theme'] as String?,
      fontFamily: map['font_family'] as String?,
      lineHeight: map['line_height'] as double?,
      letterSpacing: map['letter_spacing'] as double?,
      wordSpacing: map['word_spacing'] as double?,
      brightness: map['brightness'] as double?,
      // Layout
      layout: map['layout'] as String?,
      scrollMode: map['scroll_mode'] as String?,
      margin: map['margin'] as double?,
      orientation: map['orientation'] as String?,
      // Behavior
      tapToTurn: map['tap_to_turn'] as bool?,
      volumeKeyNavigation: map['volume_key_navigation'] as bool?,
      pageTransitionAnimation: map['page_transition_animation'] as bool?,
      animationSpeed: map['animation_speed'] as double?,
      // Accessibility
      highContrast: map['high_contrast'] as bool?,
      reduceMotion: map['reduce_motion'] as bool?,
    );
  }

  ReaderPreferences copyWith({
    // Display
    int? fontSize,
    String? theme,
    String? fontFamily,
    double? lineHeight,
    double? letterSpacing,
    double? wordSpacing,
    double? brightness,
    // Layout
    String? layout,
    String? scrollMode,
    double? margin,
    String? orientation,
    // Behavior
    bool? tapToTurn,
    bool? volumeKeyNavigation,
    bool? pageTransitionAnimation,
    double? animationSpeed,
    // Accessibility
    bool? highContrast,
    bool? reduceMotion,
  }) {
    return ReaderPreferences(
      // Display
      fontSize: fontSize ?? this.fontSize,
      theme: theme ?? this.theme,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      brightness: brightness ?? this.brightness,
      // Layout
      layout: layout ?? this.layout,
      scrollMode: scrollMode ?? this.scrollMode,
      margin: margin ?? this.margin,
      orientation: orientation ?? this.orientation,
      // Behavior
      tapToTurn: tapToTurn ?? this.tapToTurn,
      volumeKeyNavigation: volumeKeyNavigation ?? this.volumeKeyNavigation,
      pageTransitionAnimation: pageTransitionAnimation ?? this.pageTransitionAnimation,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      // Accessibility
      highContrast: highContrast ?? this.highContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }
}

/// Base class for all reader events from native platform
sealed class ReaderEvent {
  final String sessionId;
  final DateTime timestamp;

  const ReaderEvent({
    required this.sessionId,
    required this.timestamp,
  });

  factory ReaderEvent.fromMap(Map<Object?, Object?> map) {
    final type = map['type'] as String;
    final sessionId = map['session_id'] as String;
    final timestamp = DateTime.fromMillisecondsSinceEpoch(
      map['timestamp'] as int,
    );

    switch (type) {
      case 'ready':
        return ReaderReadyEvent(
          sessionId: sessionId,
          timestamp: timestamp,
          totalPages: map['total_pages'] as int,
        );
      case 'engagement':
        return EngagementEvent(
          sessionId: sessionId,
          timestamp: timestamp,
          eventType: map['event'] as String,
          pageIndex: map['page_index'] as int?,
          payload: map['payload'] as Map<String, dynamic>?,
        );
      case 'error':
        return ReaderErrorEvent(
          sessionId: sessionId,
          timestamp: timestamp,
          code: map['code'] as String,
          message: map['message'] as String,
        );
      default:
        throw ArgumentError('Unknown reader event type: $type');
    }
  }
}

/// Event emitted when the reader is ready to display content
class ReaderReadyEvent extends ReaderEvent {
  final int totalPages;

  const ReaderReadyEvent({
    required super.sessionId,
    required super.timestamp,
    required this.totalPages,
  });
}

/// Event emitted for user engagement actions (page turns, bookmarks, highlights)
class EngagementEvent extends ReaderEvent {
  final String eventType; // 'page_turn', 'bookmark', 'highlight', 'session_end'
  final int? pageIndex;
  final Map<String, dynamic>? payload;

  const EngagementEvent({
    required super.sessionId,
    required super.timestamp,
    required this.eventType,
    this.pageIndex,
    this.payload,
  });
}

/// Event emitted when an error occurs in the native reader
class ReaderErrorEvent extends ReaderEvent {
  final String code;
  final String message;

  const ReaderErrorEvent({
    required super.sessionId,
    required super.timestamp,
    required this.code,
    required this.message,
  });
}
