import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/shared/models/preferences_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

// State class for preferences
class PreferencesState {
  final AppPreferences preferences;
  final bool isLoading;
  final String? error;

  PreferencesState({
    required this.preferences,
    this.isLoading = false,
    this.error,
  });

  PreferencesState copyWith({
    AppPreferences? preferences,
    bool? isLoading,
    String? error,
  }) {
    return PreferencesState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Preferences provider (uses local storage)
class PreferencesNotifier extends StateNotifier<PreferencesState> {
  static const String _storageKey = 'knowvas_preferences';

  PreferencesNotifier() : super(PreferencesState(preferences: AppPreferences())) {
    loadPreferences();
  }

  /// Load preferences from local storage
  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final preferences = AppPreferences.fromJson(json);
        state = state.copyWith(
          preferences: preferences,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Save preferences to local storage
  Future<void> savePreferences(AppPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(preferences.toJson());
      await prefs.setString(_storageKey, jsonString);
      
      state = state.copyWith(preferences: preferences);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update a single preference
  Future<void> updatePreference(AppPreferences newPreferences) async {
    await savePreferences(newPreferences);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final preferencesProvider = StateNotifierProvider<PreferencesNotifier, PreferencesState>((ref) {
  return PreferencesNotifier();
});

