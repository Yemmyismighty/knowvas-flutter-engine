import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/content.dart';
import '../../../../shared/models/search_filters.dart';
import '../../../../shared/widgets/knowvas_loading_spinner.dart';
import '../providers/search_provider.dart';
import '../widgets/content_card.dart';

/// Search screen with filters and sorting
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isGridView = true;

  // Filter state
  final List<String> _selectedGenres = [];
  final List<String> _selectedLanguages = [];
  final List<String> _selectedTypes = [];
  double? _minPrice;
  double? _maxPrice;
  double? _minRating;
  String _sortBy = 'relevance';

  // Available filter options
  final List<String> _availableGenres = [
    'Fiction',
    'Non-Fiction',
    'Mystery',
    'Romance',
    'Science Fiction',
    'Fantasy',
    'Biography',
    'History',
    'Self-Help',
    'Business',
  ];

  final List<String> _availableLanguages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Chinese',
    'Japanese',
  ];

  final List<String> _availableTypes = [
    'ebook',
    'pdf',
    'comic',
    'magazine',
    'audiobook',
  ];

  final Map<String, String> _sortOptions = {
    'relevance': 'Relevance',
    'newest': 'Newest',
    'price_asc': 'Price: Low to High',
    'price_desc': 'Price: High to Low',
    'rating': 'Rating',
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer (300ms debounce)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch();
    });
  }

  void _performSearch() {
    final filters = SearchFilters(
      query: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
      genres: _selectedGenres,
      languages: _selectedLanguages,
      types: _selectedTypes,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      sortBy: _sortBy,
    );

    ref.read(searchProvider.notifier).search(filters);
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        selectedGenres: _selectedGenres,
        selectedLanguages: _selectedLanguages,
        selectedTypes: _selectedTypes,
        availableGenres: _availableGenres,
        availableLanguages: _availableLanguages,
        availableTypes: _availableTypes,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        minRating: _minRating,
        onApply: (genres, languages, types, minPrice, maxPrice, minRating) {
          setState(() {
            _selectedGenres.clear();
            _selectedGenres.addAll(genres);
            _selectedLanguages.clear();
            _selectedLanguages.addAll(languages);
            _selectedTypes.clear();
            _selectedTypes.addAll(types);
            _minPrice = minPrice;
            _maxPrice = maxPrice;
            _minRating = minRating;
          });
          _performSearch();
        },
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedGenres.clear();
      _selectedLanguages.clear();
      _selectedTypes.clear();
      _minPrice = null;
      _maxPrice = null;
      _minRating = null;
    });
    _performSearch();
  }

  bool get _hasActiveFilters =>
      _selectedGenres.isNotEmpty ||
      _selectedLanguages.isNotEmpty ||
      _selectedTypes.isNotEmpty ||
      _minPrice != null ||
      _maxPrice != null ||
      _minRating != null;

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search books, authors...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips and sort
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Filter button
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_list, size: 16),
                        const SizedBox(width: 4),
                        const Text('Filters'),
                        if (_hasActiveFilters) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '${_selectedGenres.length + _selectedLanguages.length + _selectedTypes.length + (_minPrice != null ? 1 : 0) + (_maxPrice != null ? 1 : 0) + (_minRating != null ? 1 : 0)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    onSelected: (_) => _showFilterSheet(),
                  ),
                  const SizedBox(width: 8),
                  // Sort dropdown
                  DropdownButton<String>(
                    value: _sortBy,
                    items: _sortOptions.entries
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.key,
                            child: Text(e.value),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                        });
                        _performSearch();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  // Clear filters button
                  if (_hasActiveFilters)
                    TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear'),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Search results
          Expanded(
            child: _buildSearchResults(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    if (searchState.isLoading) {
      return const Center(
        child: KnowvasLoadingSpinner(size: 80),
      );
    }

    if (searchState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              searchState.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (searchState.response == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Search for books, authors, and more',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    final results = searchState.response!.results;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results count
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '${searchState.response!.totalCount} results found',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // Results grid/list
        Expanded(
          child: _isGridView
              ? _buildGridView(results)
              : _buildListView(results),
        ),
      ],
    );
  }

  Widget _buildGridView(List<Content> results) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ContentCard(
          content: results[index],
        );
      },
    );
  }

  Widget _buildListView(List<Content> results) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final content = results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                content.cover ?? '',
                width: 60,
                height: 90,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 90,
                    color: Colors.grey[300],
                    child: const Icon(Icons.book),
                  );
                },
              ),
            ),
            title: Text(
              content.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('by ${content.authorName}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text('${content.averageRating.toStringAsFixed(1)} (${content.ratingCount})'),
                  ],
                ),
              ],
            ),
            trailing: Text(
              content.isFree
                  ? 'Free'
                  : content.price?.isNotEmpty == true
                      ? '₦${content.price!['NGN']?.toStringAsFixed(0) ?? '0'}'
                      : 'N/A',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            onTap: () {
              // Navigation is handled by ContentCard
            },
          ),
        );
      },
    );
  }
}

