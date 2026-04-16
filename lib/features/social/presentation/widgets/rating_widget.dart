import 'package:flutter/material.dart';

/// Widget for displaying and selecting star ratings
class RatingWidget extends StatelessWidget {
  const RatingWidget({
    required this.rating,
    this.onRatingChanged,
    this.size = 24.0,
    this.color,
    this.unratedColor,
    this.allowHalfRating = false,
    this.isReadOnly = false,
    super.key,
  });

  /// Current rating value (0.0 to 5.0)
  final double rating;

  /// Callback when rating changes (null for read-only)
  final ValueChanged<double>? onRatingChanged;

  /// Size of each star
  final double size;

  /// Color for filled stars
  final Color? color;

  /// Color for unfilled stars
  final Color? unratedColor;

  /// Whether to allow half-star ratings
  final bool allowHalfRating;

  /// Whether the widget is read-only (no interaction)
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starColor = color ?? theme.colorScheme.primary;
    final emptyColor = unratedColor ?? theme.colorScheme.outline.withOpacity(0.3);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1.0;
        return GestureDetector(
          onTap: isReadOnly || onRatingChanged == null
              ? null
              : () => onRatingChanged!(starValue),
          child: Icon(
            _getStarIcon(starValue),
            size: size,
            color: _getStarColor(starValue, starColor, emptyColor),
          ),
        );
      }),
    );
  }

  IconData _getStarIcon(double starValue) {
    if (rating >= starValue) {
      return Icons.star;
    } else if (allowHalfRating && rating >= starValue - 0.5) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getStarColor(double starValue, Color filledColor, Color emptyColor) {
    if (rating >= starValue) {
      return filledColor;
    } else if (allowHalfRating && rating >= starValue - 0.5) {
      return filledColor;
    } else {
      return emptyColor;
    }
  }
}

/// Interactive rating widget with tap and drag support
class InteractiveRatingWidget extends StatefulWidget {
  const InteractiveRatingWidget({
    required this.initialRating,
    required this.onRatingChanged,
    this.size = 32.0,
    this.color,
    this.unratedColor,
    this.allowHalfRating = false,
    super.key,
  });

  /// Initial rating value (0.0 to 5.0)
  final double initialRating;

  /// Callback when rating changes
  final ValueChanged<double> onRatingChanged;

  /// Size of each star
  final double size;

  /// Color for filled stars
  final Color? color;

  /// Color for unfilled stars
  final Color? unratedColor;

  /// Whether to allow half-star ratings
  final bool allowHalfRating;

  @override
  State<InteractiveRatingWidget> createState() =>
      _InteractiveRatingWidgetState();
}

class _InteractiveRatingWidgetState extends State<InteractiveRatingWidget> {
  late double _currentRating;

  @override
  void initState() {
    super.initState();
    _currentRating = widget.initialRating;
  }

  void _updateRating(double newRating) {
    setState(() {
      _currentRating = newRating.clamp(0.0, 5.0);
    });
    widget.onRatingChanged(_currentRating);
  }

  void _handleTap(int starIndex) {
    _updateRating((starIndex + 1).toDouble());
  }

  void _handlePanUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPosition = box.globalToLocal(details.globalPosition);
    final starWidth = constraints.maxWidth / 5;
    final position = localPosition.dx / starWidth;

    double newRating;
    if (widget.allowHalfRating) {
      newRating = (position * 2).roundToDouble() / 2;
    } else {
      newRating = position.ceilToDouble();
    }

    _updateRating(newRating);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final starColor = widget.color ?? theme.colorScheme.primary;
    final emptyColor =
        widget.unratedColor ?? theme.colorScheme.outline.withOpacity(0.3);

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanUpdate: (details) => _handlePanUpdate(details, constraints),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              return GestureDetector(
                onTap: () => _handleTap(index),
                child: Icon(
                  _getStarIcon(starValue),
                  size: widget.size,
                  color: _getStarColor(starValue, starColor, emptyColor),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  IconData _getStarIcon(double starValue) {
    if (_currentRating >= starValue) {
      return Icons.star;
    } else if (widget.allowHalfRating && _currentRating >= starValue - 0.5) {
      return Icons.star_half;
    } else {
      return Icons.star_border;
    }
  }

  Color _getStarColor(double starValue, Color filledColor, Color emptyColor) {
    if (_currentRating >= starValue) {
      return filledColor;
    } else if (widget.allowHalfRating && _currentRating >= starValue - 0.5) {
      return filledColor;
    } else {
      return emptyColor;
    }
  }
}
