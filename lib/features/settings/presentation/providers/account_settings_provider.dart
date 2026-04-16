import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/shared/models/account_settings_models.dart';
import 'package:knowvas/features/settings/data/repositories/account_settings_repository_provider.dart';

// State class for account settings
class AccountSettingsState {
  final AccountSettings? settings;
  final AccountSettings? originalSettings;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  AccountSettingsState({
    this.settings,
    this.originalSettings,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
  });

  bool get hasChanges {
    if (settings == null || originalSettings == null) return false;
    return settings!.toJson().toString() != originalSettings!.toJson().toString();
  }

  AccountSettingsState copyWith({
    AccountSettings? settings,
    AccountSettings? originalSettings,
    bool? isLoading,
    bool? isSaving,
    String? error,
  }) {
    return AccountSettingsState(
      settings: settings ?? this.settings,
      originalSettings: originalSettings ?? this.originalSettings,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
    );
  }
}

// Account settings provider
class AccountSettingsNotifier extends StateNotifier<AccountSettingsState> {
  final AccountSettingsRepository _repository;

  AccountSettingsNotifier(this._repository) : super(AccountSettingsState());

  /// Load account settings
  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final settings = await _repository.getAccountSettings();
      state = state.copyWith(
        settings: settings,
        originalSettings: settings,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update settings locally (before saving)
  void updateSettings(AccountSettings settings) {
    state = state.copyWith(settings: settings);
  }

  /// Save settings to backend
  Future<bool> saveSettings() async {
    if (state.settings == null) return false;

    state = state.copyWith(isSaving: true, error: null);
    try {
      final updatedSettings = await _repository.updateAccountSettings(state.settings!);
      state = state.copyWith(
        settings: updatedSettings,
        originalSettings: updatedSettings,
        isSaving: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Reset to original settings
  void resetSettings() {
    if (state.originalSettings != null) {
      state = state.copyWith(settings: state.originalSettings);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final accountSettingsProvider = StateNotifierProvider<AccountSettingsNotifier, AccountSettingsState>((ref) {
  final repository = ref.watch(accountSettingsRepositoryProvider);
  return AccountSettingsNotifier(repository);
});

