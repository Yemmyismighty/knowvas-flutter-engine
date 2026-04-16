import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/profile_models.dart';
import '../../data/repositories/profile_repository_provider.dart';

/// Profile data state
class ProfileDataState {
  final ProfileHeader? profileHeader;
  final ReadingGoal? readingGoal;
  final QuickStats? quickStats;
  final List<Achievement> achievements;
  final List<Activity> activity;
  final bool isLoading;
  final bool isHeaderLoading;
  final bool isGoalLoading;
  final bool isStatsLoading;
  final bool isAchievementsLoading;
  final bool isActivityLoading;
  final String? error;

  const ProfileDataState({
    this.profileHeader,
    this.readingGoal,
    this.quickStats,
    this.achievements = const [],
    this.activity = const [],
    this.isLoading = false,
    this.isHeaderLoading = false,
    this.isGoalLoading = false,
    this.isStatsLoading = false,
    this.isAchievementsLoading = false,
    this.isActivityLoading = false,
    this.error,
  });

  ProfileDataState copyWith({
    ProfileHeader? profileHeader,
    ReadingGoal? readingGoal,
    QuickStats? quickStats,
    List<Achievement>? achievements,
    List<Activity>? activity,
    bool? isLoading,
    bool? isHeaderLoading,
    bool? isGoalLoading,
    bool? isStatsLoading,
    bool? isAchievementsLoading,
    bool? isActivityLoading,
    String? error,
    bool clearError = false,
  }) {
    return ProfileDataState(
      profileHeader: profileHeader ?? this.profileHeader,
      readingGoal: readingGoal ?? this.readingGoal,
      quickStats: quickStats ?? this.quickStats,
      achievements: achievements ?? this.achievements,
      activity: activity ?? this.activity,
      isLoading: isLoading ?? this.isLoading,
      isHeaderLoading: isHeaderLoading ?? this.isHeaderLoading,
      isGoalLoading: isGoalLoading ?? this.isGoalLoading,
      isStatsLoading: isStatsLoading ?? this.isStatsLoading,
      isAchievementsLoading: isAchievementsLoading ?? this.isAchievementsLoading,
      isActivityLoading: isActivityLoading ?? this.isActivityLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Profile data notifier
class ProfileDataNotifier extends StateNotifier<ProfileDataState> {
  ProfileDataNotifier(this._repository) : super(const ProfileDataState()) {
    loadAllData();
  }

  final ProfileRepository _repository;

  /// Load all profile data
  Future<void> loadAllData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    await Future.wait([
      loadProfileHeader(),
      loadReadingGoal(),
      loadQuickStats(),
      loadAchievements(),
      loadActivity(),
    ]);

    state = state.copyWith(isLoading: false);
  }

  /// Load profile header
  Future<void> loadProfileHeader() async {
    state = state.copyWith(isHeaderLoading: true);

    try {
      final header = await _repository.getProfileHeader();
      state = state.copyWith(
        profileHeader: header,
        isHeaderLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isHeaderLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load reading goal
  Future<void> loadReadingGoal() async {
    state = state.copyWith(isGoalLoading: true);

    try {
      final goal = await _repository.getReadingGoal();
      state = state.copyWith(
        readingGoal: goal,
        isGoalLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isGoalLoading: false);
    }
  }

  /// Create reading goal
  Future<void> createReadingGoal(int targetBooks) async {
    state = state.copyWith(isGoalLoading: true);

    try {
      final goal = await _repository.createReadingGoal(targetBooks);
      state = state.copyWith(
        readingGoal: goal,
        isGoalLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isGoalLoading: false,
        error: 'Failed to create reading goal',
      );
    }
  }

  /// Load quick stats
  Future<void> loadQuickStats() async {
    state = state.copyWith(isStatsLoading: true);

    try {
      final stats = await _repository.getQuickStats();
      state = state.copyWith(
        quickStats: stats,
        isStatsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isStatsLoading: false);
    }
  }

  /// Load achievements
  Future<void> loadAchievements() async {
    state = state.copyWith(isAchievementsLoading: true);

    try {
      final achievements = await _repository.getAchievements();
      state = state.copyWith(
        achievements: achievements,
        isAchievementsLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isAchievementsLoading: false);
    }
  }

  /// Load activity
  Future<void> loadActivity() async {
    state = state.copyWith(isActivityLoading: true);

    try {
      final activity = await _repository.getActivity();
      state = state.copyWith(
        activity: activity,
        isActivityLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isActivityLoading: false);
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadAllData();
  }
}

/// Profile data provider
final profileDataProvider = StateNotifierProvider<ProfileDataNotifier, ProfileDataState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileDataNotifier(repository);
});
