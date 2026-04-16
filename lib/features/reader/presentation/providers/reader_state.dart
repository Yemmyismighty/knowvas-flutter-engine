import 'package:equatable/equatable.dart';

import '../../../../core/platform/reader_dtos.dart';

/// Reader state for managing current reading session
class ReaderState extends Equatable {
  const ReaderState({
    this.sessionId,
    this.contentId,
    this.contentType,
    this.currentPage,
    this.totalPages,
    this.preferences = const ReaderPreferences(),
    this.isLoading = false,
    this.error,
    this.isReaderOpen = false,
  });

  /// Initial state - no content open
  factory ReaderState.initial() {
    return const ReaderState();
  }

  /// Loading state when opening content
  factory ReaderState.loading({
    required int contentId,
    required String contentType,
  }) {
    return ReaderState(
      contentId: contentId,
      contentType: contentType,
      isLoading: true,
    );
  }

  /// Reader open and ready state
  factory ReaderState.ready({
    required String sessionId,
    required int contentId,
    required String contentType,
    required int totalPages,
    ReaderPreferences preferences = const ReaderPreferences(),
  }) {
    return ReaderState(
      sessionId: sessionId,
      contentId: contentId,
      contentType: contentType,
      totalPages: totalPages,
      preferences: preferences,
      isReaderOpen: true,
      currentPage: 0,
    );
  }

  /// Error state
  factory ReaderState.error(String error) {
    return ReaderState(
      error: error,
    );
  }

  final String? sessionId;
  final int? contentId;
  final String? contentType;
  final int? currentPage;
  final int? totalPages;
  final ReaderPreferences preferences;
  final bool isLoading;
  final String? error;
  final bool isReaderOpen;

  /// Calculate reading progress as percentage
  double get progress {
    if (totalPages == null || totalPages == 0 || currentPage == null) {
      return 0;
    }
    return (currentPage! / totalPages!).clamp(0, 1);
  }

  /// Check if reader has content loaded
  bool get hasContent => contentId != null && isReaderOpen;

  /// Copy with loading state
  ReaderState copyWithLoading() {
    return ReaderState(
      sessionId: sessionId,
      contentId: contentId,
      contentType: contentType,
      currentPage: currentPage,
      totalPages: totalPages,
      preferences: preferences,
      isLoading: true,
      isReaderOpen: isReaderOpen,
    );
  }

  /// Copy with error state
  ReaderState copyWithError(String error) {
    return ReaderState(
      sessionId: sessionId,
      contentId: contentId,
      contentType: contentType,
      currentPage: currentPage,
      totalPages: totalPages,
      preferences: preferences,
      error: error,
      isReaderOpen: isReaderOpen,
    );
  }

  /// Copy with new values
  ReaderState copyWith({
    String? sessionId,
    int? contentId,
    String? contentType,
    int? currentPage,
    int? totalPages,
    ReaderPreferences? preferences,
    bool? isLoading,
    String? error,
    bool? isReaderOpen,
  }) {
    return ReaderState(
      sessionId: sessionId ?? this.sessionId,
      contentId: contentId ?? this.contentId,
      contentType: contentType ?? this.contentType,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isReaderOpen: isReaderOpen ?? this.isReaderOpen,
    );
  }

  @override
  List<Object?> get props => [
        sessionId,
        contentId,
        contentType,
        currentPage,
        totalPages,
        preferences,
        isLoading,
        error,
        isReaderOpen,
      ];
}
