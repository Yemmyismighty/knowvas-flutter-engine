import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:knowvas/core/network/api_client.dart';
import 'package:knowvas/shared/models/device_models.dart';

class DevicesState {
  final List<Device> devices;
  final bool isLoading;
  final String? error;

  DevicesState({
    this.devices = const [],
    this.isLoading = false,
    this.error,
  });

  DevicesState copyWith({
    List<Device>? devices,
    bool? isLoading,
    String? error,
  }) {
    return DevicesState(
      devices: devices ?? this.devices,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DevicesNotifier extends StateNotifier<DevicesState> {
  final ApiClient _apiClient;

  DevicesNotifier(this._apiClient) : super(DevicesState()) {
    loadDevices();
  }

  Future<void> loadDevices() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.get('/api/user/devices');

      if (response.data['status'] == 'success') {
        final devices = (response.data['data'] as List)
            .map((json) => Device.fromJson(json))
            .toList();

        state = state.copyWith(devices: devices, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to load devices',
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.response?.data['message'] ?? 'Network error',
      );
    }
  }

  Future<void> signOutDevice(int deviceId) async {
    try {
      final response = await _apiClient.post(
        '/api/user/devices/$deviceId/sign-out',
      );

      if (response.data['status'] == 'success') {
        // Remove device from list
        state = state.copyWith(
          devices: state.devices.where((d) => d.id != deviceId).toList(),
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'Failed to sign out device',
      );
    }
  }

  Future<void> signOutAllDevices() async {
    try {
      final response = await _apiClient.post('/api/user/devices/sign-out-all');

      if (response.data['status'] == 'success') {
        // Keep only current device
        state = state.copyWith(
          devices: state.devices.where((d) => d.isCurrent).toList(),
        );
      }
    } on DioException catch (e) {
      state = state.copyWith(
        error: e.response?.data['message'] ?? 'Failed to sign out devices',
      );
    }
  }
}

final devicesProvider = StateNotifierProvider<DevicesNotifier, DevicesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DevicesNotifier(apiClient);
});

