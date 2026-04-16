import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Image optimization utilities for reducing memory footprint
class ImageOptimizer {
  /// Resize image to fit within max dimensions while maintaining aspect ratio
  static Future<Uint8List?> resizeImage({
    required Uint8List imageData,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      final codec = await ui.instantiateImageCodec(
        imageData,
        targetWidth: maxWidth,
        targetHeight: maxHeight,
      );
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to resize image: $e');
      return null;
    }
  }

  /// Calculate optimal cache dimensions based on screen size
  static Size calculateCacheSize(BuildContext context, {double scale = 1.0}) {
    final mediaQuery = MediaQuery.of(context);
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final screenSize = mediaQuery.size;

    return Size(
      screenSize.width * devicePixelRatio * scale,
      screenSize.height * devicePixelRatio * scale,
    );
  }

  /// Get memory-efficient image cache configuration
  static ImageCacheConfig getOptimalCacheConfig() {
    return const ImageCacheConfig(
      // Limit cache size to 100MB
      maxByteSize: 100 * 1024 * 1024,
      // Keep max 1000 images in cache
      maxImageCount: 1000,
    );
  }

  /// Clear image cache to free memory
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();
  }

  /// Precache images for better performance
  static Future<void> precacheImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (e) {
        debugPrint('Failed to precache image $url: $e');
      }
    }
  }
}

/// Image cache configuration
class ImageCacheConfig {
  final int maxByteSize;
  final int maxImageCount;

  const ImageCacheConfig({
    required this.maxByteSize,
    required this.maxImageCount,
  });

  void apply() {
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSizeBytes = maxByteSize;
    imageCache.maximumSize = maxImageCount;
  }
}
