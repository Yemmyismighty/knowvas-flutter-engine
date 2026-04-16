import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/tailwind_utils.dart';
import '../../../shared/widgets/content_card.dart';
import '../../../shared/widgets/main_navbar.dart';

/// Discover screen that exactly matches the React web version layout
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGenre = 'All';
  String _selectedType = 'All';
  
  // Mock data - replace with actual data from your API
  final List<Map<String, dynamic>> _mockContent = [
    {
      'id': 1,
      'title': 'The Great Gatsby',
      'type': 'book',
      'author_name': 'F. Scott Fitzgerald',
      'price': {'USD': 12.99, 'EUR': 11.99},
      'rating': 4.5,
      'reviews': '1,234',
      'genre': 'Classic Literature',
      'imageUrl': 'https://via.placeholder.com/192x256',
      'isFree': false,
      'premiumOnly': false,
      'isWishlisted': false,
      'badges': [
        {'text': 'Bestseller', 'variant': 'bestseller'},
      ],
    },
    // Add more mock data as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Exact background color matching React
      backgroundColor: const Color(0xFFFAFAFA), // bg-gray-50
      
      appBar: MainNavbar(
        currentRoute: '/discover',
        isAuthenticated: false, // Replace with actual auth state
        onSearchPressed: () {
          // Handle search
        },
        onCartPressed: () {
          // Handle cart
        },
        onSignInPressed: () {
          // Handle sign in
        },
        onSignUpPressed: () {
          // Handle sign up
        },
      ),
      
      body: SingleChildScrollView(
        child: Container(
          // max-w-7xl mx-auto px-6
          constraints: const BoxConstraints(maxWidth: 1280),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32), // py-8
              
              // Hero Section
              _buildHeroSection(),
              
              const SizedBox(height: 48), // space-y-12
              
              // Search and Filters
              _buildSearchAndFilters(),
              
              const SizedBox(height: 32), // space-y-8
              
              // Content Grid
              _buildContentGrid(),
              
              const SizedBox(height: 48), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24), // py-12 px-6
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.brand500,
            AppTheme.brand700,
          ],
        ),
        borderRadius: TailwindUtils.borderRadius('rounded-3xl'),
        boxShadow: TailwindUtils.shadow('shadow-brand-lg'),
      ),
      child: Column(
        children: [
          // Hero title - matching React typography
          Text(
            'Discover Your Next Great Read',
            style: TailwindUtils.textStyle(
              'text-3xl font-bold leading-tight',
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16), // space-y-4
          
          // Hero subtitle
          Text(
            'Explore thousands of books, audiobooks, and magazines',
            style: TailwindUtils.textStyle(
              'text-lg leading-relaxed',
              color: AppTheme.brand100,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32), // space-y-8
          
          // Search bar
          Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for books, authors, or topics...',
                hintStyle: TailwindUtils.textStyle('text-base', color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: TailwindUtils.borderRadius('rounded-xl'),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              style: TailwindUtils.textStyle('text-base'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title
        Text(
          'Browse Content',
          style: TailwindUtils.textStyle(
            'text-2xl font-bold',
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 16), // space-y-4
        
        // Filters row
        if (TailwindUtils.isDesktop(context))
          _buildDesktopFilters()
        else
          _buildMobileFilters(),
      ],
    );
  }

  Widget _buildDesktopFilters() {
    return Row(
      children: [
        // Genre filter
        _buildFilterDropdown(
          label: 'Genre',
          value: _selectedGenre,
          items: ['All', 'Fiction', 'Non-Fiction', 'Science', 'History'],
          onChanged: (value) => setState(() => _selectedGenre = value!),
        ),
        
        const SizedBox(width: 16), // space-x-4
        
        // Type filter
        _buildFilterDropdown(
          label: 'Type',
          value: _selectedType,
          items: ['All', 'Books', 'Audiobooks', 'Magazines', 'Comics'],
          onChanged: (value) => setState(() => _selectedType = value!),
        ),
        
        const Spacer(),
        
        // View toggle buttons
        Row(
          children: [
            IconButton(
              onPressed: () {
                // Switch to grid view
              },
              icon: const Icon(Icons.grid_view),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.brand100,
                foregroundColor: AppTheme.brand700,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                // Switch to list view
              },
              icon: const Icon(Icons.view_list),
              style: IconButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFilterDropdown(
                label: 'Genre',
                value: _selectedGenre,
                items: ['All', 'Fiction', 'Non-Fiction', 'Science', 'History'],
                onChanged: (value) => setState(() => _selectedGenre = value!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFilterDropdown(
                label: 'Type',
                value: _selectedType,
                items: ['All', 'Books', 'Audiobooks', 'Magazines', 'Comics'],
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // View toggle for mobile
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                // Switch to grid view
              },
              icon: const Icon(Icons.grid_view),
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.brand100,
                foregroundColor: AppTheme.brand700,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                // Switch to list view
              },
              icon: const Icon(Icons.view_list),
              style: IconButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: TailwindUtils.borderRadius('rounded-lg'),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: TailwindUtils.shadow('shadow-sm'),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          style: TailwindUtils.textStyle('text-sm font-medium'),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Text(item),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildContentGrid() {
    // Responsive grid matching React layout
    final crossAxisCount = TailwindUtils.isDesktop(context) 
        ? 6  // 6 columns on desktop
        : TailwindUtils.isTablet(context) 
            ? 4  // 4 columns on tablet
            : 2; // 2 columns on mobile

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75, // Matches card proportions
        crossAxisSpacing: 16, // gap-4
        mainAxisSpacing: 24,   // gap-6
      ),
      itemCount: _mockContent.length,
      itemBuilder: (context, index) {
        final content = _mockContent[index];
        
        return ContentCard(
          id: content['id'],
          title: content['title'],
          type: content['type'],
          authorName: content['author_name'],
          price: content['price'],
          rating: content['rating'],
          reviews: content['reviews'],
          genre: content['genre'],
          imageUrl: content['imageUrl'],
          isFree: content['isFree'],
          premiumOnly: content['premiumOnly'],
          isWishlisted: content['isWishlisted'],
          badges: (content['badges'] as List<Map<String, dynamic>>?)
              ?.map((badge) => ContentBadge(
                    text: badge['text'],
                    variant: _getBadgeVariant(badge['variant']),
                  ))
              .toList() ?? [],
          size: TailwindUtils.isMobile(context) 
              ? ContentCardSize.small 
              : ContentCardSize.medium,
          onTap: () {
            // Navigate to content details
          },
          onAddToCart: () {
            // Add to cart
          },
          onWishlistToggle: () {
            // Toggle wishlist
            setState(() {
              content['isWishlisted'] = !content['isWishlisted'];
            });
          },
        );
      },
    );
  }

  BadgeVariant _getBadgeVariant(String variant) {
    switch (variant) {
      case 'bestseller':
        return BadgeVariant.bestseller;
      case 'featured':
        return BadgeVariant.featured;
      case 'new':
        return BadgeVariant.newBadge;
      case 'trending':
        return BadgeVariant.trending;
      default:
        return BadgeVariant.featured;
    }
  }
}