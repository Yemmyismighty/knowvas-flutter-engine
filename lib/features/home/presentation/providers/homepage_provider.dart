import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/errors/failures.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../discover/data/repositories/content_repository.dart';
import '../../../discover/data/repositories/content_repository_provider.dart';
import 'homepage_state.dart';

part 'homepage_provider.g.dart';

/// HomepageNotifier — drives the feed-based home screen
@riverpod
class Homepage extends _$Homepage {
  DateTime? _lastFetchTime;
  bool? _lastFetchWasAuthenticated;
  static const _cacheDuration = Duration(minutes: 10);

  @override
  HomepageState build() {
    ref.keepAlive();

    // Watch auth state — force-refresh when auth changes
    final isAuthenticated = ref.watch(
      authProvider.select((s) => s.isAuthenticated),
    );

    // If auth state changed since last fetch, invalidate cache
    if (_lastFetchWasAuthenticated != null &&
        _lastFetchWasAuthenticated != isAuthenticated) {
      _lastFetchTime = null;
    }

    Future.microtask(() => fetchFeed());
    return HomepageState.initial();
  }

  /// Fetch the algorithmic feed
  Future<void> fetchFeed({bool forceRefresh = false}) async {
    final isAuthenticated = ref.read(
      authProvider.select((s) => s.isAuthenticated),
    );

    // Use cache if still fresh and auth state hasn't changed
    if (!forceRefresh &&
        state.feedResponse != null &&
        _lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheDuration &&
        _lastFetchWasAuthenticated == isAuthenticated) {
      return;
    }

    if (state.feedResponse == null) {
      state = state.copyWithLoading();
    }

    try {
      final repository = ref.read<ContentRepository>(contentRepositoryProvider);
      final feedResponse = await repository.getFeed();

      _lastFetchTime = DateTime.now();
      _lastFetchWasAuthenticated = isAuthenticated;
      state = HomepageState.loaded(feedResponse);
    } on NetworkFailure catch (e) {
      state = state.feedResponse != null
          ? state.copyWith(error: e.message)
          : HomepageState.error(e.message);
    } on ServerFailure catch (e) {
      state = state.feedResponse != null
          ? state.copyWith(error: e.message)
          : HomepageState.error(e.message);
    } catch (e) {
      state = state.feedResponse != null
          ? state.copyWith(error: e.toString())
          : HomepageState.error(e.toString());
    }
  }

  /// Force-refresh — bypasses cache (called on login/logout)
  Future<void> refresh() async {
    _lastFetchTime = null;
    await fetchFeed(forceRefresh: true);
  }
}
