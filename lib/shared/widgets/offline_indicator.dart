import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/connectivity_provider.dart';

/// Global offline indicator widget
/// Displays a banner at the top of the screen when device is offline
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStream = ref.watch(connectivityProvider);

    return connectivityStream.when(
      data: (isOnline) {
        if (isOnline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.orange.shade100,
            border: Border(
              bottom: BorderSide(
                color: Colors.orange.shade300,
                width: 1,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off,
                size: 16,
                color: Colors.orange.shade900,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You are offline',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Offline indicator for app bar
/// Shows a small icon in the app bar when offline
class AppBarOfflineIndicator extends ConsumerWidget {
  const AppBarOfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStream = ref.watch(connectivityProvider);

    return connectivityStream.when(
      data: (isOnline) {
        if (isOnline) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Tooltip(
            message: 'Offline mode',
            child: Icon(
              Icons.cloud_off,
              size: 20,
              color: Colors.orange.shade700,
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
