import '../stubs/firebase_stubs.dart';
import 'package:flutter/material.dart';

/// Trip model for planning itineraries
class Trip {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String title;
  final String description;
  final String? coverImageUrl;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> destinationIds;
  final List<TripDestination> destinations;
  final List<String> participantIds;
  final Map<String, ParticipantInfo> participants;
  final TripStatus status;
  final bool isPublic;
  
  // Itinerary management
  final List<ItineraryItem> itinerary;
  
  // Budget tracking
  final TripBudget? budget;
  final List<BudgetExpense> expenses;
  
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.title,
    required this.description,
    this.coverImageUrl,
    required this.startDate,
    required this.endDate,
    this.destinationIds = const [],
    this.destinations = const [],
    this.participantIds = const [],
    this.participants = const {},
    this.status = TripStatus.planning,
    this.isPublic = true,
    this.itinerary = const [],
    this.budget,
    this.expenses = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Trip(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhotoUrl: data['userPhotoUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      coverImageUrl: data['coverImageUrl'],
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      destinationIds: List<String>.from(data['destinationIds'] ?? []),
      destinations: (data['destinations'] as List<dynamic>?)
              ?.map((d) => TripDestination.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participants: (data['participants'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              ParticipantInfo.fromMap(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      status: TripStatus.values.firstWhere(
        (e) => e.toString() == 'TripStatus.${data['status']}',
        orElse: () => TripStatus.planning,
      ),
      isPublic: data['isPublic'] ?? true,
      itinerary: (data['itinerary'] as List<dynamic>?)
              ?.map((i) => ItineraryItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      budget: data['budget'] != null
          ? TripBudget.fromMap(data['budget'] as Map<String, dynamic>)
          : null,
      expenses: (data['expenses'] as List<dynamic>?)
              ?.map((e) => BudgetExpense.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'destinationIds': destinationIds,
      'destinations': destinations.map((d) => d.toMap()).toList(),
      'participantIds': participantIds,
      'participants': participants.map((key, value) => MapEntry(key, value.toMap())),
      'status': status.toString().split('.').last,
      'isPublic': isPublic,
      'itinerary': itinerary.map((i) => i.toMap()).toList(),
      'budget': budget?.toMap(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create from Map (for offline cache)
  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userPhotoUrl: map['userPhotoUrl'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      coverImageUrl: map['coverImageUrl'],
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      destinationIds: List<String>.from(map['destinationIds'] ?? []),
      destinations: (map['destinations'] as List<dynamic>?)
              ?.map((d) => TripDestination.fromMap(d as Map<String, dynamic>))
              .toList() ??
          [],
      participantIds: List<String>.from(map['participantIds'] ?? []),
      participants: (map['participants'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              ParticipantInfo.fromMap(value as Map<String, dynamic>),
            ),
          ) ??
          {},
      status: TripStatus.values.firstWhere(
        (e) => e.toString() == 'TripStatus.${map['status']}',
        orElse: () => TripStatus.planning,
      ),
      isPublic: map['isPublic'] ?? true,
      itinerary: (map['itinerary'] as List<dynamic>?)
              ?.map((i) => ItineraryItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      budget: map['budget'] != null
          ? TripBudget.fromMap(map['budget'] as Map<String, dynamic>)
          : null,
      expenses: (map['expenses'] as List<dynamic>?)
              ?.map((e) => BudgetExpense.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  /// Convert to Map (for offline cache)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'title': title,
      'description': description,
      'coverImageUrl': coverImageUrl,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'destinationIds': destinationIds,
      'destinations': destinations.map((d) => d.toMap()).toList(),
      'participantIds': participantIds,
      'participants': participants.map((key, value) => MapEntry(key, value.toMap())),
      'status': status.toString().split('.').last,
      'isPublic': isPublic,
      'itinerary': itinerary.map((i) => i.toMap()).toList(),
      'budget': budget?.toMap(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Calculate total budget spent
  double get totalSpent {
    return expenses.fold(0.0, (total, expense) => total + expense.amount);
  }

  /// Calculate budget remaining
  double get budgetRemaining {
    if (budget == null) return 0.0;
    return budget!.totalBudget - totalSpent;
  }

  /// Check if over budget
  bool get isOverBudget {
    if (budget == null) return false;
    return totalSpent > budget!.totalBudget;
  }

  /// Get budget usage percentage
  double get budgetUsagePercentage {
    if (budget == null || budget!.totalBudget == 0) return 0.0;
    return (totalSpent / budget!.totalBudget) * 100;
  }

  /// Get trip duration in days
  int get durationInDays {
    return endDate.difference(startDate).inDays + 1;
  }

  /// Check if trip is in the past
  bool get isPast {
    return endDate.isBefore(DateTime.now());
  }

  /// Check if trip is ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return startDate.isBefore(now) && endDate.isAfter(now);
  }

  /// Check if trip is upcoming
  bool get isUpcoming {
    return startDate.isAfter(DateTime.now());
  }
}

/// Trip destination with scheduling
class TripDestination {
  final String id;
  final String name;
  final String? imageUrl;
  final DateTime? scheduledDate;
  final String? notes;
  final int order;

  TripDestination({
    required this.id,
    required this.name,
    this.imageUrl,
    this.scheduledDate,
    this.notes,
    this.order = 0,
  });

  factory TripDestination.fromMap(Map<String, dynamic> map) {
    return TripDestination(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      imageUrl: map['imageUrl'],
      scheduledDate: map['scheduledDate'] != null
          ? (map['scheduledDate'] as Timestamp).toDate()
          : null,
      notes: map['notes'],
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'scheduledDate':
          scheduledDate != null ? Timestamp.fromDate(scheduledDate!) : null,
      'notes': notes,
      'order': order,
    };
  }
}

/// Participant information
class ParticipantInfo {
  final String name;
  final String? photoUrl;
  final DateTime joinedAt;

  ParticipantInfo({
    required this.name,
    this.photoUrl,
    required this.joinedAt,
  });

  factory ParticipantInfo.fromMap(Map<String, dynamic> map) {
    return ParticipantInfo(
      name: map['name'] ?? '',
      photoUrl: map['photoUrl'],
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'photoUrl': photoUrl,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

/// Trip status enum
enum TripStatus {
  planning,
  confirmed,
  ongoing,
  completed,
  cancelled,
}

/// Trip status helper
class TripStatusHelper {
  static String getLabel(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return 'Planning';
      case TripStatus.confirmed:
        return 'Confirmed';
      case TripStatus.ongoing:
        return 'Ongoing';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }

  static Color getColor(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return const Color(0xFF757575); // Gray
      case TripStatus.confirmed:
        return const Color(0xFF2196F3); // Blue
      case TripStatus.ongoing:
        return const Color(0xFF4CAF50); // Green
      case TripStatus.completed:
        return const Color(0xFF9E9E9E); // Light Gray
      case TripStatus.cancelled:
        return const Color(0xFFF44336); // Red
    }
  }
}

/// Trip filter options
enum TripFilter {
  all,
  upcoming,
  ongoing,
  past,
  myTrips,
  joined,
}

class TripFilterHelper {
  static String getLabel(TripFilter filter) {
    switch (filter) {
      case TripFilter.all:
        return 'All Trips';
      case TripFilter.upcoming:
        return 'Upcoming';
      case TripFilter.ongoing:
        return 'Ongoing';
      case TripFilter.past:
        return 'Past';
      case TripFilter.myTrips:
        return 'My Trips';
      case TripFilter.joined:
        return 'Joined';
    }
  }
}

/// Itinerary item for detailed scheduling
class ItineraryItem {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? locationId;
  final ItineraryType type;
  final String? notes;
  final bool isCompleted;
  final int order;

  ItineraryItem({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.locationId,
    this.type = ItineraryType.activity,
    this.notes,
    this.isCompleted = false,
    this.order = 0,
  });

  factory ItineraryItem.fromMap(Map<String, dynamic> map) {
    return ItineraryItem(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'],
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      location: map['location'],
      locationId: map['locationId'],
      type: ItineraryType.values.firstWhere(
        (e) => e.toString() == 'ItineraryType.${map['type']}',
        orElse: () => ItineraryType.activity,
      ),
      notes: map['notes'],
      isCompleted: map['isCompleted'] ?? false,
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'location': location,
      'locationId': locationId,
      'type': type.toString().split('.').last,
      'notes': notes,
      'isCompleted': isCompleted,
      'order': order,
    };
  }

  /// Get duration in minutes
  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Check if item conflicts with another
  bool conflictsWith(ItineraryItem other) {
    return (startTime.isBefore(other.endTime) && 
            endTime.isAfter(other.startTime));
  }
}

/// Itinerary item types
enum ItineraryType {
  activity,
  accommodation,
  transport,
  meal,
  other,
}

class ItineraryTypeHelper {
  static String getLabel(ItineraryType type) {
    switch (type) {
      case ItineraryType.activity:
        return 'Activity';
      case ItineraryType.accommodation:
        return 'Accommodation';
      case ItineraryType.transport:
        return 'Transport';
      case ItineraryType.meal:
        return 'Meal';
      case ItineraryType.other:
        return 'Other';
    }
  }

  static Color getColor(ItineraryType type) {
    switch (type) {
      case ItineraryType.activity:
        return const Color(0xFF2196F3); // Blue
      case ItineraryType.accommodation:
        return const Color(0xFF9C27B0); // Purple
      case ItineraryType.transport:
        return const Color(0xFFFF9800); // Orange
      case ItineraryType.meal:
        return const Color(0xFF4CAF50); // Green
      case ItineraryType.other:
        return const Color(0xFF757575); // Gray
    }
  }
}

/// Trip budget with category breakdown
class TripBudget {
  final double totalBudget;
  final String currency;
  final Map<BudgetCategory, double> categoryBudgets;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripBudget({
    required this.totalBudget,
    this.currency = 'USD',
    this.categoryBudgets = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory TripBudget.fromMap(Map<String, dynamic> map) {
    final categoryBudgetsMap = map['categoryBudgets'] as Map<String, dynamic>?;
    final categoryBudgets = <BudgetCategory, double>{};
    
    if (categoryBudgetsMap != null) {
      categoryBudgetsMap.forEach((key, value) {
        final category = BudgetCategory.values.firstWhere(
          (e) => e.toString() == 'BudgetCategory.$key',
          orElse: () => BudgetCategory.other,
        );
        categoryBudgets[category] = (value as num).toDouble();
      });
    }

    return TripBudget(
      totalBudget: (map['totalBudget'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      categoryBudgets: categoryBudgets,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    final categoryBudgetsMap = <String, double>{};
    categoryBudgets.forEach((key, value) {
      categoryBudgetsMap[key.toString().split('.').last] = value;
    });

    return {
      'totalBudget': totalBudget,
      'currency': currency,
      'categoryBudgets': categoryBudgetsMap,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get remaining budget for a category
  double getCategoryRemaining(BudgetCategory category, double spent) {
    final categoryBudget = categoryBudgets[category] ?? 0.0;
    return categoryBudget - spent;
  }
}

/// Budget expense tracking
class BudgetExpense {
  final String id;
  final String description;
  final double amount;
  final String currency;
  final BudgetCategory category;
  final DateTime date;
  final String? paidBy;
  final List<String> sharedWith;
  final String? receiptUrl;
  final String? notes;
  final DateTime createdAt;

  BudgetExpense({
    required this.id,
    required this.description,
    required this.amount,
    this.currency = 'USD',
    required this.category,
    required this.date,
    this.paidBy,
    this.sharedWith = const [],
    this.receiptUrl,
    this.notes,
    required this.createdAt,
  });

  factory BudgetExpense.fromMap(Map<String, dynamic> map) {
    return BudgetExpense(
      id: map['id'] ?? '',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      category: BudgetCategory.values.firstWhere(
        (e) => e.toString() == 'BudgetCategory.${map['category']}',
        orElse: () => BudgetCategory.other,
      ),
      date: (map['date'] as Timestamp).toDate(),
      paidBy: map['paidBy'],
      sharedWith: List<String>.from(map['sharedWith'] ?? []),
      receiptUrl: map['receiptUrl'],
      notes: map['notes'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'currency': currency,
      'category': category.toString().split('.').last,
      'date': Timestamp.fromDate(date),
      'paidBy': paidBy,
      'sharedWith': sharedWith,
      'receiptUrl': receiptUrl,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Calculate share per person
  double getSharePerPerson() {
    final totalPeople = sharedWith.length + (paidBy != null ? 1 : 0);
    if (totalPeople == 0) return amount;
    return amount / totalPeople;
  }
}

/// Budget categories
enum BudgetCategory {
  accommodation,
  transport,
  food,
  activities,
  shopping,
  other,
}

class BudgetCategoryHelper {
  static String getLabel(BudgetCategory category) {
    switch (category) {
      case BudgetCategory.accommodation:
        return 'Accommodation';
      case BudgetCategory.transport:
        return 'Transport';
      case BudgetCategory.food:
        return 'Food & Drinks';
      case BudgetCategory.activities:
        return 'Activities';
      case BudgetCategory.shopping:
        return 'Shopping';
      case BudgetCategory.other:
        return 'Other';
    }
  }

  static Color getColor(BudgetCategory category) {
    switch (category) {
      case BudgetCategory.accommodation:
        return const Color(0xFF9C27B0); // Purple
      case BudgetCategory.transport:
        return const Color(0xFFFF9800); // Orange
      case BudgetCategory.food:
        return const Color(0xFF4CAF50); // Green
      case BudgetCategory.activities:
        return const Color(0xFF2196F3); // Blue
      case BudgetCategory.shopping:
        return const Color(0xFFE91E63); // Pink
      case BudgetCategory.other:
        return const Color(0xFF757575); // Gray
    }
  }
}

