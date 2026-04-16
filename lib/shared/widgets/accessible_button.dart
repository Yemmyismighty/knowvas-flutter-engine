import 'package:flutter/material.dart';
import '../../core/utils/accessibility_utils.dart';

/// Accessible button widget with proper touch targets and semantic labels
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.tooltip,
    this.minSize = AccessibilityUtils.minTouchTargetSize,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final String? tooltip;
  final double minSize;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );

    // Ensure minimum touch target size
    button = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: button,
    );

    // Add semantic label if provided
    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: ExcludeSemantics(child: button),
      );
    }

    // Add tooltip if provided
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }
}

/// Accessible icon button with proper touch targets
class AccessibleIconButton extends StatelessWidget {
  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.semanticLabel,
    this.tooltip,
    this.minSize = AccessibilityUtils.minTouchTargetSize,
    this.color,
    this.iconSize,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? tooltip;
  final double minSize;
  final Color? color;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      icon: Icon(icon, size: iconSize),
      onPressed: onPressed,
      color: color,
      tooltip: tooltip ?? semanticLabel,
    );

    // Ensure minimum touch target size
    button = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: button,
    );

    // Add semantic label if provided
    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: ExcludeSemantics(child: button),
      );
    }

    return button;
  }
}

/// Accessible text button with proper touch targets
class AccessibleTextButton extends StatelessWidget {
  const AccessibleTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.tooltip,
    this.minSize = AccessibilityUtils.minTouchTargetSize,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final String? tooltip;
  final double minSize;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    Widget button = TextButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );

    // Ensure minimum touch target size
    button = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: button,
    );

    // Add semantic label if provided
    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: ExcludeSemantics(child: button),
      );
    }

    // Add tooltip if provided
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }
}

/// Accessible outlined button with proper touch targets
class AccessibleOutlinedButton extends StatelessWidget {
  const AccessibleOutlinedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.tooltip,
    this.minSize = AccessibilityUtils.minTouchTargetSize,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final String? tooltip;
  final double minSize;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    Widget button = OutlinedButton(
      onPressed: onPressed,
      style: style,
      child: child,
    );

    // Ensure minimum touch target size
    button = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: button,
    );

    // Add semantic label if provided
    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        enabled: onPressed != null,
        child: ExcludeSemantics(child: button),
      );
    }

    // Add tooltip if provided
    if (tooltip != null) {
      button = Tooltip(
        message: tooltip,
        child: button,
      );
    }

    return button;
  }
}

