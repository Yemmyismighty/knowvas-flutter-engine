import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../discover/presentation/widgets/content_card.dart';
import '../../data/repositories/author_repository.dart';
import '../providers/author_provider.dart';

/// Author profile screen displaying author information and published works
/// Shows bio, avatar, cover image, social links, follower count, and content grid
/// Provides follow/unfollow functionality
class AuthorProfileScreen extends ConsumerStatefulWidget {
  const AuthorProfileScreen({
    required this.authorId,
    super.key,
  });

  final int authorId;

  @override
  ConsumerState<AuthorProfileScreen> createState() => _AuthorProfileScreenState();
}

class _AuthorProfileScreenState extends ConsumerState<AuthorProfileScreen> {
  bool _isFollowLoading = false;

  @override
  Widget build(BuildContext context) {
    final authorProfileAsync = ref.watch(authorProfileProvider(widget.authorId));

    return Scaffold(
      body: authorProfileAsync.when(
        data: (authorProfile) => _buildContent(context, authorProfile),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => _buildError(context, error),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AuthorProfile authorProfile) {
    final author = authorProfile.author;
    final publishedWorks = authorProfile.publishedWorks;
    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // App bar with cover image
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Cover image
                if (author.coverImage != null && author.coverImage!.isNotEmpty)
                  Image.network(
                    author.coverImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.brand500,
                              AppTheme.brand700,
                            ],
                          ),
                        ),
                      );
                    },
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.brand500,
                          AppTheme.brand700,
                        ],
                      ),
                    ),
                  ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Author profile content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar and name section
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: author.avatar != null && author.avatar!.isNotEmpty
                          ? NetworkImage(author.avatar!)
                          : null,
                      child: author.avatar == null || author.avatar!.isEmpty
                          ? Text(
                              author.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    // Name and stats
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            author.name,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Stats row
                          Wrap(
                            spacing: 24,
                            runSpacing: 8,
                            children: [
                              _buildStatItem(
                                Icons.people,
                                '${author.followerCount}',
                                'Followers',
                              ),
                              _buildStatItem(
                                Icons.book,
                                '${author.publishedWorksCount}',
                                'Works',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Follow button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isFollowLoading ? null : () => _handleFollowToggle(author.id, author.isFollowedByCurrentUser),
                    icon: _isFollowLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            author.isFollowedByCurrentUser
                                ? Icons.person_remove
                                : Icons.person_add,
                          ),
                    label: Text(
                      author.isFollowedByCurrentUser ? 'Unfollow' : 'Follow',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: author.isFollowedByCurrentUser
                          ? Colors.grey[600]
                          : AppTheme.brandPrimary,
                    ),
                  ),
                ),

                // Bio section
                if (author.bio != null && author.bio!.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'About',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    author.bio!,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.6,
                    ),
                  ),
                ],

                // Social links section
                if (author.socialLinks.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Connect',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: author.socialLinks.entries.map((entry) {
                      return _buildSocialLinkButton(entry.key, entry.value);
                    }).toList(),
                  ),
                ],

                // Published works section
                if (publishedWorks.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Published Works',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          ),
        ),

        // Published works grid
        if (publishedWorks.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return ContentCard(
                    content: publishedWorks[index],
                    size: ContentCardSize.medium,
                  );
                },
                childCount: publishedWorks.length,
              ),
            ),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 24),
        ),
      ],
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialLinkButton(String platform, String url) {
    IconData icon;
    Color color;

    switch (platform.toLowerCase()) {
      case 'twitter':
      case 'x':
        icon = Icons.close; // X icon
        color = Colors.black;
        break;
      case 'facebook':
        icon = Icons.facebook;
        color = const Color(0xFF1877F2);
        break;
      case 'instagram':
        icon = Icons.camera_alt;
        color = const Color(0xFFE4405F);
        break;
      case 'linkedin':
        icon = Icons.business;
        color = const Color(0xFF0A66C2);
        break;
      case 'website':
        icon = Icons.language;
        color = AppTheme.brandPrimary;
        break;
      default:
        icon = Icons.link;
        color = Colors.grey;
    }

    return OutlinedButton.icon(
      onPressed: () => _launchUrl(url),
      icon: Icon(icon, size: 18),
      label: Text(platform.toUpperCase()),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load author profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleFollowToggle(int authorId, bool isCurrentlyFollowing) async {
    setState(() {
      _isFollowLoading = true;
    });

    try {
      final authorActions = ref.read(authorActionsProvider);
      
      if (isCurrentlyFollowing) {
        await authorActions.unfollowAuthor(authorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unfollowed successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await authorActions.followAuthor(authorId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Following successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isCurrentlyFollowing ? 'unfollow' : 'follow'}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    try {
      final url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $urlString'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid URL: $urlString'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
