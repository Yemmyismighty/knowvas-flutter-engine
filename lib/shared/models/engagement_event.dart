import 'package:equatable/equatable.dart';

/// Engagement event model
class EngagementEvent extends Equatable {
  final int? id;
  final int contentId;
  final String sessionId;
  final String eventType; // 'open', 'page_turn', 'close', 'bookmark', 'highlight', 'read_progress'
  final Map<String, dynamic>? payload;
  final DateTime timestamp;
  final bool uploaded;

  const EngagementEvent({
    this.id,
    required this.contentId,
    required this.sessionId,
    required this.eventType,
    this.payload,
    required this.timestamp,
    this.uploaded = false,
  });

  factory EngagementEvent.fromJson(Map<String, dynamic> json) {
    return EngagementEvent(
      id: json['id'] as int?,
      contentId: json['content_id'] as int,
      sessionId: json['session_id'] as String,
      eventType: json['event_type'] as String,
      payload: json['payload'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      uploaded: json['uploaded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content_id': contentId,
      'session_id': sessionId,
      'event_type': eventType,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'uploaded': uploaded,
    };
  }

  EngagementEvent copyWith({
    int? id,
    int? contentId,
    String? sessionId,
    String? eventType,
    Map<String, dynamic>? payload,
    DateTime? timestamp,
    bool? uploaded,
  }) {
    return EngagementEvent(
      id: id ?? this.id,
      contentId: contentId ?? this.contentId,
      sessionId: sessionId ?? this.sessionId,
      eventType: eventType ?? this.eventType,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      uploaded: uploaded ?? this.uploaded,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contentId,
        sessionId,
        eventType,
        payload,
        timestamp,
        uploaded,
      ];
}

/// Batch engagement upload request
class EngagementBatchRequest extends Equatable {
  final List<EngagementEvent> events;

  const EngagementBatchRequest({required this.events});

  Map<String, dynamic> toJson() {
    return {
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [events];
}
