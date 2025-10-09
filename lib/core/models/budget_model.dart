import 'package:cloud_firestore/cloud_firestore.dart';

/// Trip budget model
class TripBudget {
  final String id;
  final String tripId;
  final String userId;
  final double totalBudget;
  final String currency;
  final List<BudgetCategory> categories;
  final List<Expense> expenses;
  final DateTime createdAt;
  final DateTime updatedAt;

  TripBudget({
    required this.id,
    required this.tripId,
    required this.userId,
    required this.totalBudget,
    this.currency = 'IDR',
    required this.categories,
    required this.expenses,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory TripBudget.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TripBudget(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      userId: data['userId'] ?? '',
      totalBudget: (data['totalBudget'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'IDR',
      categories: (data['categories'] as List<dynamic>?)
              ?.map((c) => BudgetCategory.fromMap(c as Map<String, dynamic>))
              .toList() ??
          [],
      expenses: (data['expenses'] as List<dynamic>?)
              ?.map((e) => Expense.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'userId': userId,
      'totalBudget': totalBudget,
      'currency': currency,
      'categories': categories.map((c) => c.toMap()).toList(),
      'expenses': expenses.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Get total spent
  double get totalSpent {
    return expenses.fold(0.0, (total, expense) => total + expense.amount);
  }

  /// Get remaining budget
  double get remaining {
    return totalBudget - totalSpent;
  }

  /// Get spending percentage
  double get spentPercentage {
    if (totalBudget == 0) return 0.0;
    return (totalSpent / totalBudget) * 100;
  }

  /// Check if over budget
  bool get isOverBudget {
    return totalSpent > totalBudget;
  }

  /// Get spent by category
  double getSpentByCategory(ExpenseCategory category) {
    return expenses
        .where((e) => e.category == category)
        .fold(0.0, (total, expense) => total + expense.amount);
  }

  /// Copy with updated fields
  TripBudget copyWith({
    double? totalBudget,
    String? currency,
    List<BudgetCategory>? categories,
    List<Expense>? expenses,
  }) {
    return TripBudget(
      id: id,
      tripId: tripId,
      userId: userId,
      totalBudget: totalBudget ?? this.totalBudget,
      currency: currency ?? this.currency,
      categories: categories ?? this.categories,
      expenses: expenses ?? this.expenses,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Budget category with allocation
class BudgetCategory {
  final ExpenseCategory category;
  final double allocatedAmount;

  BudgetCategory({
    required this.category,
    required this.allocatedAmount,
  });

  /// Create from map
  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    return BudgetCategory(
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString() == 'ExpenseCategory.${map['category']}',
        orElse: () => ExpenseCategory.other,
      ),
      allocatedAmount: (map['allocatedAmount'] ?? 0).toDouble(),
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'category': category.toString().split('.').last,
      'allocatedAmount': allocatedAmount,
    };
  }
}

/// Individual expense entry
class Expense {
  final String id;
  final ExpenseCategory category;
  final String description;
  final double amount;
  final DateTime date;
  final String? notes;
  final String? receiptUrl;
  final List<String> paidBy; // User IDs who paid
  final List<String> sharedWith; // User IDs to split with

  Expense({
    required this.id,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.notes,
    this.receiptUrl,
    this.paidBy = const [],
    this.sharedWith = const [],
  });

  /// Create from map
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      category: ExpenseCategory.values.firstWhere(
        (e) => e.toString() == 'ExpenseCategory.${map['category']}',
        orElse: () => ExpenseCategory.other,
      ),
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: (map['date'] as Timestamp).toDate(),
      notes: map['notes'],
      receiptUrl: map['receiptUrl'],
      paidBy: List<String>.from(map['paidBy'] ?? []),
      sharedWith: List<String>.from(map['sharedWith'] ?? []),
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category.toString().split('.').last,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
      'receiptUrl': receiptUrl,
      'paidBy': paidBy,
      'sharedWith': sharedWith,
    };
  }

  /// Copy with updated fields
  Expense copyWith({
    ExpenseCategory? category,
    String? description,
    double? amount,
    DateTime? date,
    String? notes,
    String? receiptUrl,
    List<String>? paidBy,
    List<String>? sharedWith,
  }) {
    return Expense(
      id: id,
      category: category ?? this.category,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      paidBy: paidBy ?? this.paidBy,
      sharedWith: sharedWith ?? this.sharedWith,
    );
  }

  /// Get icon for expense category
  String get icon {
    switch (category) {
      case ExpenseCategory.accommodation:
        return '🏨';
      case ExpenseCategory.food:
        return '🍽️';
      case ExpenseCategory.transportation:
        return '🚗';
      case ExpenseCategory.activities:
        return '🎯';
      case ExpenseCategory.shopping:
        return '🛍️';
      case ExpenseCategory.other:
        return '💰';
    }
  }
}

/// Expense category enum
enum ExpenseCategory {
  accommodation,
  food,
  transportation,
  activities,
  shopping,
  other,
}

/// Extension for expense category display
extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.accommodation:
        return 'Accommodation';
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.transportation:
        return 'Transportation';
      case ExpenseCategory.activities:
        return 'Activities';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.other:
        return 'Other';
    }
  }
}
