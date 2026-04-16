import 'package:equatable/equatable.dart';

import '../../../../shared/models/feed.dart';

/// Homepage state — now driven by the feed endpoint
class HomepageState extends Equatable {
  const HomepageState({
    this.feedResponse,
    this.isLoading = false,
    this.error,
    this.isInitialized = false,
  });

  final FeedResponse? feedResponse;
  final bool isLoading;
  final String? error;
  final bool isInitialized;

  factory HomepageState.initial() {
    return const HomepageState(isLoading: true);
  }

  factory HomepageState.loaded(FeedResponse response) {
    return HomepageState(
      feedResponse: response,
      isLoading: false,
      isInitialized: true,
    );
  }

  factory HomepageState.error(String message) {
    return HomepageState(
      isLoading: false,
      error: message,
      isInitialized: true,
    );
  }

  HomepageState copyWith({
    FeedResponse? feedResponse,
    bool? isLoading,
    String? error,
    bool? isInitialized,
  }) {
    return HomepageState(
      feedResponse: feedResponse ?? this.feedResponse,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  HomepageState copyWithLoading() {
    return HomepageState(
      feedResponse: feedResponse,
      isLoading: true,
      error: null,
      isInitialized: isInitialized,
    );
  }

  HomepageState copyWithError(String message) {
    return HomepageState(
      feedResponse: feedResponse,
      isLoading: false,
      error: message,
      isInitialized: true,
    );
  }

  @override
  List<Object?> get props => [feedResponse, isLoading, error, isInitialized];
}
