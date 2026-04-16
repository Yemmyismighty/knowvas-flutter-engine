import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/knowvas_loading_spinner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../library/presentation/providers/library_provider.dart';
import '../providers/profile_data_provider.dart';
import '../widgets/reading_goal_card.dart';
import '../widgets/streak_cards.dart';
import '../widgets/achievement_card.dart';
import '../widgets/activity_item.dart';

/// Profile screen matching web app design
class ProfileScreenNew extends ConsumerStatefulWidget {
  const ProfileScreenNew({super.key});

  @override
  ConsumerState<ProfileScreenNew> createState() => _ProfileScreenNewState();
}

class _ProfileScreenNewState extends ConsumerState<ProfileScreenNew>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profileState = ref.watch(profileDataProvider);

    if (!authState.isAuthenticated) {
      return _buildUnauthenticatedState(context);
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.grey[50]!, Colors.white],
          ),
        ),
        child: profileState.isLoading && profileState.profileHeader == null
            ? const Center(child: KnowvasLoadingSpinner(size: 80))
            : RefreshIndicator(
                onRefresh: () => ref.read(profileDataProvider.notifier).refresh(),
                child: CustomScrollView(
                  slivers: [
                    _buildAppBar(context),
                    _buildCoverSection(context, profileState),
                    _buildTabBar(context),
                    _buildTabContent(context, profileState),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildUnauthenticatedState(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.white.withOpacity(0.95),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              const Text(
                'You need to login to view Profile information',
                style: TextStyle(fontSize: 18, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 48,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.brand600, AppTheme.brand700],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ElevatedButton(
                    onPressed: () => context.push('/auth/signin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Sign In', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      pinned: true,
      backgroundColor: Colors.white.withOpacity(0.95),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
        onPressed: () => context.pop(),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: Colors.black87),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black87),
          onPressed: () => context.push('/settings'),
        ),
        IconButton(
          icon: const Icon(Icons.logout, color: Colors.red),
          onPressed: () => ref.read(authProvider.notifier).signOut(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCoverSection(BuildContext context, ProfileDataState profileState) {
    final header = profileState.profileHeader;
    if (header == null) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Cover Image
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.brand600, AppTheme.brand700, AppTheme.brand800],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: header.coverImage != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: header.coverImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          color: Colors.black.withOpacity(0.7),
                          colorBlendMode: BlendMode.darken,
                        ),
                      )
                    : null,
              ),
              // Reading Level Badge
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        header.readingLevel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Profile Info
          Transform.translate(
            offset: const Offset(0, -64),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Avatar
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.brandPrimary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: header.avatar != null
                              ? CachedNetworkImage(
                                  imageUrl: header.avatar!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [AppTheme.brand600, AppTheme.brand700],
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      header.name.isNotEmpty ? header.name[0].toUpperCase() : 'U',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Edit Profile Button
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: SizedBox(
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.brand600, AppTheme.brand700],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () => context.push('/profile/edit'),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Edit Profile'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // User Info Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          header.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          header.username,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.brand600,
                          ),
                        ),
                        if (header.bio != null && header.bio!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Text(
                            header.bio!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        // Stats Grid
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                '${header.totalBooksRead}',
                                'Books Read',
                                AppTheme.brand600,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                '${header.currentStreak}',
                                'Day Streak',
                                Colors.green[600]!,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                '${header.followers}',
                                'Followers',
                                Colors.purple[600]!,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                '${header.following}',
                                'Following',
                                Colors.blue[600]!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[100]?.withOpacity(0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            labelColor: AppTheme.brandPrimary,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            tabs: const [
              Tab(icon: Icon(Icons.bar_chart, size: 18), text: 'Overview'),
              Tab(icon: Icon(Icons.menu_book, size: 18), text: 'Reading'),
              Tab(icon: Icon(Icons.emoji_events, size: 18), text: 'Achievements'),
              Tab(icon: Icon(Icons.access_time, size: 18), text: 'Activity'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, ProfileDataState profileState) {
    return SliverFillRemaining(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, profileState),
          _buildReadingTab(context),
          _buildAchievementsTab(context, profileState),
          _buildActivityTab(context, profileState),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context, ProfileDataState profileState) {
    final header = profileState.profileHeader;
    final libraryState = ref.watch(libraryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Reading Goal Card
          ReadingGoalCard(
            readingGoal: profileState.readingGoal,
            isLoading: profileState.isGoalLoading,
            onCreateGoal: (targetBooks) {
              ref.read(profileDataProvider.notifier).createReadingGoal(targetBooks);
            },
          ),
          const SizedBox(height: 24),

          // Streak Cards
          StreakCards(
            currentStreak: header?.currentStreak ?? 0,
            longestStreak: header?.longestStreak ?? 0,
          ),
          const SizedBox(height: 24),

          // Favorite Genres
          if (header != null && header.favoriteGenres.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Favorite Genres',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: header.favoriteGenres.map((genre) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.brand100, AppTheme.brand200],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          genre,
                          style: const TextStyle(
                            color: AppTheme.brand700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Currently Reading Preview
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Currently Reading',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.push('/library'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (libraryState.currentlyReading.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No books currently reading',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...libraryState.currentlyReading.take(2).map((book) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 64,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.grey[200],
                              ),
                              child: book.cover != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: book.cover!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(Icons.book),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    book.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'by ${book.author}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: book.progress / 100,
                                          backgroundColor: Colors.grey[200],
                                          valueColor: const AlwaysStoppedAnimation(AppTheme.brand600),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${book.progress.toInt()}%',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats
          if (profileState.quickStats != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickStatRow('Contents this month', '${profileState.quickStats!.contentsThisMonth}', AppTheme.brand600),
                  _buildQuickStatRow('Average rating given', '${profileState.quickStats!.averageRating.toStringAsFixed(1)} ⭐', Colors.amber[700]!),
                  _buildQuickStatRow('Total reading time', profileState.quickStats!.totalReadingTime, Colors.green[600]!),
                  _buildQuickStatRow('Purchases', '${profileState.quickStats!.purchases}', Colors.purple[600]!, isLast: true),
                ],
              ),
            ),
          const SizedBox(height: 24),

          // Account Info
          if (header != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAccountInfoRow('Member since', header.joinDate),
                  _buildAccountInfoRow('Profile visibility', header.publicProfile ? 'Public' : 'Private'),
                  _buildAccountInfoRow('Email verified', header.emailVerified ? 'Yes' : 'Pending', isLast: true),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickStatRow(String label, String value, Color color, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingTab(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: libraryState.currentlyReading.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.menu_book, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No books currently reading', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.6,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: libraryState.currentlyReading.length,
              itemBuilder: (context, index) {
                final book = libraryState.currentlyReading[index];
                return GestureDetector(
                  onTap: () => context.push('/content/${book.id}'),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: book.cover != null
                                ? CachedNetworkImage(
                                    imageUrl: book.cover!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.book, size: 40),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.title,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAchievementsTab(BuildContext context, ProfileDataState profileState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: profileState.achievements.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Column(
                  children: [
                    Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No achievements yet', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: profileState.achievements.length,
              itemBuilder: (context, index) {
                return AchievementCard(achievement: profileState.achievements[index]);
              },
            ),
    );
  }

  Widget _buildActivityTab(BuildContext context, ProfileDataState profileState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            if (profileState.activity.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No recent activity', style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...profileState.activity.map((activity) {
                return ActivityItem(activity: activity);
              }),
          ],
        ),
      ),
    );
  }
}
