import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Compact inline loading spinner — pulsing brand ring with bouncing dots.
/// Matches the web app's loading.tsx design.
/// Drop-in replacement for the old spinning-books widget.
class KnowvasLoadingSpinner extends StatefulWidget {
  final double size;
  final Color? color;

  const KnowvasLoadingSpinner({
    super.key,
    this.size = 60.0,
    this.color,
  });

  @override
  State<KnowvasLoadingSpinner> createState() => _KnowvasLoadingSpinnerState();
}

class _KnowvasLoadingSpinnerState extends State<KnowvasLoadingSpinner>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final List<AnimationController> _dotCtrls;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dotCtrls = List.generate(3, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) c.repeat(reverse: true);
      });
      return c;
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    for (final c in _dotCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.brandPrimary;
    final logoSize = widget.size * 0.55;
    final ringSize = widget.size;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo with pulse ring
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer ping ring
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, __) {
                  final scale = 1.0 + _pulseCtrl.value * 0.5;
                  final opacity = (1.0 - _pulseCtrl.value).clamp(0.0, 1.0);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: ringSize * 0.85,
                      height: ringSize * 0.85,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.2 * opacity),
                      ),
                    ),
                  );
                },
              ),
              // Inner static ring
              Container(
                width: ringSize * 0.68,
                height: ringSize * 0.68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                ),
              ),
              // Logo
              ClipOval(
                child: Image.asset(
                  'assets/logo.png',
                  width: logoSize,
                  height: logoSize,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.menu_book_rounded,
                    color: color,
                    size: logoSize * 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Three bouncing dots
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return AnimatedBuilder(
              animation: _dotCtrls[i],
              builder: (_, __) {
                final offset = -5.0 * _dotCtrls[i].value;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Transform.translate(
                    offset: Offset(0, offset),
                    child: Container(
                      width: widget.size * 0.09,
                      height: widget.size * 0.09,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

/// Alias kept for backward compatibility — same design as KnowvasLoadingSpinner.
class KnowvasPulseSpinner extends KnowvasLoadingSpinner {
  const KnowvasPulseSpinner({
    super.key,
    super.size,
    super.color,
  });
}

/// Simple branded circular progress indicator (unchanged).
class KnowvasCircularProgress extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const KnowvasCircularProgress({
    super.key,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppTheme.brandPrimary,
        ),
      ),
    );
  }
}
