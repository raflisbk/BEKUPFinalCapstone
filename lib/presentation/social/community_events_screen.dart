import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/config/service_locator.dart';
import '../../core/interfaces/i_community_service.dart';

/// Screen showing community events
class CommunityEventsScreen extends StatefulWidget {
  final String communityId;

  const CommunityEventsScreen({
    super.key,
    required this.communityId,
  });

  @override
  State<CommunityEventsScreen> createState() => _CommunityEventsScreenState();
}

class _CommunityEventsScreenState extends State<CommunityEventsScreen> {
  static const String _tag = 'CommunityEventsScreen';
  
  final ICommunityService _communityService = ServiceLocator.iCommunityService;
  
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = true;
  bool _showUpcomingOnly = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    try {
      setState(() => _isLoading = true);
      
      final events = await _communityService.getCommunityEvents(
        communityId: widget.communityId,
        upcomingOnly: _showUpcomingOnly,
        limit: 50,
      );
      
      setState(() {
        _events = events;
        _isLoading = false;
      });
      
      AppLogger.success(_tag, 'Loaded ${events.length} events');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to load events', e);
      setState(() => _isLoading = false);
    }
  }

  void _showCreateEventDialog() {
    // Placeholder for create event functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create event feature coming soon!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.grey50,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _isLoading ? _buildLoadingState() : _buildEventList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            'Show:',
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Upcoming'),
                  icon: Icon(Icons.event_available, size: 18),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('All Events'),
                  icon: Icon(Icons.calendar_month, size: 18),
                ),
              ],
              selected: {_showUpcomingOnly},
              onSelectionChanged: (Set<bool> selection) {
                HapticHelper.selectionClick();
                setState(() {
                  _showUpcomingOnly = selection.first;
                });
                _loadEvents();
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(WidgetState.selected)) {
                      return AppColors.primary;
                    }
                    return AppColors.grey100;
                  },
                ),
                foregroundColor: WidgetStateProperty.resolveWith<Color>(
                  (states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return AppColors.textPrimary;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SkeletonLoader.container(
          width: double.infinity,
          height: 140,
          borderRadius: 12,
        ),
      ),
    );
  }

  Widget _buildEventList() {
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.event_outlined,
              size: 80,
              color: AppColors.grey300,
            ),
            const SizedBox(height: 16),
            Text(
              'No Events',
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _showUpcomingOnly
                  ? 'No upcoming events scheduled'
                  : 'No events in this community yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          return _buildEventCard(_events[index]);
        },
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final startDate = DateTime.tryParse(event['start_date'] ?? '');
    final endDate = DateTime.tryParse(event['end_date'] ?? '');
    final attendeeCount = event['attendee_count'] ?? 0;
    final maxAttendees = event['max_attendees'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          HapticHelper.lightImpact();
          // Navigate to event detail
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date badge
              if (startDate != null)
                Container(
                  width: 60,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM').format(startDate).toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        DateFormat('d').format(startDate),
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('EEE').format(startDate).toUpperCase(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 16),
              
              // Event details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      event['title'] ?? 'Untitled Event',
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Time
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            startDate != null
                                ? endDate != null
                                    ? '${DateFormat('h:mm a').format(startDate)} - ${DateFormat('h:mm a').format(endDate)}'
                                    : DateFormat('h:mm a').format(startDate)
                                : 'TBA',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    
                    // Location
                    if (event['location'] != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event['location'],
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    
                    // Attendees & RSVP
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          maxAttendees != null
                              ? '$attendeeCount / $maxAttendees attending'
                              : '$attendeeCount attending',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton(
                          onPressed: () {
                            HapticHelper.lightImpact();
                            // RSVP logic
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            minimumSize: Size.zero,
                            side: const BorderSide(color: AppColors.primary),
                          ),
                          child: Text(
                            'RSVP',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
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
      ),
    );
  }
}
