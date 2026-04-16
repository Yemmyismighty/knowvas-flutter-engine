import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../widgets/daily_reading_chart.dart';
import '../widgets/genre_distribution_chart.dart';
import '../widgets/monthly_progress_chart.dart';
import '../widgets/stats_card.dart';

/// Reading stats dashboard screen
/// Displays comprehensive reading statistics including:
/// - Total books read, reading time, current streak
/// - Favorite genre
/// - Daily reading time chart
/// - Genre distribution chart
/// - Monthly progress chart
class ReadingStatsScreen extends ConsumerWidget {
  const ReadingStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reading Stats'),
        ),
        body: const Center(
          child: Text('Please sign in to view your reading stats'),
        ),
      );
    }

    final stats = user.stats;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading Stats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Refresh stats by re-fetching user data
              // This would typically call a refresh method on the auth provider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Stats refreshed'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Refresh stats',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh user data
          // In a real implementation, this would call the backend
          await Future.delayed(const Duration(seconds: 1));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overview Stats Cards
              Text(
                'Overview',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildOverviewCards(context, stats),
              const SizedBox(height: 32),

              // Favorite Genre
              if (stats.favoriteGenre != null) ...[
                Text(
                  'Favorite Genre',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFavoriteGenreCard(context, stats.favoriteGenre!),
                const SizedBox(height: 32),
              ],

              // Daily Reading Time Chart
              Text(
                'Daily Reading Time',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Last 7 days',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const DailyReadingChart(),
              const SizedBox(height: 32),

              // Genre Distribution Chart
              Text(
                'Genre Distribution',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your reading preferences',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const GenreDistributionChart(),
              const SizedBox(height: 32),

              // Monthly Progress Chart
              Text(
                'Monthly Progress',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Books completed per month',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const MonthlyProgressChart(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, stats) {
    final readingTimeHours = (stats.totalReadingTimeMinutes / 60).floor();
    final readingTimeMinutes = stats.totalReadingTimeMinutes % 60;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatsCard(
                icon: Icons.book,
                iconColor: Colors.blue,
                title: 'Books Read',
                value: stats.booksRead.toString(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                icon: Icons.access_time,
                iconColor: Colors.orange,
                title: 'Reading Time',
                value: readingTimeHours > 0
                    ? '${readingTimeHours}h ${readingTimeMinutes}m'
                    : '${readingTimeMinutes}m',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: StatsCard(
                icon: Icons.local_fire_department,
                iconColor: Colors.red,
                title: 'Current Streak',
                value: '${stats.currentStreak} days',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: StatsCard(
                icon: Icons.auto_stories,
                iconColor: Colors.green,
                title: 'Pages Read',
                value: NumberFormat('#,###').format(stats.pagesRead),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFavoriteGenreCard(BuildContext context, String genre) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.purple,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    genre,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your most read genre',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
