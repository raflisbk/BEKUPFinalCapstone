import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/destination_model.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/destinations_list_ui_provider.dart';
import '../../services/destination_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/widgets/skeleton_loader.dart';
import 'destination_detail_screen.dart';

/// Destinations list screen with filtering and search
class DestinationsListScreen extends StatefulWidget {
  const DestinationsListScreen({super.key});

  @override
  State<DestinationsListScreen> createState() => _DestinationsListScreenState();
}

class _DestinationsListScreenState extends State<DestinationsListScreen> {
  final DestinationService _destinationService = DestinationService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String query, DestinationsListUIProvider listUIProvider) {
    listUIProvider.applySearch(query);
  }

  void _clearFilters(DestinationsListUIProvider listUIProvider) {
    listUIProvider.clearFilters();
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DestinationsListUIProvider>(
      builder: (context, authProvider, listUIProvider, child) {
        final isGuideOrAdmin = authProvider.user != null;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Destinations'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.black,
            elevation: 0,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.grey200),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  listUIProvider.showFilters
                      ? Icons.filter_list
                      : Icons.filter_list_outlined,
                  color: listUIProvider.filter.hasActiveFilters
                      ? AppColors.black
                      : AppColors.grey500,
                ),
                onPressed: () {
                  HapticHelper.lightImpact();
                  listUIProvider.toggleFilters();
                },
              ),
              if (isGuideOrAdmin)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    HapticHelper.buttonTap();
                    Navigator.pushNamed(context, '/add-edit-destination');
                  },
                ),
            ],
          ),
          body: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search destinations...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applySearch('', listUIProvider);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.grey300),
                    ),
                    filled: true,
                    fillColor: AppColors.grey50,
                  ),
                  onChanged: (query) => _applySearch(query, listUIProvider),
                ),
              ),

              // Filter panel
              if (listUIProvider.showFilters) _buildFilterPanel(listUIProvider),

              // Destinations list
              Expanded(
                child: StreamBuilder<List<Destination>>(
                  stream: _destinationService.getDestinationsStream(
                    filter: listUIProvider.filter,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoadingState();
                    }

                    if (snapshot.hasError) {
                      return _buildErrorState(snapshot.error.toString());
                    }

                    final destinations = snapshot.data ?? [];

                    if (destinations.isEmpty) {
                      return _buildEmptyState(listUIProvider);
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        await HapticHelper.lightImpact();
                        // Force rebuild by returning a completed future
                      },
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
      },
    );
  }

  Widget _buildFilterPanel(DestinationsListUIProvider listUIProvider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.grey50,
        border: Border(bottom: BorderSide(color: AppColors.grey200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (listUIProvider.filter.hasActiveFilters)
                TextButton(
                  onPressed: () => _clearFilters(listUIProvider),
                  child: const Text('Clear All'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Category filter
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DestinationCategory.values.map((category) {
              final isSelected =
                  listUIProvider.filter.category == category.name;
              return FilterChip(
                label: Text(category.displayName),
                avatar: Icon(category.icon, size: 16),
                selected: isSelected,
                onSelected: (selected) {
                  HapticHelper.selectionClick();
                  listUIProvider.setCategory(selected ? category.name : null);
                },
                selectedColor: AppColors.black.withValues(alpha: 0.1),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Sort options
          DropdownButtonFormField<DestinationSort>(
            value: listUIProvider.filter.sortBy,
            decoration: InputDecoration(
              labelText: 'Sort by',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            items: DestinationSort.values.map((sort) {
              return DropdownMenuItem(
                value: sort,
                child: Text(sort.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                listUIProvider.setSortBy(value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationCard(Destination destination) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          HapticHelper.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DestinationDetailScreen(
                title: destination.name,
                location: destination.location,
                guides: 'Guide information available',
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: destination.images.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: destination.images.first,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: AppColors.grey100,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 200,
                        color: AppColors.grey200,
                        child: const Icon(Icons.image_not_supported, size: 48),
                      ),
                    )
                  : Container(
                      height: 200,
                      color: AppColors.grey200,
                      child: const Icon(Icons.image, size: 48),
                    ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          DestinationCategory.fromString(
                            destination.category,
                          ).icon,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          destination.category,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    destination.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.grey600,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          destination.location,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.grey600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Rating and price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Rating
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            destination.rating.toStringAsFixed(1),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' (${destination.reviewCount})',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.grey500),
                          ),
                        ],
                      ),

                      // Price range
                      Text(
                        destination.priceRangeSymbol,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.grey700,
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
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SkeletonLoader.destinationCard(),
      ),
    );
  }

  Widget _buildEmptyState(DestinationsListUIProvider listUIProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.explore_off, size: 80, color: AppColors.grey300),
            const SizedBox(height: 24),
            Text(
              'No Destinations Found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              listUIProvider.filter.hasActiveFilters
                  ? 'Try adjusting your filters'
                  : 'No destinations available yet',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
            if (listUIProvider.filter.hasActiveFilters) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _clearFilters(listUIProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clear Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error Loading Destinations',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.grey500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
