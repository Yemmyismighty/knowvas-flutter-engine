import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Monthly progress chart widget
/// Displays a line chart showing books completed per month
class MonthlyProgressChart extends StatelessWidget {
  const MonthlyProgressChart({super.key});

  // Mock data - in a real implementation, this would come from the backend
  List<MonthlyProgress> _getMockData() {
    final now = DateTime.now();
    return List.generate(6, (index) {
      final month = DateTime(now.year, now.month - (5 - index), 1);
      // Generate some mock book counts (0-10 books per month)
      final books = (math.Random().nextDouble() * 10).toInt();
      return MonthlyProgress(
        month: month,
        booksCompleted: books,
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
                painter: LineChartPainter(
                  data: data,
                  lineColor: theme.colorScheme.primary,
                  textColor: theme.colorScheme.onSurface,
                  gridColor: theme.colorScheme.outlineVariant,
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
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Books completed',
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

/// Data model for monthly progress
class MonthlyProgress {
  final DateTime month;
  final int booksCompleted;

  MonthlyProgress({
    required this.month,
    required this.booksCompleted,
  });
}

/// Custom painter for line chart
class LineChartPainter extends CustomPainter {
  final List<MonthlyProgress> data;
  final Color lineColor;
  final Color textColor;
  final Color gridColor;

  LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxBooks = data.map((e) => e.booksCompleted).reduce(math.max);
    final chartHeight = size.height - 40;
    final chartWidth = size.width - 60;
    final leftMargin = 30.0;
    final bottomMargin = 30.0;

    // Draw grid lines
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    final gridSteps = 5;
    for (var i = 0; i <= gridSteps; i++) {
      final y = size.height - bottomMargin - (chartHeight / gridSteps * i);
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(leftMargin + chartWidth, y),
        gridPaint,
      );

      // Draw y-axis labels
      if (maxBooks > 0) {
        final value = (maxBooks / gridSteps * i).toInt();
        final textPainter = TextPainter(
          text: TextSpan(
            text: value.toString(),
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
            leftMargin - textPainter.width - 5,
            y - textPainter.height / 2,
          ),
        );
      }
    }

    if (maxBooks == 0) return;

    // Calculate points
    final points = <Offset>[];
    for (var i = 0; i < data.length; i++) {
      final progress = data[i];
      final x = leftMargin + (chartWidth / (data.length - 1)) * i;
      final y = size.height -
          bottomMargin -
          (progress.booksCompleted / maxBooks) * chartHeight;
      points.add(Offset(x, y));
    }

    // Draw line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points[0].dx, points[0].dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, linePaint);

    // Draw points and labels
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final progress = data[i];

      // Draw point
      final pointPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(point, 5, pointPaint);

      // Draw white border around point
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(point, 5, borderPaint);

      // Draw month label
      final textPainter = TextPainter(
        text: TextSpan(
          text: _getMonthLabel(progress.month),
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
          point.dx - textPainter.width / 2,
          size.height - bottomMargin + 5,
        ),
      );
    }
  }

  String _getMonthLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[date.month - 1];
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor;
  }
}
