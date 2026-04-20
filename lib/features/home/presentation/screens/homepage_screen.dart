import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/feed.dart';
import '../../../../shared/widgets/content_carousel.dart';
import '../../../../shared/widgets/knowvas_loading_spinner.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/homepage_provider.dart';
import '../providers/homepage_state.dart';

class HomepageScreen extends ConsumerWidget {
  const HomepageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homepageProvider);
    final user = ref.watch(authProvider.select((s) => s.user));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/logo.png', width: 32, height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [AppTheme.brand600, AppTheme.brand800]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.menu_book, color: Colors.white, size: 20),
                  )),
            ),
            const SizedBox(width: 8),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.brand600, AppTheme.brand800],
              ).createShader(bounds),
              child: const Text('Knowvas',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/discover'),
          ),
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => context.push('/profile'),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.brand100,
                  backgroundImage: user.profilePicture != null
                      ? CachedNetworkImageProvider(user.profilePicture!)
                      : null,
                  child: user.profilePicture == null
                      ? Text(
                          (user.firstName.isNotEmpty
                                  ? user.firstName[0]
                                  : user.email[0])
                              .toUpperCase(),
                          style: const TextStyle(
                              color: AppTheme.brand700,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(homepageProvider.notifier).refresh(),
        color: AppTheme.brandPrimary,
        child: _buildBody(context, state, ref),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomepageState state, WidgetRef ref) {
    if (state.isLoading && state.feedResponse == null) {
      return const Center(child: KnowvasLoadingSpinner());
    }

    if (state.error != null && state.feedResponse == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Could not load feed',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(state.error!, textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(homepageProvider.notifier).fetchFeed(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    final feed = state.feedResponse?.feed ?? [];
    final isPersonalised = state.feedResponse?.isPersonalised ?? false;

    // Collect all non-continue_reading, non-creator_spotlight items for the featured card
    final allItems = feed
        .where((s) => s.type != 'continue_reading' && s.type != 'creator_spotlight' && s.type != 'stats_nudge')
        .expand((s) => s.items)
        .toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Hero heading
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.brand50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 14, color: AppTheme.brand700),
                      const SizedBox(width: 6),
                      Text(
                        isPersonalised
                            ? 'Your personalised feed'
                            : 'New releases this week',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.brand700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2),
                    children: [
                      TextSpan(text: 'Your Digital\nReading '),
                      TextSpan(
                        text: 'Sanctuary',
                        style: TextStyle(color: AppTheme.brand600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Featured Card — rotating every 10 minutes from feed items
        if (allItems.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _FeaturedCard(items: allItems),
            ),
          ),

        // Feed sections
        if (feed.isEmpty && !state.isLoading)
          const SliverFillRemaining(
            child: Center(child: Text('No content available')),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final section = feed[index];
                // Insert membership hook after the 3rd section
                if (index == 3) {
                  return Column(children: [
                    _buildSection(context, section),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: _MembershipHookCard(),
                    ),
                  ]);
                }
                return _buildSection(context, section);
              },
              childCount: feed.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 32)),
      ],
    );
  }

  Widget _buildSection(BuildContext context, FeedSection section) {
    switch (section.type) {
      case 'continue_reading':
        return _ContinueReadingSection(section: section);
      case 'creator_spotlight':
        return _CreatorSpotlightSection(section: section);
      case 'stats_nudge':
        return _StatsNudgeCard(section: section);
      default:
        if (section.items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ContentCarousel(
            title: section.title,
            contents: section.items.map((i) => i.toContent()).toList(),
            onViewAll: section.viewAllUrl != null
                ? () => _handleViewAll(context, section.viewAllUrl!)
                : null,
            onContentTap: (content) =>
                context.push('/content/${content.id}'),
          ),
        );
    }
  }

  void _handleViewAll(BuildContext context, String url) {
    // Parse the URL and route accordingly
    final uri = Uri.parse(url);
    if (url.startsWith('/library')) {
      final tab = uri.queryParameters['tab'];
      context.push(tab != null ? '/library?tab=$tab' : '/library');
    } else if (url.startsWith('/discover')) {
      final tab = uri.queryParameters['tab'];
      final genre = uri.queryParameters['genre'];
      final sort = uri.queryParameters['sort'];
      final type = uri.queryParameters['type'];
      final params = <String, String>{};
      if (tab != null) params['tab'] = tab;
      if (genre != null) params['genre'] = genre;
      if (sort != null) params['sort'] = sort;
      if (type != null) params['type'] = type;
      final query = params.isNotEmpty
          ? '?${params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}'
          : '';
      context.push('/discover$query');
    }
  }
}

