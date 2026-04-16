import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knowvas/shared/models/security_settings_models.dart';
import 'package:knowvas/features/settings/data/repositories/security_settings_repository_provider.dart';

// State class for security settings
class SecuritySettingsState {
  final List<DeviceInfo> devices;
  final MfaStatus? mfaStatus;
  final bool isLoadingDevices;
  final bool isLoadingMfa;
  final bool isChangingPassword;
  final String? error;

  SecuritySettingsState({
    this.devices = const [],
    this.mfaStatus,
    this.isLoadingDevices = false,
    this.isLoadingMfa = false,
    this.isChangingPassword = false,
    this.error,
  });

  SecuritySettingsState copyWith({
    List<DeviceInfo>? devices,
    MfaStatus? mfaStatus,
    bool? isLoadingDevices,
    bool? isLoadingMfa,
    bool? isChangingPassword,
    String? error,
  }) {
    return SecuritySettingsState(
      devices: devices ?? this.devices,
      mfaStatus: mfaStatus ?? this.mfaStatus,
      isLoadingDevices: isLoadingDevices ?? this.isLoadingDevices,
      isLoadingMfa: isLoadingMfa ?? this.isLoadingMfa,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      error: error,
    );
  }
}

// Security settings provider
class SecuritySettingsNotifier extends StateNotifier<SecuritySettingsState> {
  final SecuritySettingsRepository _repository;

  SecuritySettingsNotifier(this._repository) : super(SecuritySettingsState());

  /// Load devices
  Future<void> loadDevices() async {
    state = state.copyWith(isLoadingDevices: true, error: null);
    try {
      final devices = await _repository.getDevices();
      state = state.copyWith(
        devices: devices,
        isLoadingDevices: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingDevices: false,
        error: e.toString(),
      );
    }
  }

  /// Load MFA status
  Future<void> loadMfaStatus() async {
    state = state.copyWith(isLoadingMfa: true, error: null);
    try {
      final mfaStatus = await _repository.getMfaStatus();
      state = state.copyWith(
        mfaStatus: mfaStatus,
        isLoadingMfa: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMfa: false,
        error: e.toString(),
      );
    }
  }

  /// Change password
  Future<bool> changePassword(PasswordChangeRequest request) async {
    state = state.copyWith(isChangingPassword: true, error: null);
    try {
      await _repository.changePassword(request);
      state = state.copyWith(isChangingPassword: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isChangingPassword: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Sign out device
  Future<bool> signOutDevice(int deviceId) async {
    try {
      await _repository.signOutDevice(deviceId);
      // Remove device from list
      state = state.copyWith(
        devices: state.devices.where((d) => d.id != deviceId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Sign out all devices
  Future<bool> signOutAllDevices() async {
    try {
      await _repository.signOutAllDevices();
      // Keep only current device
      state = state.copyWith(
        devices: state.devices.where((d) => d.isCurrent).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Toggle MFA
  Future<bool> toggleMfa(bool enable, {String? password}) async {
    try {
      await _repository.toggleMfa(enable, password: password);
      // Reload MFA status
      await loadMfaStatus();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final securitySettingsProvider = StateNotifierProvider<SecuritySettingsNotifier, SecuritySettingsState>((ref) {
  final repository = ref.watch(securitySettingsRepositoryProvider);
  return SecuritySettingsNotifier(repository);
});

