import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/trip_detail_ui_provider.dart';
import '../../core/models/trip_model.dart';
import '../../services/trip_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/widgets/weather_widget.dart';
import 'create_edit_trip_screen.dart';
import 'itinerary_management_screen.dart';
import 'budget_overview_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  static const String _tag = 'TripDetailScreen';

  final TripService _tripService = TripService();

  Future<void> _joinTrip(
    String userId,
    String userName,
    String? photoUrl,
  ) async {
    AppLogger.debug(_tag, 'Joining trip', {'tripId': widget.trip.id});

    try {
      final result = await _tripService.addTripParticipant(
        tripId: widget.trip.id,
        userId: userId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isNotEmpty ? 'Joined trip successfully!' : 'Failed to join trip',
          ),
          backgroundColor: result.isNotEmpty ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join trip'),
          backgroundColor: AppColors.error,
        ),
      );
      
      AppLogger.error(_tag, 'Error joining trip', e);
    }
  }

  Future<void> _leaveTrip(String userId) async {
    // Confirm before leaving
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Trip'),
        content: const Text('Are you sure you want to leave this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    AppLogger.debug(_tag, 'Leaving trip', {'tripId': widget.trip.id});

    try {
      await _tripService.removeTripParticipant(
        tripId: widget.trip.id,
        userId: userId,
      );

      if (!mounted) return;

      Navigator.pop(context); // Go back to trip list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Left trip successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to leave trip'),
          backgroundColor: AppColors.error,
        ),
      );
      
      AppLogger.error(_tag, 'Error leaving trip', e);
    }
  }

  Future<void> _deleteTrip() async {
    await HapticHelper.mediumImpact();

    // Confirm before deleting
    final confirmed = await showDialog<bool>(
      // ignore: use_build_context_synchronously
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text(
          'Are you sure you want to delete this trip? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await HapticHelper.heavyImpact();
              if (!context.mounted) return;
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    AppLogger.debug(_tag, 'Deleting trip', {'tripId': widget.trip.id});

    try {
      await _tripService.deleteTrip(widget.trip.id);

      if (!mounted) return;

      await HapticHelper.success();
      AppLogger.success(_tag, 'Trip deleted successfully');

      // ignore: use_build_context_synchronously
      Navigator.pop(context); // Go back to trip list
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      await HapticHelper.error();
      AppLogger.error(_tag, 'Failed to delete trip', e);

      if (!mounted) return;

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete trip'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showOptionsMenu(
    BuildContext context,
    String currentUserId,
    bool isOwner,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOwner) ...[
                ListTile(
                  leading: const Icon(Icons.edit, color: AppColors.black),
                  title: const Text('Edit Trip'),
                  onTap: () async {
                    final navigator = Navigator.of(context);
                    final provider = context.read<TripDetailUIProvider>();
                    navigator.pop();
                    await HapticHelper.lightImpact();

                    if (!mounted) return;

                    // Navigate to edit screen
                    final result = await navigator.push<bool>(
                      MaterialPageRoute(
                        builder: (context) =>
                            CreateEditTripScreen(trip: widget.trip),
                      ),
                    );

                    // Refresh trip data if edited successfully
                    if (result == true && mounted) {
                      provider.refresh();
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: AppColors.error),
                  title: const Text(
                    'Delete Trip',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteTrip();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(
                    Icons.exit_to_app,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Leave Trip',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _leaveTrip(currentUserId);
                  },
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: TripStatusHelper.getColor(widget.trip.status),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              TripStatusHelper.getLabel(widget.trip.status),
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(widget.trip.title, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 12),

          // Description
          Text(
            widget.trip.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Dates
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${DateFormat('dd MMM').format(widget.trip.startDate)} - ${DateFormat('dd MMM yyyy').format(widget.trip.endDate)}',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Duration
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.trip.durationInDays} days',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Privacy
          Row(
            children: [
              Icon(
                widget.trip.isPublic ? Icons.public : Icons.lock,
                size: 18,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                widget.trip.isPublic ? 'Public Trip' : 'Private Trip',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Destinations', style: AppTextStyles.headlineSmall),
              Text(
                '${widget.trip.destinations.length}',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (widget.trip.destinations.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('📍', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      'No destinations added yet',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.trip.destinations.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final destination = widget.trip.destinations[index];
                return Row(
                  children: [
                    // Order number
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.grey100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: AppTextStyles.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Destination info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            destination.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (destination.scheduledDate != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'EEE, dd MMM yyyy',
                              ).format(destination.scheduledDate!),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (destination.notes != null &&
                              destination.notes!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              destination.notes!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Travelers', style: AppTextStyles.headlineSmall),
              Text(
                '${widget.trip.participantIds.length}',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.trip.participantIds.length,
            separatorBuilder: (context, index) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final participantId = widget.trip.participantIds[index];
              final participant = widget.trip.participants[participantId];
              final isOwner = participantId == widget.trip.userId;

              return Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.grey300,
                    backgroundImage: participant?.photoUrl != null
                        ? NetworkImage(participant!.photoUrl!)
                        : null,
                    child: participant?.photoUrl == null
                        ? Text(
                            (participant?.name ?? 'U')[0].toUpperCase(),
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  // Name and role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              participant?.name ?? 'Unknown',
                              style: AppTextStyles.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isOwner) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Owner',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (participant != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Joined ${DateFormat('dd MMM yyyy').format(participant.joinedAt)}',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildItinerarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Itinerary', style: AppTextStyles.headlineSmall),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Plan your daily activities and schedule',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await HapticHelper.lightImpact();
                if (!mounted) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ItineraryManagementScreen(trip: widget.trip),
                  ),
                );

                // Refresh trip data
                if (mounted) {
                  context.read<TripDetailUIProvider>().refresh();
                }
              },
              icon: const Icon(Icons.event_note, size: 20),
              label: const Text('Manage Itinerary'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.black,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Budget', style: AppTextStyles.headlineSmall),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Track your expenses and manage your budget',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await HapticHelper.lightImpact();
                if (!mounted) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        BudgetOverviewScreen(trip: widget.trip),
                  ),
                );

                // Refresh trip data
                if (mounted) {
                  context.read<TripDetailUIProvider>().refresh();
                }
              },
              icon: const Icon(Icons.account_balance_wallet, size: 20),
              label: const Text('Manage Budget'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.black,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection() {
    // Show weather for the first destination if available
    if (widget.trip.destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    final firstDestination = widget.trip.destinations.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weather at ${firstDestination.name}',
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: 12),
          WeatherWidget(cityName: firstDestination.name),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final currentUserId = authProvider.user?.uid;
        final isOwner = currentUserId == widget.trip.userId;
        final isParticipant =
            currentUserId != null &&
            widget.trip.participantIds.contains(currentUserId);

        return Scaffold(
          backgroundColor: AppColors.grey50,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.black),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Trip Details',
              style: AppTextStyles.headlineSmall,
            ),
            actions: [
              if (isParticipant)
                IconButton(
                  icon: const Icon(Icons.more_vert, color: AppColors.black),
                  onPressed: () =>
                      _showOptionsMenu(context, currentUserId, isOwner),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: AppColors.divider, height: 1),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoSection(),
              const SizedBox(height: 16),
              _buildDestinationsSection(),
              const SizedBox(height: 16),
              _buildItinerarySection(),
              const SizedBox(height: 16),
              _buildBudgetSection(),
              const SizedBox(height: 16),
              _buildWeatherSection(),
              const SizedBox(height: 16),
              _buildParticipantsSection(),
              const SizedBox(height: 80), // Space for bottom button
            ],
          ),
          bottomSheet:
              currentUserId != null && !isParticipant && widget.trip.isPublic
              ? Container(
                  color: AppColors.white,
                  padding: const EdgeInsets.all(16),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _joinTrip(
                          currentUserId,
                          authProvider.user!.displayName,
                          authProvider.user!.photoUrl,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.black,
                          foregroundColor: AppColors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Join Trip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }
}
