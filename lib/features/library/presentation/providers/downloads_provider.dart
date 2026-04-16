import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/download/download_manager.dart';
import '../../../../core/download/download_manager_provider.dart';
import '../../../../core/notifications/download_notification_service_provider.dart';
import '../../../../core/utils/storage_utils.dart';
import '../../../../shared/models/library_item.dart';
import 'library_provider.dart';

part 'downloads_provider.g.dart';

/// State for downloads
class DownloadsState {
  final Map<int, DownloadProgress> activeDownloads;
  final List<DownloadedContent> completedDownloads;
  final bool isLoading;
  final String? error;

  const DownloadsState({
    this.activeDownloads = const {},
    this.completedDownloads = const [],
    this.isLoading = false,
    this.error,
  });

  DownloadsState copyWith({
    Map<int, DownloadProgress>? activeDownloads,
    List<DownloadedContent>? completedDownloads,
    bool? isLoading,
    String? error,
  }) {
    return DownloadsState(
      activeDownloads: activeDownloads ?? this.activeDownloads,
      completedDownloads: completedDownloads ?? this.completedDownloads,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for managing downloads
@riverpod
class Downloads extends _$Downloads {
  DownloadManager get _downloadManager => ref.read(downloadManagerProvider);

  @override
  DownloadsState build() {
    _loadDownloads();
    return const DownloadsState();
  }

  /// Load all downloads
  Future<void> _loadDownloads() async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Get user ID from auth or use placeholder
      const userId = 'current_user'; // TODO: Get from auth provider
      
      final completed = await _downloadManager.getDownloadedContent(userId);
      
      state = state.copyWith(
        completedDownloads: completed,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to load downloads: $e',
        isLoading: false,
      );
    }
  }

  /// Start downloading content
  Future<void> startDownload({
    required LibraryItem item,
    required String signedUrl,
    required String quality,
    int? estimatedSize,
  }) async {
    try {
      // Check storage space before download
      if (estimatedSize != null) {
        final hasSpace = await StorageUtils.hasEnoughStorage(estimatedSize);
        if (!hasSpace) {
          state = state.copyWith(
            error: 'Not enough storage space. Please free up space and try again.',
          );
          return;
        }
      }
      
      const userId = 'current_user'; // TODO: Get from auth provider
      final notificationService = ref.read(downloadNotificationServiceProvider);
      
      // Show start notification
      await notificationService.showDownloadStarted(
        contentId: item.id,
        title: item.title,
      );
      
      // Start download
      await _downloadManager.downloadContent(
        contentId: item.id,
        signedUrl: signedUrl,
        userId: userId,
        quality: quality,
      );

      // Watch progress
      final progressStream = _downloadManager.watchDownload(item.id);
      if (progressStream != null) {
        progressStream.listen((progress) {
          _updateDownloadProgress(progress);
        });
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to start download: $e');
    }
  }

  /// Update download progress
  void _updateDownloadProgress(DownloadProgress progress) {
    final updatedDownloads = Map<int, DownloadProgress>.from(state.activeDownloads);
    final notificationService = ref.read(downloadNotificationServiceProvider);
    
    if (progress.status == DownloadStatus.completed) {
      updatedDownloads.remove(progress.contentId);
      _loadDownloads(); // Reload to get updated completed downloads
      
      // Show completion notification
      notificationService.showDownloadCompleted(
        contentId: progress.contentId,
        title: 'Content ${progress.contentId}',
      );
    } else if (progress.status == DownloadStatus.cancelled) {
      updatedDownloads.remove(progress.contentId);
      notificationService.cancelNotification(progress.contentId);
    } else if (progress.status == DownloadStatus.failed) {
      updatedDownloads.remove(progress.contentId);
      
      // Show failure notification
      notificationService.showDownloadFailed(
        contentId: progress.contentId,
        title: 'Content ${progress.contentId}',
        error: progress.error,
      );
    } else if (progress.status == DownloadStatus.downloading) {
      updatedDownloads[progress.contentId] = progress;
      
      // Update progress notification (throttled in production)
      if (progress.progress > 0 && progress.progress % 0.1 < 0.01) {
        notificationService.updateDownloadProgress(
          contentId: progress.contentId,
          title: 'Content ${progress.contentId}',
          progress: progress,
        );
      }
    } else {
      updatedDownloads[progress.contentId] = progress;
    }
    
    state = state.copyWith(activeDownloads: updatedDownloads);
  }

  /// Pause download
  Future<void> pauseDownload(int contentId) async {
    try {
      await _downloadManager.pauseDownload(contentId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to pause download: $e');
    }
  }

  /// Resume download
  Future<void> resumeDownload(int contentId) async {
    try {
      await _downloadManager.resumeDownload(contentId);
    } catch (e) {
      state = state.copyWith(error: 'Failed to resume download: $e');
    }
  }

  /// Cancel download
  Future<void> cancelDownload(int contentId) async {
    try {
      await _downloadManager.cancelDownload(contentId);
      
      final updatedDownloads = Map<int, DownloadProgress>.from(state.activeDownloads);
      updatedDownloads.remove(contentId);
      
      state = state.copyWith(activeDownloads: updatedDownloads);
    } catch (e) {
      state = state.copyWith(error: 'Failed to cancel download: $e');
    }
  }

  /// Delete downloaded content
  Future<void> deleteDownload(int contentId) async {
    try {
      const userId = 'current_user'; // TODO: Get from auth provider
      
      await _downloadManager.deleteDownload(contentId, userId);
      await _loadDownloads();
      
      // Refresh library to update download status
      ref.invalidate(libraryProvider);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete download: $e');
    }
  }

  /// Refresh downloads
  Future<void> refresh() async {
    await _loadDownloads();
  }
}

