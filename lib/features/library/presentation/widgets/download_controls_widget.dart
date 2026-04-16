import 'package:flutter/material.dart';
import '../../../../core/download/download_manager.dart';

/// Widget with download control buttons (pause, resume, cancel)
class DownloadControlsWidget extends StatelessWidget {
  final DownloadProgress progress;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCancel;

  const DownloadControlsWidget({
    super.key,
    required this.progress,
    this.onPause,
    this.onResume,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Pause/Resume button
        if (progress.status == DownloadStatus.downloading)
          IconButton(
            icon: const Icon(Icons.pause_circle_outline),
            onPressed: onPause,
            tooltip: 'Pause',
            iconSize: 28,
          )
        else if (progress.status == DownloadStatus.paused)
          IconButton(
            icon: const Icon(Icons.play_circle_outline),
            onPressed: onResume,
            tooltip: 'Resume',
            iconSize: 28,
          ),
        
        // Cancel button
        if (progress.status == DownloadStatus.downloading ||
            progress.status == DownloadStatus.paused ||
            progress.status == DownloadStatus.queued)
          IconButton(
            icon: const Icon(Icons.cancel_outlined),
            onPressed: onCancel,
            tooltip: 'Cancel',
            iconSize: 28,
            color: Theme.of(context).colorScheme.error,
          ),
        
        // Retry button for failed downloads
        if (progress.status == DownloadStatus.failed)
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: onResume,
            tooltip: 'Retry',
            iconSize: 28,
          ),
      ],
    );
  }
}
