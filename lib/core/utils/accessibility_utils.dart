import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

/// Accessibility utilities for the Knowvas app
/// Provides helpers for semantic labels, touch targets, and screen reader support
class AccessibilityUtils {
  AccessibilityUtils._();

  /// Minimum touch target size per Material Design guidelines (48x48 dp)
  static const double minTouchTargetSize = 48.0;

  /// Recommended touch target size for better accessibility (56x56 dp)
  static const double recommendedTouchTargetSize = 56.0;

  /// WCAG AA contrast ratio requirement
  static const double minContrastRatioAA = 4.5;

  /// WCAG AAA contrast ratio requirement
  static const double minContrastRatioAAA = 7.0;

  /// Calculate relative luminance of a color
  /// Used for contrast ratio calculations
  static double _relativeLuminance(Color color) {
    final r = _linearize(color.red / 255.0);
    final g = _linearize(color.green / 255.0);
    final b = _linearize(color.blue / 255.0);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Linearize RGB channel value
  static double _linearize(double channel) {
    if (channel <= 0.03928) {
      return channel / 12.92;
    }
    return math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Calculate contrast ratio between two colors
  /// Returns a value between 1 and 21
  static double calculateContrastRatio(Color foreground, Color background) {
    final l1 = _relativeLuminance(foreground);
    final l2 = _relativeLuminance(background);
    final lighter = l1 > l2 ? l1 : l2;
    final darker = l1 > l2 ? l2 : l1;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check if contrast ratio meets WCAG AA standards
  static bool meetsContrastAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= minContrastRatioAA;
  }

  /// Check if contrast ratio meets WCAG AAA standards
  static bool meetsContrastAAA(Color foreground, Color background) {
    return calculateContrastRatio(foreground, background) >= minContrastRatioAAA;
  }

  /// Wrap a widget to ensure minimum touch target size
  static Widget ensureTouchTarget({
    required Widget child,
    double minSize = minTouchTargetSize,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: child,
    );
  }

  /// Create a semantic label for reading progress
  static String readingProgressLabel(double progress) {
    final percentage = (progress * 100).round();
    return 'Reading progress: $percentage percent';
  }

  /// Create a semantic label for ratings
  static String ratingLabel(double rating, {int maxRating = 5}) {
    return '$rating out of $maxRating stars';
  }

  /// Create a semantic label for page numbers
  static String pageLabel(int currentPage, int totalPages) {
    return 'Page $currentPage of $totalPages';
  }

  /// Create a semantic label for download progress
  static String downloadProgressLabel(double progress) {
    final percentage = (progress * 100).round();
    return 'Download progress: $percentage percent';
  }

  /// Create a semantic label for content type
  static String contentTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'ebook':
        return 'E-book';
      case 'pdf':
        return 'PDF document';
      case 'comic':
        return 'Comic book';
      case 'magazine':
        return 'Magazine';
      case 'audiobook':
        return 'Audio book';
      default:
        return type;
    }
  }

  /// Announce a message to screen readers
  static void announce(BuildContext context, String message) {
    SemanticsService.announce(message, TextDirection.ltr);
  }

  /// Create a semantic button label
  static String buttonLabel(String action, {String? target}) {
    if (target != null) {
      return '$action $target';
    }
    return action;
  }
}

/// Mixin for widgets that need accessibility features
mixin AccessibilityMixin {
  /// Check if screen reader is enabled
  bool isScreenReaderEnabled(BuildContext context) {
    return MediaQuery.of(context).accessibleNavigation;
  }

  /// Check if bold text is enabled
  bool isBoldTextEnabled(BuildContext context) {
    return MediaQuery.of(context).boldText;
  }

  /// Get text scale factor
  double getTextScaleFactor(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor;
  }

  /// Check if reduce motion is enabled
  bool isReduceMotionEnabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
}

