import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/models/content.dart';
import '../../../../shared/widgets/content_carousel.dart';
import '../../../../shared/widgets/knowvas_loading_spinner.dart';
import '../providers/discover_provider.dart';
import '../providers/discover_state.dart';

/// Discover screen matching web app functionality
/// Features: Search with autocomplete, filters, tabs (Trending, New, Bestsellers, Free, Genres)
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  
  late TabController _tabController;
  String _selectedGenre = 'all';
  String _sortBy = 'newest';
  bool _showAutocomplete = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Listen to search changes for autocomplete
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.length >= 2) {
      ref.read(discoverProvider.notifier).fetchAutocomplete(query);
      setState(() => _showAutocomplete = true);
    } else {
      setState(() => _showAutocomplete = false);
    }
  }

  void _onFocusChanged() {
    if (!_searchFocusNode.hasFocus) {
      // Delay hiding to allow tap on autocomplete items
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          setState(() => _showAutocomplete = false);
        }
      });
    }
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    
    setState(() => _showAutocomplete = false);
    _searchFocusNode.unfocus();
    
    ref.read(discoverProvider.notifier).search(
      query: query,
      sortBy: _sortBy,
      genre: _selectedGenre != 'all' ? _selectedGenre : null,
    );
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() => _showAutocomplete = false);
    ref.read(discoverProvider.notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final discoverState = ref.watch(discoverProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // App Bar with Search
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.white.withOpacity(0.95),
            title: _buildSearchBar(discoverState),
            automaticallyImplyLeading: false,
          ),
        ],
        body: RefreshIndicator(
          onRefresh: () async {
            await ref.read(discoverProvider.notifier).refresh();
          },
          color: AppTheme.brandPrimary,
          child: _buildBody(context, discoverState),
        ),
      ),
    );
  }

  Widget _buildSearchBar(DiscoverState state) {
    return Column(
      children: [
        Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.search, color: Colors.grey[600], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: const InputDecoration(
                    hintText: 'Search books, authors, topics...',
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _performSearch(),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey[600], size: 20),
                  onPressed: _clearSearch,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        
        // Autocomplete Dropdown
        if (_showAutocomplete && state.autocompleteResults.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.autocompleteResults.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final result = state.autocompleteResults[index];
                return ListTile(
                  dense: true,
                  leading: result['image'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: result['image'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: Colors.grey[200],
                              width: 40,
                              height: 40,
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey[200],
                              width: 40,
                              height: 40,
                              child: const Icon(Icons.book, size: 20),
                            ),
                          ),
                        )
                      : null,
                  title: Text(
                    result['title'],
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    result['subtitle'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.brand100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      result['type'] == 'resource' ? 'Content' : 'Author',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.brand700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onTap: () {
                    setState(() => _showAutocomplete = false);
                    _searchFocusNode.unfocus();
                    
                    if (result['type'] == 'resource') {
                      context.push('/content/${result['id']}');
                    } else {
                      context.push('/creator/${result['id']}');
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, DiscoverState state) {
    // Error state
    if (state.error != null && state.discoverResponse == null) {
      return _buildErrorState(state.error!);
    }

    // Loading state (initial load)
    if (state.isLoading && state.discoverResponse == null) {
      return const Center(child: KnowvasLoadingSpinner(size: 80));
    }

    // Search results view
    if (state.searchResults != null) {
      return _buildSearchResults(state);
    }

    // Main discover content
    return _buildDiscoverContent(state);
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Something went wrong',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              ref.read(discoverProvider.notifier).fetchDiscoverContent();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(DiscoverState state) {
    final results = state.searchResults!;
    final authors = state.searchAuthors ?? [];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Search Results for "${_searchController.text}"',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton(
              onPressed: _clearSearch,
              child: const Text('Clear'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Content results
        if (results.isNotEmpty) ...[
          const Text(
            'Content',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ContentCarousel(
            title: 'Results',
            contents: results.whereType<Content>().toList(),
            onContentTap: (content) {
              context.push('/content/${content.id}');
            },
          ),
          const SizedBox(height: 24),
        ] else ...[
          _buildEmptyState(
            icon: Icons.search,
            title: 'No content found',
            subtitle: 'Try adjusting your search terms or filters',
          ),
          const SizedBox(height: 24),
        ],
        
        // Author results
        if (authors.isNotEmpty) ...[
          const Text(
            'Authors',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: authors.length,
            itemBuilder: (context, index) {
              final author = authors[index];
              return _buildAuthorCard(author);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAuthorCard(Map<String, dynamic> author) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/creator/${author['id']}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: author['profilePicture'] != null
                    ? CachedNetworkImageProvider(author['profilePicture'])
                    : null,
                child: author['profilePicture'] == null
                    ? const Icon(Icons.person, size: 32)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                author['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                author['bio'] ?? 'No bio available',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${author['resourceCount']} ${author['resourceCount'] == 1 ? 'work' : 'works'}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscoverContent(DiscoverState state) {
    final content = state.discoverResponse;
    if (content == null) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No content available',
        subtitle: 'Check back later for new content',
      );
    }

    return Column(
      children: [
        // Hero Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppTheme.brand50.withOpacity(0.3),
              ],
            ),
          ),
          child: Column(
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
                    Icon(Icons.auto_awesome, size: 16, color: AppTheme.brand700),
                    const SizedBox(width: 6),
                    Text(
                      'Discover your next favorite read',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.brand700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Explore the Universe of',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [AppTheme.brand600, AppTheme.brand800],
                ).createShader(bounds),
                child: Text(
                  'Digital Literature',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'From cutting-edge sci-fi to timeless philosophy,\ndiscover stories that will expand your mind',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        
        // Filter Bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white.withOpacity(0.8),
          child: Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Sort by',
                  value: _sortBy,
                  items: const {
                    'newest': 'Newest',
                    'oldest': 'Oldest',
                    'rating': 'Highest Rated',
                    'price_low': 'Price: Low to High',
                    'price_high': 'Price: High to Low',
                    'popularity': 'Most Popular',
                  },
                  onChanged: (value) {
                    setState(() => _sortBy = value!);
                    ref.read(discoverProvider.notifier).updateFilters(
                      sortBy: value,
                      genre: _selectedGenre != 'all' ? _selectedGenre : null,
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  label: 'Genre',
                  value: _selectedGenre,
                  items: {
                    'all': 'All Genres',
                    ...Map.fromEntries(
                      (state.categories ?? []).map(
                        (cat) => MapEntry(cat['name'], cat['name']),
                      ),
                    ),
                  },
                  onChanged: (value) {
                    setState(() => _selectedGenre = value!);
                    ref.read(discoverProvider.notifier).updateFilters(
                      sortBy: _sortBy,
                      genre: value != 'all' ? value : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Tabs
        Expanded(
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: AppTheme.brandPrimary,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: AppTheme.brandPrimary,
                tabs: const [
                  Tab(text: 'Trending'),
                  Tab(text: 'New'),
                  Tab(text: 'Bestsellers'),
                  Tab(text: 'Free'),
                  Tab(text: 'Genres'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent(content.trending, 'trending'),
                    _buildTabContent(content.newReleases, 'new'),
                    _buildTabContent(content.bestsellers, 'bestsellers'),
                    _buildTabContent(content.freeBooks, 'free'),
                    _buildGenresTab(state.categories ?? []),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              items: items.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(List<dynamic> contents, String tabName) {
    if (contents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No ${tabName} content found',
        subtitle: 'Try adjusting your filters or check back later',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ContentCarousel(
          title: '',
          contents: contents.whereType<Content>().toList(),
          onContentTap: (content) {
            context.push('/content/${content.id}');
          },
        ),
      ],
    );
  }

  Widget _buildGenresTab(List<Map<String, dynamic>> categories) {
    if (categories.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category_outlined,
        title: 'No genres available',
        subtitle: 'Check back later',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedGenre = category['name'];
                _tabController.animateTo(0); // Switch to Trending tab
              });
              ref.read(discoverProvider.notifier).updateFilters(
                sortBy: _sortBy,
                genre: category['name'],
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.brand500, AppTheme.brand600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('📚', style: TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category['count']} items',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

