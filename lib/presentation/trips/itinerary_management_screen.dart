import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/models/trip_model.dart';
import '../../services/trip_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/logger.dart';
import '../../core/utils/haptic_helper.dart';
import 'add_edit_itinerary_item_screen.dart';

/// Screen for managing trip itinerary items
class ItineraryManagementScreen extends StatefulWidget {
  final Trip trip;

  const ItineraryManagementScreen({
    super.key,
    required this.trip,
  });

  @override
  State<ItineraryManagementScreen> createState() => _ItineraryManagementScreenState();
}

class _ItineraryManagementScreenState extends State<ItineraryManagementScreen> {
  static const String _tag = 'ItineraryManagementScreen';

  final TripService _tripService = TripService();
  bool _isReordering = false;

  @override
  void initState() {
    super.initState();
    AppLogger.debug(_tag, 'Itinerary management screen initialized', {
      'tripId': widget.trip.id,
      'itemCount': widget.trip.itinerary.length,
    });
  }

  Future<void> _addItineraryItem() async {
    HapticHelper.lightImpact();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditItineraryItemScreen(trip: widget.trip),
      ),
    );

    if (result == true && mounted) {
      setState(() {}); // Refresh list
    }
  }

  Future<void> _editItineraryItem(ItineraryItem item) async {
    HapticHelper.lightImpact();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditItineraryItemScreen(
          trip: widget.trip,
          item: item,
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {}); // Refresh list
    }
  }

  Future<void> _deleteItineraryItem(ItineraryItem item) async {
    await HapticHelper.mediumImpact();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        title: Text('Delete Activity', style: AppTextStyles.titleLarge),
        content: Text(
          'Are you sure you want to delete "${item.title}"?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: AppTextStyles.labelLarge),
          ),
          TextButton(
            onPressed: () {
              HapticHelper.heavyImpact();
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text('Delete', style: AppTextStyles.labelLarge),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await _tripService.deleteItineraryItem(
      tripId: widget.trip.id,
      itemId: item.id,
    );

    if (!mounted) return;

    if (success) {
      await HapticHelper.success();
      setState(() {
        widget.trip.itinerary.removeWhere((i) => i.id == item.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity deleted'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      await HapticHelper.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete activity'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleCompletion(ItineraryItem item) async {
    HapticHelper.selectionClick();

    final success = await _tripService.updateItineraryItem(
      tripId: widget.trip.id,
      itemId: item.id,
      isCompleted: !item.isCompleted,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        final index = widget.trip.itinerary.indexWhere((i) => i.id == item.id);
        if (index != -1) {
          widget.trip.itinerary[index] = ItineraryItem(
            id: item.id,
            title: item.title,
            description: item.description,
            type: item.type,
            startTime: item.startTime,
            endTime: item.endTime,
            location: item.location,
            locationId: item.locationId,
            notes: item.notes,
            isCompleted: !item.isCompleted,
            order: item.order,
          );
        }
      });
    }
  }

  void _toggleReorderMode() {
    HapticHelper.lightImpact();
    setState(() {
      _isReordering = !_isReordering;
    });
  }

  Future<void> _reorderItems(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = widget.trip.itinerary.removeAt(oldIndex);
      widget.trip.itinerary.insert(newIndex, item);
    });

    HapticHelper.mediumImpact();

    // Update order in backend
    final itemIds = widget.trip.itinerary.map((i) => i.id).toList();
    await _tripService.reorderItineraryItems(
      tripId: widget.trip.id,
      itemIds: itemIds,
    );
  }

  List<ItineraryItem> _getSortedItinerary() {
    final items = List<ItineraryItem>.from(widget.trip.itinerary);
    items.sort((a, b) => a.startTime.compareTo(b.startTime));
    return items;
  }

  Map<String, List<ItineraryItem>> _groupByDate() {
    final sorted = _getSortedItinerary();
    final grouped = <String, List<ItineraryItem>>{};

    for (var item in sorted) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.startTime);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupByDate();
    final isEmpty = widget.trip.itinerary.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () {
            HapticHelper.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Text('Itinerary', style: AppTextStyles.headlineSmall),
        actions: [
          if (!isEmpty)
            IconButton(
              icon: Icon(
                _isReordering ? Icons.check : Icons.reorder,
                color: AppColors.black,
              ),
              onPressed: _toggleReorderMode,
              tooltip: _isReordering ? 'Done' : 'Reorder',
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppColors.divider,
            height: 1,
          ),
        ),
      ),
      body: isEmpty ? _buildEmptyState() : _buildItineraryList(groupedItems),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addItineraryItem,
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeIn(
        duration: const Duration(milliseconds: 600),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: const Icon(
                  Icons.event_note,
                  size: 64,
                  color: AppColors.grey400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'No Activities Yet',
                style: AppTextStyles.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Start planning your trip by adding activities, accommodations, and transport.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _addItineraryItem,
                icon: const Icon(Icons.add),
                label: const Text('Add First Activity'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.black,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItineraryList(Map<String, List<ItineraryItem>> groupedItems) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80, top: 16),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final dateKey = groupedItems.keys.elementAt(index);
        final items = groupedItems[dateKey]!;
        final date = DateTime.parse(dateKey);

        return FadeInUp(
          duration: Duration(milliseconds: 300 + (index * 100)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(date),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Items for this date
              if (_isReordering)
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  onReorder: _reorderItems,
                  itemBuilder: (context, itemIndex) {
                    final item = items[itemIndex];
                    return _buildItineraryCard(item, key: ValueKey(item.id));
                  },
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, itemIndex) {
                    final item = items[itemIndex];
                    return _buildItineraryCard(item);
                  },
                ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildItineraryCard(ItineraryItem item, {Key? key}) {
    final timeFormat = DateFormat('h:mm a');
    final startTime = timeFormat.format(item.startTime);
    final endTime = timeFormat.format(item.endTime);

    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isCompleted ? AppColors.success : AppColors.border,
          width: item.isCompleted ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: _isReordering ? null : () => _editItineraryItem(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Reorder handle or Completion checkbox
              if (_isReordering)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Icon(
                    Icons.drag_handle,
                    color: AppColors.grey400,
                  ),
                )
              else
                GestureDetector(
                  onTap: () => _toggleCompletion(item),
                  child: Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: item.isCompleted ? AppColors.success : AppColors.white,
                      border: Border.all(
                        color: item.isCompleted ? AppColors.success : AppColors.grey300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: item.isCompleted
                        ? const Icon(Icons.check, size: 16, color: AppColors.white)
                        : null,
                  ),
                ),

              // Type Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ItineraryTypeHelper.getColor(item.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTypeIcon(item.type),
                  color: ItineraryTypeHelper.getColor(item.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: AppTextStyles.titleSmall.copyWith(
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$startTime - $endTime',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    if (item.location != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.location!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              if (!_isReordering)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: AppColors.grey600),
                  color: AppColors.white,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editItineraryItem(item);
                    } else if (value == 'delete') {
                      _deleteItineraryItem(item);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          const Icon(Icons.edit, size: 20),
                          const SizedBox(width: 12),
                          Text('Edit', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete, size: 20, color: AppColors.error),
                          const SizedBox(width: 12),
                          Text(
                            'Delete',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(ItineraryType type) {
    switch (type) {
      case ItineraryType.activity:
        return Icons.local_activity;
      case ItineraryType.accommodation:
        return Icons.hotel;
      case ItineraryType.transport:
        return Icons.directions_car;
      case ItineraryType.meal:
        return Icons.restaurant;
      case ItineraryType.other:
        return Icons.more_horiz;
    }
  }

  @override
  void dispose() {
    AppLogger.debug(_tag, 'Disposing itinerary management screen');
    super.dispose();
  }
}
