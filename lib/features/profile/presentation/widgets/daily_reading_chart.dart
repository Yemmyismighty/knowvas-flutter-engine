import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Daily reading time chart widget
/// Displays a bar chart showing reading time for the last 7 days
class DailyReadingChart extends StatelessWidget {
  const DailyReadingChart({super.key});

  // Mock data - in a real implementation, this would come from the backend
  List<DailyReading> _getMockData() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final date = now.subtract(Duration(days: 6 - index));
      // Generate some mock reading time (0-120 minutes)
      final minutes = (math.Random().nextDouble() * 120).toInt();
      return DailyReading(
        date: date,
        minutes: minutes,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = _getMockData();
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CustomPaint(
                painter: BarChartPainter(
                  data: data,
                  barColor: theme.colorScheme.primary,
                  textColor: theme.colorScheme.onSurface,
                ),
                child: Container(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Reading time (minutes)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Data model for daily reading
class DailyReading {
  final DateTime date;
  final int minutes;

  DailyReading({
    required this.date,
    required this.minutes,
  });
}

/// Custom painter for bar chart
class BarChartPainter extends CustomPainter {
  final List<DailyReading> data;
  final Color barColor;
  final Color textColor;

  BarChartPainter({
    required this.data,
    required this.barColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxMinutes = data.map((e) => e.minutes).reduce(math.max);
    if (maxMinutes == 0) return;

    final barWidth = (size.width - 40) / data.length;
    final chartHeight = size.height - 40;

    // Draw bars
    for (var i = 0; i < data.length; i++) {
      final reading = data[i];
      final barHeight = (reading.minutes / maxMinutes) * chartHeight;
      final x = 20 + i * barWidth + barWidth * 0.2;
      final y = size.height - 20 - barHeight;

      // Draw bar
      final barPaint = Paint()
        ..color = barColor
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth * 0.6, barHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, barPaint);

      // Draw day label
      final textPainter = TextPainter(
        text: TextSpan(
          text: _getDayLabel(reading.date),
          style: TextStyle(
            color: textColor.withOpacity(0.6),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          x + (barWidth * 0.6 - textPainter.width) / 2,
          size.height - 15,
        ),
      );

      // Draw value on top of bar if there's space
      if (reading.minutes > 0) {
        final valuePainter = TextPainter(
          text: TextSpan(
            text: reading.minutes.toString(),
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        valuePainter.layout();
        valuePainter.paint(
          canvas,
          Offset(
            x + (barWidth * 0.6 - valuePainter.width) / 2,
            y - 15,
          ),
        );
      }
    }
  }

  String _getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yest';
    } else {
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      return days[date.weekday % 7];
    }
  }

  @override
  bool shouldRepaint(BarChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.barColor != barColor ||
        oldDelegate.textColor != textColor;
  }
}
