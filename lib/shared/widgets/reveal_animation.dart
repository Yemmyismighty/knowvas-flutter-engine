import 'package:flutter/material.dart';

/// Screen-entry animation: fades in + slides up once on mount.
/// Uses FadeTransition + SlideTransition (GPU-composited, no layout rebuilds).
/// The animation plays exactly once and never re-triggers on scroll or rebuild.
class RevealAnimation extends StatefulWidget {
  const RevealAnimation({
    required this.child,
    this.duration = const Duration(milliseconds: 450),
    this.delay = Duration.zero,
    this.slideOffset = 0.03,
    super.key,
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final double slideOffset;

  @override
  State<RevealAnimation> createState() => _RevealAnimationState();
}

class _RevealAnimationState extends State<RevealAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Staggered version - each child animates in sequence.
class StaggeredRevealAnimation extends StatelessWidget {
  const StaggeredRevealAnimation({
    required this.children,
    this.staggerDelay = const Duration(milliseconds: 80),
    this.initialDelay = Duration.zero,
    super.key,
  });

  final List<Widget> children;
  final Duration staggerDelay;
  final Duration initialDelay;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < children.length; i++)
          RevealAnimation(
            delay: initialDelay + staggerDelay * i,
            child: children[i],
          ),
      ],
    );
  }
}
