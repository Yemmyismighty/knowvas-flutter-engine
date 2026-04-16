import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Genre distribution chart widget
/// Displays a pie chart showing the distribution of genres read
class GenreDistributionChart extends StatelessWidget {
  const GenreDistributionChart({super.key});

  // Mock data - in a real implementation, this would come from the backend
  List<GenreData> _getMockData() {
    return [
      GenreData(genre: 'Fiction', count: 15, color: Colors.blue),
      GenreData(genre: 'Science', count: 8, color: Colors.green),
      GenreData(genre: 'History', count: 6, color: Colors.orange),
      GenreData(genre: 'Biography', count: 5, color: Colors.purple),
      GenreData(genre: 'Other', count: 4, color: Colors.grey),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final data = _getMockData();
    final total = data.fold<int>(0, (sum, item) => sum + item.count);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // Pie chart
                  Expanded(
                    flex: 2,
                    child: CustomPaint(
                      painter: PieChartPainter(data: data),
                      child: Container(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Legend
                  Expanded(
                    flex: 3,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.map((item) {
                        final percentage = (item.count / total * 100).toStringAsFixed(1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.genre,
                                  style: theme.textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '$percentage%',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total: $total books',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data model for genre distribution
class GenreData {
  final String genre;
  final int count;
  final Color color;

  GenreData({
    required this.genre,
    required this.count,
    required this.color,
  });
}

/// Custom painter for pie chart
class PieChartPainter extends CustomPainter {
  final List<GenreData> data;

  PieChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final total = data.fold<int>(0, (sum, item) => sum + item.count);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    double startAngle = -math.pi / 2; // Start from top

    for (var item in data) {
      final sweepAngle = (item.count / total) * 2 * math.pi;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      // Draw white border between segments
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle for donut effect
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.5, centerPaint);
  }

  @override
  bool shouldRepaint(PieChartPainter oldDelegate) {
    return oldDelegate.data != data;
  }
}
