/// Payment-related models for Supabase backend
library payment_model;

/// Payment method enumeration
enum PaymentMethod {
  card('card'),
  paypal('paypal'),
  bankTransfer('bank_transfer'),
  digitalWallet('digital_wallet'),
  crypto('crypto'),
  applePay('apple_pay'),
  googlePay('google_pay');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.card,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.paypal:
        return 'PayPal';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.digitalWallet:
        return 'Digital Wallet';
      case PaymentMethod.crypto:
        return 'Cryptocurrency';
      case PaymentMethod.applePay:
        return 'Apple Pay';
      case PaymentMethod.googlePay:
        return 'Google Pay';
    }
  }
}

/// Payment status enumeration
enum PaymentStatus {
  pending('pending'),
  processing('processing'),
  completed('completed'),
  failed('failed'),
  cancelled('cancelled'),
  refunded('refunded'),
  partialRefund('partial_refund');

  const PaymentStatus(this.value);
  final String value;

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Pending';
      case PaymentStatus.processing:
        return 'Processing';
      case PaymentStatus.completed:
        return 'Completed';
      case PaymentStatus.failed:
        return 'Failed';
      case PaymentStatus.cancelled:
        return 'Cancelled';
      case PaymentStatus.refunded:
        return 'Refunded';
      case PaymentStatus.partialRefund:
        return 'Partial Refund';
    }
  }
}

/// Payment transaction model
class PaymentTransaction {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? failureReason;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    required this.description,
    this.metadata = const {},
    required this.createdAt,
    this.completedAt,
    this.failureReason,
  });

  /// Create from Supabase row
  factory PaymentTransaction.fromSupabase(Map<String, dynamic> data) {
    return PaymentTransaction(
      id: data['id'] ?? '',
      userId: data['user_id'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      method: PaymentMethod.fromString(data['method'] ?? 'card'),
      status: PaymentStatus.fromString(data['status'] ?? 'pending'),
      description: data['description'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: DateTime.parse(data['created_at']),
      completedAt: data['completed_at'] != null 
          ? DateTime.parse(data['completed_at']) 
          : null,
      failureReason: data['failure_reason'],
    );
  }

  /// Convert to Supabase row
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'method': method.value,
      'status': status.value,
      'description': description,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'failure_reason': failureReason,
    };
  }

  /// Convert to Map for local storage
  Map<String, dynamic> toMap() {
    return toSupabase();
  }

  /// Create from Map
  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    return PaymentTransaction.fromSupabase(map);
  }

  /// Create a copy with updated fields
  PaymentTransaction copyWith({
    String? id,
    String? userId,
    double? amount,
    String? currency,
    PaymentMethod? method,
    PaymentStatus? status,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? completedAt,
    String? failureReason,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      status: status ?? this.status,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      failureReason: failureReason ?? this.failureReason,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentTransaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PaymentTransaction(id: $id, amount: $amount $currency, status: ${status.displayName})';
  }
}

/// Subscription plan model
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String interval; // monthly, yearly, etc.
  final List<String> features;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.interval,
    required this.features,
    required this.isActive,
    this.metadata = const {},
  });

  /// Create from Supabase row
  factory SubscriptionPlan.fromSupabase(Map<String, dynamic> data) {
    return SubscriptionPlan(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'USD',
      interval: data['interval'] ?? 'monthly',
      features: List<String>.from(data['features'] ?? []),
      isActive: data['is_active'] ?? true,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  /// Convert to Supabase row
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'interval': interval,
      'features': features,
      'is_active': isActive,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SubscriptionPlan && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SubscriptionPlan(id: $id, name: $name, price: $price $currency/$interval)';
  }
}
