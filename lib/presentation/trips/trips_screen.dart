import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/trips_ui_provider.dart';
import '../../core/models/trip_model.dart';
import '../../services/trip_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';

class TripsScreen extends StatelessWidget {
  const TripsScreen({super.key});

  static const String _tag = 'TripsScreen';

  void _navigateToCreateTrip(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CreateEditTripScreen(), // No trip = create mode
      ),
    );
  }

  void _navigateToTripDetail(BuildContext context, Trip trip) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TripDetailScreen(trip: trip)),
    );
  }

  Widget _buildFilterChips(BuildContext context, TripsUIProvider uiProvider) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: TripFilter.values.map((filter) {
          final isSelected = uiProvider.selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(TripFilterHelper.getLabel(filter)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  uiProvider.setFilter(filter);
                  AppLogger.debug(_tag, 'Filter changed', {
                    'filter': filter.toString(),
                  });
                }
              },
              backgroundColor: AppColors.grey50,
              selectedColor: AppColors.black,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.black : AppColors.border,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, Trip trip) {
    return GestureDetector(
      onTap: () => _navigateToTripDetail(context, trip),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover image or placeholder
            Container(
              height: 160,
              decoration: const BoxDecoration(
                color: AppColors.grey50,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  // Placeholder
                  const Center(
                    child: Text('🗺️', style: TextStyle(fontSize: 48)),
                  ),

                  // Status badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: TripStatusHelper.getColor(trip.status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        TripStatusHelper.getLabel(trip.status),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Trip info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    trip.title,
                    style: AppTextStyles.headlineSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Description
                  Text(
                    trip.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Dates
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${DateFormat('dd MMM').format(trip.startDate)} - ${DateFormat('dd MMM yyyy').format(trip.endDate)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${trip.durationInDays} days',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Destinations and participants
                  Row(
                    children: [
                      // Destinations
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.destinations.length} destinations',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Participants
                      const Icon(
                        Icons.people,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${trip.participantIds.length} travelers',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
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

  @override
  Widget build(BuildContext context) {
    final tripService = TripService();

    return Consumer<TripsUIProvider>(
      builder: (context, uiProvider, child) {
        return Scaffold(
          backgroundColor: AppColors.grey50,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            title: const Text('My Trips', style: AppTextStyles.headlineSmall),
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: AppColors.black),
                onPressed: () => _navigateToCreateTrip(context),
                tooltip: 'Create Trip',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.divider, height: 1),
            ),
          ),
          body: Column(
            children: [
              const SizedBox(height: 8),

              // Filter chips
              _buildFilterChips(context, uiProvider),
              const SizedBox(height: 8),

              // Trips list
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    final userId = authProvider.user?.uid;

                    if (userId == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('👤', style: TextStyle(fontSize: 64)),
                            const SizedBox(height: 16),
                            Text(
                              'Please login to view trips',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return StreamBuilder<List<Trip>>(
                      stream: tripService.getTripsStream(
                        userId: userId,
                        filter: uiProvider.selectedFilter,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.black,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading trips',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }

                        final trips = snapshot.data ?? [];

                        if (trips.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  '🗺️',
                                  style: TextStyle(fontSize: 64),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No trips yet',
                                  style: AppTextStyles.headlineSmall,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start planning your next adventure',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () =>
                                      _navigateToCreateTrip(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.black,
                                    foregroundColor: AppColors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                  child: const Text('Create Trip'),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: trips.length,
                          itemBuilder: (context, index) {
                            return _buildTripCard(context, trips[index]);
                          },
                        );
                      },
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
}
