import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

/// Custom animated loading spinner for Knowvas brand
/// Features animated book pages flipping with brand colors
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
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.brandPrimary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: Listenable.merge([_rotationAnimation, _scaleAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: CustomPaint(
              painter: _BookPagesPainter(
                rotation: _rotationAnimation.value,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookPagesPainter extends CustomPainter {
  final double rotation;
  final Color color;

  _BookPagesPainter({
    required this.rotation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 3 rotating book pages
    for (int i = 0; i < 3; i++) {
      final angle = rotation + (i * 2 * math.pi / 3);
      
      // Calculate page position
      final pageOffset = Offset(
        center.dx + math.cos(angle) * radius * 0.4,
        center.dy + math.sin(angle) * radius * 0.4,
      );

      // Page gradient colors
      final gradientColors = [
        AppTheme.brand400,
        AppTheme.brand600,
        AppTheme.brand800,
      ];

      // Draw page with gradient
      final pagePaint = Paint()
        ..shader = LinearGradient(
          colors: [
            gradientColors[i].withOpacity(0.8),
            gradientColors[(i + 1) % 3].withOpacity(0.9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Rect.fromCircle(center: pageOffset, radius: radius * 0.3));

      // Draw rounded rectangle (book page)
      final pageRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: pageOffset,
          width: radius * 0.5,
          height: radius * 0.7,
        ),
        const Radius.circular(4),
      );

      canvas.save();
      canvas.translate(pageOffset.dx, pageOffset.dy);
      canvas.rotate(angle + math.pi / 2);
      canvas.translate(-pageOffset.dx, -pageOffset.dy);
      canvas.drawRRect(pageRect, pagePaint);
      canvas.restore();
    }

    // Draw center circle (book spine)
    final centerPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.brand500,
          AppTheme.brand700,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.2));

    canvas.drawCircle(center, radius * 0.15, centerPaint);
  }

  @override
  bool shouldRepaint(_BookPagesPainter oldDelegate) {
    return oldDelegate.rotation != rotation || oldDelegate.color != color;
  }
}

/// Alternative spinner design - Pulsing knowledge dots
class KnowvasPulseSpinner extends StatefulWidget {
  final double size;
  final Color? color;

  const KnowvasPulseSpinner({
    super.key,
    this.size = 60.0,
    this.color,
  });

  @override
  State<KnowvasPulseSpinner> createState() => _KnowvasPulseSpinnerState();
}

class _KnowvasPulseSpinnerState extends State<KnowvasPulseSpinner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppTheme.brandPrimary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _PulseDotsPainter(
              progress: _controller.value,
              color: color,
            ),
          );
        },
      ),
    );
  }
}

class _PulseDotsPainter extends CustomPainter {
  final double progress;
  final Color color;

  _PulseDotsPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw 5 dots in a circle
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * math.pi / 5) - math.pi / 2;
      final dotProgress = (progress + (i * 0.2)) % 1.0;
      
      // Calculate dot position
      final dotOffset = Offset(
        center.dx + math.cos(angle) * radius * 0.6,
        center.dy + math.sin(angle) * radius * 0.6,
      );

      // Pulsing scale
      final scale = 0.5 + (math.sin(dotProgress * 2 * math.pi) * 0.5);
      final opacity = 0.3 + (scale * 0.7);

      // Gradient colors
      final gradientColors = [
        AppTheme.brand400,
        AppTheme.brand600,
        AppTheme.brand800,
      ];

      final dotPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            gradientColors[i % 3].withOpacity(opacity),
            gradientColors[(i + 1) % 3].withOpacity(opacity * 0.5),
          ],
        ).createShader(Rect.fromCircle(center: dotOffset, radius: radius * 0.15 * scale));

      canvas.drawCircle(dotOffset, radius * 0.12 * scale, dotPaint);
    }
  }

  @override
  bool shouldRepaint(_PulseDotsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Simple branded circular progress indicator
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
