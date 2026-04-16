import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/knowvas_loading_spinner.dart';
import '../../../../shared/models/library_item.dart';
import '../widgets/library_book_card.dart';
import '../providers/library_provider.dart';

/// Library screen matching React design
/// Shows user's books with reading progress, stats, and tabs
class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  bool _isGridView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(libraryProvider);
    
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white.withOpacity(0.95),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.brand600, AppTheme.brand800],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.menu_book, color: Colors.white, size: 24);
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [AppTheme.brand600, AppTheme.brand800],
              ).createShader(bounds),
              child: const Text(
                'My Library',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(libraryProvider.notifier).refresh();
        },
        child: libraryState.isLoading
            ? const Center(child: KnowvasLoadingSpinner(size: 80))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 32),

              // Error State
              if (libraryState.error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          libraryState.error!,
                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),

              // Reading Stats Cards
              _buildStatsCards(libraryState.stats),
              const SizedBox(height: 32),

              // Search and View Controls
              _buildSearchAndControls(),
              const SizedBox(height: 24),

              // Tabs
              _buildTabs(),
              const SizedBox(height: 24),

              // Tab Content
              _buildTabContent(libraryState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Library',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your personal collection of books and reading progress',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  Widget _buildStatsCards(ReadingStats stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          title: 'Currently Reading',
          value: '${stats.currentlyReadingCount}',
          icon: Icons.menu_book,
          gradient: const LinearGradient(
            colors: [AppTheme.brand500, AppTheme.brand600],
          ),
        ),
        _buildStatCard(
          title: 'Books Finished',
          value: '${stats.totalBooksRead}',
          icon: Icons.check_circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
        ),
        _buildStatCard(
          title: 'Reading Streak',
          value: '${stats.currentStreak} days',
          icon: Icons.local_fire_department,
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          ),
        ),
        _buildStatCard(
          title: 'This Month',
          value: '${stats.booksThisMonth}',
          icon: Icons.track_changes,
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndControls() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search your library...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.brand300, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.grid_view,
                  color: _isGridView ? AppTheme.brandPrimary : Colors.grey[600],
                ),
                onPressed: () => setState(() => _isGridView = true),
              ),
              IconButton(
                icon: Icon(
                  Icons.view_list,
                  color: !_isGridView ? AppTheme.brandPrimary : Colors.grey[600],
                ),
                onPressed: () => setState(() => _isGridView = false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
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
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.menu_book, size: 18),
            text: 'Reading',
          ),
          Tab(
            icon: Icon(Icons.shopping_bag, size: 18),
            text: 'Purchased',
          ),
          Tab(
            icon: Icon(Icons.access_time, size: 18),
            text: 'Recent',
          ),
          Tab(
            icon: Icon(Icons.check_circle, size: 18),
            text: 'Finished',
          ),
          Tab(
            icon: Icon(Icons.favorite, size: 18),
            text: 'Favorites',
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(LibraryState libraryState) {
    return SizedBox(
      height: 500,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildBooksGrid('currently-reading', libraryState),
          _buildBooksGrid('purchased', libraryState),
          _buildBooksGrid('recently-viewed', libraryState),
          _buildBooksGrid('finished', libraryState),
          _buildBooksGrid('favorites', libraryState),
        ],
      ),
    );
  }

  Widget _buildBooksGrid(String tab, LibraryState libraryState) {
    // Get books for the current tab
    List<LibraryItem> books;
    switch (tab) {
      case 'currently-reading':
        books = libraryState.currentlyReading;
        break;
      case 'purchased':
        books = libraryState.purchased;
        break;
      case 'recently-viewed':
        books = libraryState.recentlyViewed;
        break;
      case 'finished':
        books = libraryState.finished;
        break;
      case 'favorites':
        books = libraryState.favorites;
        break;
      default:
        books = [];
    }

    // Filter by search query
    final filteredBooks = libraryState.filterItems(books, _searchQuery);

    if (filteredBooks.isEmpty) {
      return _buildEmptyState(tab);
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _isGridView ? 3 : 1,
        childAspectRatio: _isGridView ? 0.6 : 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: filteredBooks.length,
      itemBuilder: (context, index) {
        final book = filteredBooks[index];
        return LibraryBookCard(
          id: book.id.toString(),
          title: book.title,
          author: book.author,
          imageUrl: book.cover ?? "",
          genre: book.categories.isNotEmpty ? book.categories.first : book.type,
          rating: book.rating,
          reviews: '${book.reviewCount}',
          readingProgress: book.progress,
          isFinished: book.isFinished,
          isFavorite: book.isFavorite,
          currentPage: book.currentPage,
          totalPages: book.totalPages,
          variant: tab,
          onTap: () {
            context.push('/content/${book.id}');
          },
          onFavoriteToggle: () {
            // TODO: Toggle favorite
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _getMockBooks(String tab) {
    // Mock data - will be replaced with actual data
    final currentlyReading = [
      {
        'id': '1',
        'title': 'The Quantum Garden',
        'author': 'Elena Rodriguez',
        'imageUrl': 'https://picsum.photos/seed/book1/300/400',
        'genre': 'Science Fiction',
        'rating': 4.9,
        'reviews': '2.1k',
        'readingProgress': 65.0,
        'currentPage': 156,
        'totalPages': 240,
        'isFavorite': true,
      },
      {
        'id': '2',
        'title': 'Digital Minimalism',
        'author': 'Cal Newport',
        'imageUrl': 'https://picsum.photos/seed/book2/300/400',
        'genre': 'Self-Help',
        'rating': 4.8,
        'reviews': '1.5k',
        'readingProgress': 23.0,
        'currentPage': 45,
        'totalPages': 195,
        'isFavorite': false,
      },
    ];

    final purchased = [
      {
        'id': '3',
        'title': 'The Creator Economy',
        'author': 'Sarah Chen',
        'imageUrl': 'https://picsum.photos/seed/book3/300/400',
        'genre': 'Business',
        'rating': 4.9,
        'reviews': '1.2k',
        'isFavorite': true,
      },
      {
        'id': '4',
        'title': 'Mindful Design',
        'author': 'Alex Rivera',
        'imageUrl': 'https://picsum.photos/seed/book4/300/400',
        'genre': 'Design',
        'rating': 4.7,
        'reviews': '987',
        'isFavorite': false,
      },
    ];

    final finished = [
      {
        'id': '5',
        'title': 'Atomic Habits',
        'author': 'James Clear',
        'imageUrl': 'https://picsum.photos/seed/book5/300/400',
        'genre': 'Self-Help',
        'rating': 4.8,
        'reviews': '3.2k',
        'readingProgress': 100.0,
        'isFinished': true,
        'isFavorite': true,
      },
    ];

    switch (tab) {
      case 'currently-reading':
        return currentlyReading;
      case 'purchased':
        return purchased;
      case 'finished':
        return finished;
      case 'favorites':
        return [...currentlyReading, ...purchased, ...finished]
            .where((book) => book['isFavorite'] == true)
            .toList();
      case 'recently-viewed':
        return purchased;
      default:
        return [];
    }
  }

  Widget _buildEmptyState(String tab) {
    final messages = {
      'currently-reading': 'Start reading a book to see it here.',
      'purchased': 'Purchase some books to build your library.',
      'recently-viewed': 'Books you\'ve recently viewed will appear here.',
      'finished': 'Completed books will be shown here.',
      'favorites': 'Mark books as favorites to see them here.',
    };

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTabIcon(tab),
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No books ${tab.replaceAll('-', ' ')} yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            messages[tab] ?? '',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/discover'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Discover Books'),
          ),
        ],
      ),
    );
  }

  IconData _getTabIcon(String tab) {
    switch (tab) {
      case 'currently-reading':
        return Icons.menu_book;
      case 'purchased':
        return Icons.shopping_bag;
      case 'recently-viewed':
        return Icons.access_time;
      case 'finished':
        return Icons.check_circle;
      case 'favorites':
        return Icons.favorite;
      default:
        return Icons.menu_book;
    }
  }
}