/// Filter sheet widget
class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.selectedGenres,
    required this.selectedLanguages,
    required this.selectedTypes,
    required this.availableGenres,
    required this.availableLanguages,
    required this.availableTypes,
    required this.minPrice,
    required this.maxPrice,
    required this.minRating,
    required this.onApply,
  });

  final List<String> selectedGenres;
  final List<String> selectedLanguages;
  final List<String> selectedTypes;
  final List<String> availableGenres;
  final List<String> availableLanguages;
  final List<String> availableTypes;
  final double? minPrice;
  final double? maxPrice;
  final double? minRating;
  final void Function(
    List<String> genres,
    List<String> languages,
    List<String> types,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  ) onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late List<String> _genres;
  late List<String> _languages;
  late List<String> _types;
  late TextEditingController _minPriceController;
  late TextEditingController _maxPriceController;
  double? _rating;

  @override
  void initState() {
    super.initState();
    _genres = List.from(widget.selectedGenres);
    _languages = List.from(widget.selectedLanguages);
    _types = List.from(widget.selectedTypes);
    _minPriceController = TextEditingController(
      text: widget.minPrice?.toString() ?? '',
    );
    _maxPriceController = TextEditingController(
      text: widget.maxPrice?.toString() ?? '',
    );
    _rating = widget.minRating;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              // Filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Genres
                    const Text(
                      'Genres',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.availableGenres.map((genre) {
                        return FilterChip(
                          label: Text(genre),
                          selected: _genres.contains(genre),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _genres.add(genre);
                              } else {
                                _genres.remove(genre);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Languages
                    const Text(
                      'Languages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.availableLanguages.map((language) {
                        return FilterChip(
                          label: Text(language),
                          selected: _languages.contains(language),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _languages.add(language);
                              } else {
                                _languages.remove(language);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Types
                    const Text(
                      'Content Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: widget.availableTypes.map((type) {
                        return FilterChip(
                          label: Text(type.toUpperCase()),
                          selected: _types.contains(type),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _types.add(type);
                              } else {
                                _types.remove(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    // Price range
                    const Text(
                      'Price Range',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min Price',
                              border: OutlineInputBorder(),
                              prefixText: '₦',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _maxPriceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max Price',
                              border: OutlineInputBorder(),
                              prefixText: '₦',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Rating
                    const Text(
                      'Minimum Rating',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        final rating = index + 1.0;
                        return Expanded(
                          child: FilterChip(
                            label: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.star, size: 16),
                                Text(' $rating+'),
                              ],
                            ),
                            selected: _rating == rating,
                            onSelected: (selected) {
                              setState(() {
                                _rating = selected ? rating : null;
                              });
                            },
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
              // Apply button
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final minPrice = double.tryParse(_minPriceController.text);
                    final maxPrice = double.tryParse(_maxPriceController.text);
                    widget.onApply(
                      _genres,
                      _languages,
                      _types,
                      minPrice,
                      maxPrice,
                      _rating,
                    );
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
