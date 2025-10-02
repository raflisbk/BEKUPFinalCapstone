import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../destinations/destination_detail_screen.dart';
import '../guides/guide_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Destinations, Guides

  // Dummy data
  final List<Map<String, String>> _destinations = [
    {
      'title': 'Ubud Rice Terraces',
      'location': 'Bali, Indonesia',
      'guides': '12 guides available',
      'type': 'destination',
    },
    {
      'title': 'Mount Bromo',
      'location': 'East Java, Indonesia',
      'guides': '8 guides available',
      'type': 'destination',
    },
    {
      'title': 'Raja Ampat Islands',
      'location': 'West Papua, Indonesia',
      'guides': '5 guides available',
      'type': 'destination',
    },
    {
      'title': 'Borobudur Temple',
      'location': 'Central Java, Indonesia',
      'guides': '15 guides available',
      'type': 'destination',
    },
    {
      'title': 'Komodo Island',
      'location': 'East Nusa Tenggara, Indonesia',
      'guides': '6 guides available',
      'type': 'destination',
    },
  ];

  final List<Map<String, String>> _guides = [
    {
      'name': 'Made Wijaya',
      'expertise': 'Cultural & History Tours',
      'rating': '4.9',
      'price': 'Rp 500k/day',
      'type': 'guide',
    },
    {
      'name': 'Siti Rahayu',
      'expertise': 'Culinary Adventures',
      'rating': '4.8',
      'price': 'Rp 400k/day',
      'type': 'guide',
    },
    {
      'name': 'Budi Santoso',
      'expertise': 'Nature & Hiking',
      'rating': '4.7',
      'price': 'Rp 600k/day',
      'type': 'guide',
    },
    {
      'name': 'Dewi Lestari',
      'expertise': 'Photography Tours',
      'rating': '4.9',
      'price': 'Rp 550k/day',
      'type': 'guide',
    },
  ];

  List<Map<String, String>> get _filteredResults {
    List<Map<String, String>> allResults = [];

    if (_selectedFilter == 'All' || _selectedFilter == 'Destinations') {
      allResults.addAll(_destinations);
    }

    if (_selectedFilter == 'All' || _selectedFilter == 'Guides') {
      allResults.addAll(_guides);
    }

    if (_searchQuery.isEmpty) {
      return allResults;
    }

    return allResults.where((item) {
      final query = _searchQuery.toLowerCase();
      if (item['type'] == 'destination') {
        return item['title']!.toLowerCase().contains(query) ||
            item['location']!.toLowerCase().contains(query);
      } else {
        return item['name']!.toLowerCase().contains(query) ||
            item['expertise']!.toLowerCase().contains(query);
      }
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search',
          style: AppTextStyles.headlineSmall,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search destinations, guides...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.textTertiary,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: AppColors.textTertiary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 18,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filter Chips
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  delay: const Duration(milliseconds: 100),
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _selectedFilter == 'All',
                        onTap: () {
                          setState(() {
                            _selectedFilter = 'All';
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      _FilterChip(
                        label: 'Destinations',
                        isSelected: _selectedFilter == 'Destinations',
                        onTap: () {
                          setState(() {
                            _selectedFilter = 'Destinations';
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      _FilterChip(
                        label: 'Guides',
                        isSelected: _selectedFilter == 'Guides',
                        onTap: () {
                          setState(() {
                            _selectedFilter = 'Guides';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: _searchQuery.isEmpty
                ? _buildRecentSearches()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Searches',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 24),
          _RecentSearchItem(
            icon: Icons.history,
            text: 'Bali Rice Terraces',
            onTap: () {
              setState(() {
                _searchController.text = 'Bali Rice Terraces';
                _searchQuery = 'Bali Rice Terraces';
              });
            },
          ),
          _RecentSearchItem(
            icon: Icons.history,
            text: 'Cultural Tours',
            onTap: () {
              setState(() {
                _searchController.text = 'Cultural Tours';
                _searchQuery = 'Cultural Tours';
              });
            },
          ),
          _RecentSearchItem(
            icon: Icons.history,
            text: 'Mount Bromo',
            onTap: () {
              setState(() {
                _searchController.text = 'Mount Bromo';
                _searchQuery = 'Mount Bromo';
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _filteredResults;

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_outlined,
              size: 80,
              color: AppColors.grey400,
            ),
            const SizedBox(height: 24),
            Text(
              'No results found',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final item = results[index];
        return FadeInUp(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: index * 100),
          child: item['type'] == 'destination'
              ? _DestinationSearchResultCard(
                  title: item['title']!,
                  location: item['location']!,
                  guides: item['guides']!,
                )
              : _GuideSearchResultCard(
                  name: item['name']!,
                  expertise: item['expertise']!,
                  rating: item['rating']!,
                  price: item['price']!,
                ),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.black : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.white : AppColors.black,
          ),
        ),
      ),
    );
  }
}

class _RecentSearchItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _RecentSearchItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textTertiary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: AppTextStyles.bodyMedium,
              ),
            ),
            const Icon(
              Icons.arrow_outward,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationSearchResultCard extends StatelessWidget {
  final String title;
  final String location;
  final String guides;

  const _DestinationSearchResultCard({
    required this.title,
    required this.location,
    required this.guides,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DestinationDetailScreen(
                title: title,
                location: location,
                guides: guides,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.landscape_outlined,
                  color: AppColors.grey400,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          location,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideSearchResultCard extends StatelessWidget {
  final String name;
  final String expertise;
  final String rating;
  final String price;

  const _GuideSearchResultCard({
    required this.name,
    required this.expertise,
    required this.rating,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GuideDetailScreen(
                name: name,
                expertise: expertise,
                rating: rating,
                price: price,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.grey400,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: AppTextStyles.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.grey50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 12,
                                color: AppColors.black,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                rating,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.black,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      expertise,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
