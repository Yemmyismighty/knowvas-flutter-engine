import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:knowvas/features/curated/presentation/providers/curated_provider.dart';
import 'package:knowvas/features/auth/presentation/providers/auth_provider.dart';
import 'package:knowvas/shared/models/curated_models.dart';
import 'package:knowvas/shared/widgets/wishlist_button.dart';

const Map<String, GenreConfig> GENRE_CONFIGS = {
  'fictional-books': GenreConfig(
    id: 'fictional-books',
    title: 'Fiction & Stories',
    description: 'Immerse yourself in captivating stories, from classic literature to contemporary fiction',
    color: '0xFF9333EA',
    apiEndpoint: 'fictional',
  ),
  'educational-resources': GenreConfig(
    id: 'educational-resources',
    title: 'Educational Resources',
    description: 'Learn and grow with comprehensive educational content across all subjects',
    color: '0xFF3B82F6',
    apiEndpoint: 'educational',
  ),
  'technology-innovation': GenreConfig(
    id: 'technology-innovation',
    title: 'Technology & Innovation',
    description: 'Stay ahead with cutting-edge tech, AI, and entrepreneurship content',
    color: '0xFF06B6D4',
    apiEndpoint: 'tech',
  ),
  'lifestyle-wellness': GenreConfig(
    id: 'lifestyle-wellness',
    title: 'Lifestyle & Wellness',
    description: 'Discover content on health, fitness, cooking, and personal development',
    color: '0xFF10B981',
    apiEndpoint: 'lifestyle',
  ),
  'spirituality-religion': GenreConfig(
    id: 'spirituality-religion',
    title: 'Spirituality & Religion',
    description: 'Explore diverse spiritual traditions and philosophical perspectives',
    color: '0xFFF59E0B',
    apiEndpoint: 'religion',
  ),
};

class CuratedGenreScreen extends ConsumerStatefulWidget {
  final String genreId;

  const CuratedGenreScreen({
    super.key,
    required this.genreId,
  });

  @override
  ConsumerState<CuratedGenreScreen> createState() => _CuratedGenreScreenState();
}

class _CuratedGenreScreenState extends ConsumerState<CuratedGenreScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  
  String _searchQuery = '';
  String _sortBy = 'newest';
  String _priceFilter = 'all';
  String _ratingFilter = 'all';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final genreConfig = GENRE_CONFIGS[widget.genreId];
      if (genreConfig != null) {
        ref.read(curatedProvider.notifier).loadContent(genreConfig.apiEndpoint);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(curatedProvider.notifier).loadMore();
    }
  }

  List<CuratedContent> _getFilteredContents(List<CuratedContent> contents) {
    var filtered = contents;

    // Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) =>
        item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        item.authorName.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    // Price filter
    if (_priceFilter == 'free') {
      filtered = filtered.where((item) => item.isFree).toList();
    } else if (_priceFilter == 'premium') {
      filtered = filtered.where((item) => !item.isFree).toList();
    }

    // Rating filter
    if (_ratingFilter == '3plus') {
      filtered = filtered.where((item) => item.averageRating >= 3).toList();
    } else if (_ratingFilter == '4plus') {
      filtered = filtered.where((item) => item.averageRating >= 4).toList();
    }

    // Sort
    if (_sortBy == 'popular') {
      filtered.sort((a, b) => int.parse(b.reviews).compareTo(int.parse(a.reviews)));
    } else if (_sortBy == 'rated') {
      filtered.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final genreConfig = GENRE_CONFIGS[widget.genreId];
    
    if (genreConfig == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Genre not found'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final curatedState = ref.watch(curatedProvider);
    final filteredContents = _getFilteredContents(curatedState.contents);
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF9FAFB), Colors.white],
          ),
        ),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(int.parse(genreConfig.color)),
                        Color(int.parse(genreConfig.color)).withOpacity(0.8),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            genreConfig.title,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            genreConfig.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Search and Filters
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Search Bar
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by title or author...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (value) {
                              setState(() => _searchQuery = value);
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            setState(() => _showFilters = !_showFilters);
                          },
                          icon: const Icon(Icons.filter_list),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(16),
                          ),
                        ),
                      ],
                    ),

                    // Filter Panel
                    if (_showFilters) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sort By',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('Newest'),
                                  selected: _sortBy == 'newest',
                                  onSelected: (selected) {
                                    setState(() => _sortBy = 'newest');
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Most Popular'),
                                  selected: _sortBy == 'popular',
                                  onSelected: (selected) {
                                    setState(() => _sortBy = 'popular');
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Highest Rated'),
                                  selected: _sortBy == 'rated',
                                  onSelected: (selected) {
                                    setState(() => _sortBy = 'rated');
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Price',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('All'),
                                  selected: _priceFilter == 'all',
                                  onSelected: (selected) {
                                    setState(() => _priceFilter = 'all');
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Free Only'),
                                  selected: _priceFilter == 'free',
                                  onSelected: (selected) {
                                    setState(() => _priceFilter = 'free');
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('Premium Only'),
                                  selected: _priceFilter == 'premium',
                                  onSelected: (selected) {
                                    setState(() => _priceFilter = 'premium');
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Minimum Rating',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: const Text('All Ratings'),
                                  selected: _ratingFilter == 'all',
                                  onSelected: (selected) {
                                    setState(() => _ratingFilter = 'all');
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('3+ Stars'),
                                  selected: _ratingFilter == '3plus',
                                  onSelected: (selected) {
                                    setState(() => _ratingFilter = '3plus');
                                  },
                                ),
                                ChoiceChip(
                                  label: const Text('4+ Stars'),
                                  selected: _ratingFilter == '4plus',
                                  onSelected: (selected) {
                                    setState(() => _ratingFilter = '4plus');
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _searchController.clear();
                                      _sortBy = 'newest';
                                      _priceFilter = 'all';
                                      _ratingFilter = 'all';
                                    });
                                  },
                                  child: const Text('Reset'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() => _showFilters = false);
                                  },
                                  child: const Text('Apply'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Results Count
            if (!curatedState.isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Showing ${filteredContents.length} results',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),

            // Content Grid
            if (curatedState.isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (filteredContents.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        'No content found',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Try adjusting your filters',
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final content = filteredContents[index];
                      final isWishlisted = authState.user != null &&
                          content.wishlists.any((w) => w.userId == int.parse(authState.user!.id));

                      return GestureDetector(
                        onTap: () => context.push('/content/${content.id}'),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Cover
                              Expanded(
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(12),
                                        ),
                                        color: Colors.grey[200],
                                      ),
                                      child: content.cover.isNotEmpty
                                          ? ClipRRect(
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                              child: CachedNetworkImage(
                                                imageUrl: content.cover,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              ),
                                            )
                                          : const Center(
                                              child: Icon(Icons.book, size: 48),
                                            ),
                                    ),
                                    if (content.isFree)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Free',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (content.premiumOnly)
                                      Positioned(
                                        top: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'Premium',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: WishlistButton(
                                        isWishlisted: isWishlisted,
                                        onToggle: () {
                                          if (authState.user != null) {
                                            ref.read(curatedProvider.notifier).updateWishlist(
                                              content.id,
                                              !isWishlisted,
                                              int.parse(authState.user!.id),
                                            );
                                          }
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Info
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      content.title,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      content.authorName,
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
                                        const Icon(Icons.star, size: 14, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(
                                          content.averageRating.toStringAsFixed(1),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '(${content.reviews})',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
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
                    },
                    childCount: filteredContents.length,
                  ),
                ),
              ),

            // Loading More Indicator
            if (curatedState.isLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