// ---------------------------------------------------------------------------
// Featured Card — rotating every 10 minutes, mirrors web's FeaturedCard
// ---------------------------------------------------------------------------
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.items});
  final List<FeedItem> items;

  FeedItem _pickItem() {
    final quality = items.where((i) => i.rating > 0).toList();
    final pool = quality.isNotEmpty ? quality : items;
    final bucket = DateTime.now().millisecondsSinceEpoch ~/ (10 * 60 * 1000);
    return pool[bucket % pool.length];
  }

  String _priceLabel(FeedItem item) {
    if (item.isFree) return 'Free';
    if (item.isPremiumOnly) return 'Members Only';
    final ngn = item.price['NGN'] ?? item.price['USD'] ?? 0;
    if (ngn == 0) return 'Free';
    return '₦${ngn.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final item = _pickItem();
    return GestureDetector(
      onTap: () => context.push('/content/${item.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppTheme.brand600.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 110,
                height: 160,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 110,
                  height: 160,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.brand600, AppTheme.brand800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.menu_book, color: Colors.white, size: 40),
                ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.brand100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Featured',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.brand700)),
                    ),
                    const SizedBox(height: 8),
                    Text(item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                    const SizedBox(height: 4),
                    Text('by ${item.author}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                    if (item.rating > 0) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(item.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Text('(${item.reviewCount})',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500)),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 8),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppTheme.brand600, AppTheme.brand800],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text('Read Now',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.brand50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(_priceLabel(item),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.brand700)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Membership Hook Card — mirrors web's right-side subscription promo
// ---------------------------------------------------------------------------
class _MembershipHookCard extends StatelessWidget {
  const _MembershipHookCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.brand600, AppTheme.brand800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand600.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.workspace_premium_rounded,
                color: Colors.amber, size: 20),
            const SizedBox(width: 8),
            const Text('Knowvas Membership',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ]),
          const SizedBox(height: 10),
          ...[
            'Unlimited access to all books',
            'Read on up to 3 devices',
            'Exclusive member-only titles',
            'Ad-free reading experience',
          ].map((perk) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(children: [
                  const Icon(Icons.check_circle_rounded,
                      size: 14, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Text(perk,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ]),
              )),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => context.push('/pricing'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('View Plans',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: AppTheme.brand700,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Continue Reading Section
// ---------------------------------------------------------------------------
class _ContinueReadingSection extends StatelessWidget {
  const _ContinueReadingSection({required this.section});
  final FeedSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle_outline,
                  size: 20, color: AppTheme.brand600),
              const SizedBox(width: 8),
              Text(section.title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/library'),
                child: const Text('View All',
                    style: TextStyle(color: AppTheme.brand600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...section.items.map((item) => _ContinueReadingCard(item: item)),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.item});
  final FeedItem item;

  @override
  Widget build(BuildContext context) {
    final progress = item.progress ?? 0.0;
    return GestureDetector(
      onTap: () => context.push('/content/${item.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Cover
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item.imageUrl,
                width: 52,
                height: 72,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 52,
                  height: 72,
                  color: AppTheme.brand100,
                  child: const Icon(Icons.book, color: AppTheme.brand400),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(item.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress / 100,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppTheme.brand600),
                            minHeight: 5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${progress.round()}%',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Creator Spotlight Section
// ---------------------------------------------------------------------------
class _CreatorSpotlightSection extends StatelessWidget {
  const _CreatorSpotlightSection({required this.section});
  final FeedSection section;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.people_outline,
                    size: 20, color: AppTheme.brand600),
                const SizedBox(width: 8),
                Text(section.title,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: section.creators.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  _CreatorCard(creator: section.creators[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatorCard extends StatelessWidget {
  const _CreatorCard({required this.creator});
  final FeedCreator creator;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/creator/${creator.id}'),
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.brand100,
              backgroundImage: creator.profilePicture.isNotEmpty
                  ? CachedNetworkImageProvider(creator.profilePicture)
                  : null,
              child: creator.profilePicture.isEmpty
                  ? Text(
                      creator.name.isNotEmpty ? creator.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: AppTheme.brand700,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(creator.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 12)),
            const SizedBox(height: 2),
            Text('${creator.contentCount} works',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats Nudge Card
// ---------------------------------------------------------------------------
class _StatsNudgeCard extends StatelessWidget {
  const _StatsNudgeCard({required this.section});
  final FeedSection section;

  @override
  Widget build(BuildContext context) {
    final stats = section.stats;
    if (stats == null) return const SizedBox.shrink();

    final booksThisMonth = stats.booksThisMonth;
    final streakDays = stats.streakDays;

    String message;
    if (booksThisMonth >= 5) {
      message = "You're on fire this month!";
    } else if (booksThisMonth >= 2) {
      message = "Great reading momentum — keep it up!";
    } else {
      message = "Every page counts. Keep reading!";
    }

    String subMessage = streakDays >= 3
        ? "$streakDays days in a row — you're building a great habit."
        : "Read daily to build your streak.";

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.brand50, Color(0xFFF3E8FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.brand100),
        ),
        child: Row(
          children: [
            // Stats
            Row(
              children: [
                _StatBadge(
                  icon: Icons.menu_book_outlined,
                  value: '$booksThisMonth',
                  label: 'this month',
                  color: AppTheme.brand600,
                ),
                if (streakDays > 0) ...[
                  Container(
                    width: 1,
                    height: 40,
                    color: AppTheme.brand200,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  _StatBadge(
                    icon: Icons.local_fire_department_outlined,
                    value: '$streakDays',
                    label: 'day streak',
                    color: Colors.orange,
                  ),
                ],
              ],
            ),
            const SizedBox(width: 12),
            // Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(message,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(subMessage,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600)),
                ],
              ),
            ),
            // Library button
            GestureDetector(
              onTap: () => context.push('/library'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.brand600,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Library',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
          ],
        ),
        Text(label,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
      ],
    );
  }
}
