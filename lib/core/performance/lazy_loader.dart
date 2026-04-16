import 'package:flutter/widgets.dart';

/// Lazy loading widget that defers rendering until visible
class LazyLoader extends StatefulWidget {
  final Widget child;
  final Widget? placeholder;
  final double threshold;

  const LazyLoader({
    super.key,
    required this.child,
    this.placeholder,
    this.threshold = 0.1,
  });

  @override
  State<LazyLoader> createState() => _LazyLoaderState();
}

class _LazyLoaderState extends State<LazyLoader> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: widget.key ?? UniqueKey(),
      onVisibilityChanged: (info) {
        if (info.visibleFraction >= widget.threshold && !_isVisible) {
          setState(() {
            _isVisible = true;
          });
        }
      },
      child: _isVisible
          ? widget.child
          : widget.placeholder ?? const SizedBox.shrink(),
    );
  }
}

/// Simple visibility detector
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final Function(VisibilityInfo) onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVisibility();
    });
  }

  void _checkVisibility() {
    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) {
      widget.onVisibilityChanged(VisibilityInfo(visibleFraction: 0.0));
      return;
    }

    // Simplified visibility check
    // In production, you'd want more sophisticated viewport detection
    widget.onVisibilityChanged(VisibilityInfo(visibleFraction: 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class VisibilityInfo {
  final double visibleFraction;

  VisibilityInfo({required this.visibleFraction});
}

/// Lazy list builder that only builds visible items
class LazyListBuilder extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  const LazyListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return LazyLoader(
          child: itemBuilder(context, index),
          placeholder: const SizedBox(height: 100), // Placeholder height
        );
      },
    );
  }
}

/// Lazy grid builder that only builds visible items
class LazyGridBuilder extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int crossAxisCount;
  final double childAspectRatio;
  final ScrollController? controller;
  final EdgeInsetsGeometry? padding;

  const LazyGridBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.childAspectRatio = 1.0,
    this.controller,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return LazyLoader(
          child: itemBuilder(context, index),
          placeholder: const SizedBox.shrink(),
        );
      },
    );
  }
}
