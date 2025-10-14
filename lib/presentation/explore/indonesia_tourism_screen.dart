import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/indonesia_tourism_provider.dart';
import '../../core/models/indonesia_tourism_models.dart';
import '../../core/models/destination_model.dart';
import '../destinations/destination_detail_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Screen for exploring Indonesian tourism destinations
class IndonesiaTourismScreen extends StatefulWidget {
  const IndonesiaTourismScreen({super.key});

  @override
  State<IndonesiaTourismScreen> createState() => _IndonesiaTourismScreenState();
}

class _IndonesiaTourismScreenState extends State<IndonesiaTourismScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IndonesiaTourismProvider>().loadTrendingDestinations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🇮🇩 Wisata Indonesia'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari destinasi wisata...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<IndonesiaTourismProvider>().clearFilters();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  context.read<IndonesiaTourismProvider>().searchByKeyword(value);
                }
              },
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Province filter chips
          _buildProvinceFilter(),

          // Category filter chips
          _buildCategoryFilter(),

          // Destinations list
          Expanded(
            child: Consumer<IndonesiaTourismProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(provider.error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.reload(),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final destinations = provider.destinations.isNotEmpty
                    ? provider.destinations
                    : provider.trendingDestinations;

                if (destinations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.explore_off, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('Tidak ada destinasi ditemukan'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.loadTrendingDestinations(),
                          child: const Text('Muat Trending'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.reload(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      return _buildDestinationCard(destinations[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceFilter() {
    return Consumer<IndonesiaTourismProvider>(
      builder: (context, provider, child) {
        return SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildFilterChip(
                label: 'Semua',
                selected: provider.selectedProvince == null,
                onTap: () {
                  provider.clearFilters();
                  provider.loadTrendingDestinations();
                },
              ),
              ...IndonesianProvince.allProvinces.map((province) {
                return _buildFilterChip(
                  label: province.name,
                  selected: provider.selectedProvince == province,
                  onTap: () => provider.searchByProvince(province),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryFilter() {
    return Consumer<IndonesiaTourismProvider>(
      builder: (context, provider, child) {
        return SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildFilterChip(
                label: '🌴 Semua Kategori',
                selected: provider.selectedCategory == null,
                onTap: () {
                  if (provider.selectedProvince != null) {
                    provider.searchByProvince(provider.selectedProvince!);
                  } else {
                    provider.loadTrendingDestinations();
                  }
                },
              ),
              ...TourismCategory.allCategories.map((category) {
                return _buildFilterChip(
                  label: '${_getCategoryIcon(category)} ${category.name}',
                  selected: provider.selectedCategory == category,
                  onTap: () => provider.searchByCategory(category),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildDestinationCard(Destination destination) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DestinationDetailScreen(
                title: destination.name,
                location: destination.location,
                guides: destination.description,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: destination.images.isNotEmpty
                      ? destination.images.first
                      : 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?w=800',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 64),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          destination.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    destination.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          destination.location,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    destination.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),

                  // Tags/Facilities
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: destination.facilities.take(3).map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryIcon(TourismCategory category) {
    switch (category.id) {
      case 'wisata-pantai':
        return '🏖️';
      case 'wisata-gunung':
        return '⛰️';
      case 'wisata-budaya':
        return '🎭';
      case 'wisata-kuliner':
        return '🍜';
      case 'wisata-alam':
        return '🌿';
      case 'wisata-religi':
        return '🕌';
      case 'eco-tourism':
        return '🌱';
      case 'wisata-modern':
        return '🏙️';
      default:
        return '📍';
    }
  }
}
