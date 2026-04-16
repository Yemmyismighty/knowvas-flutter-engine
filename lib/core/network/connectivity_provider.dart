import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'network_info.dart';

part 'connectivity_provider.g.dart';

/// Provider for NetworkInfo instance
@riverpod
NetworkInfo networkInfo(NetworkInfoRef ref) {
  return NetworkInfo();
}

/// Provider that watches connectivity status
/// Returns true if device is connected to the internet
@riverpod
Stream<bool> connectivity(ConnectivityRef ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.onConnectivityChanged;
}

/// Provider for current connectivity status
/// Returns true if device is currently connected
@riverpod
Future<bool> isOnline(IsOnlineRef ref) async {
  final networkInfo = ref.watch(networkInfoProvider);
  return await networkInfo.isConnected;
}
