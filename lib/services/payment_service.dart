import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/utils/logger.dart';

/// Payment method types
enum PaymentMethod {
  creditCard,
  debitCard,
  paypal,
  googlePay,
  applePay,
}

/// Payment status
enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  refunded,
  cancelled,
}

/// Payment transaction model
class PaymentTransaction {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;

  const PaymentTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.status,
    this.description,
    this.metadata,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'method': method.name,
      'status': status.name,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  factory PaymentTransaction.fromMap(Map<String, dynamic> map) {
    return PaymentTransaction(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'USD',
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => PaymentMethod.creditCard,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      description: map['description'],
      metadata: map['metadata'],
      createdAt: DateTime.parse(map['createdAt']),
      completedAt: map['completedAt'] != null ? DateTime.parse(map['completedAt']) : null,
      errorMessage: map['errorMessage'],
    );
  }
}

/// Subscription plan model
class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final String currency;
  final String billingPeriod; // monthly, yearly
  final List<String> features;
  final bool isPopular;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.billingPeriod,
    required this.features,
    this.isPopular = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'billingPeriod': billingPeriod,
      'features': features,
      'isPopular': isPopular,
    };
  }
}

/// Service for payment processing and subscription management
class PaymentService {
  static const String _tag = 'PaymentService';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize payment gateway (Stripe/PayPal)
  Future<bool> initialize() async {
    try {
      AppLogger.info(_tag, 'Initializing payment service');

      // In real implementation:
      // - Initialize Stripe with publishable key
      // - Initialize PayPal SDK
      // Stripe.publishableKey = 'your_publishable_key';

      AppLogger.success(_tag, 'Payment service initialized');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to initialize payment service', e, stackTrace);
      return false;
    }
  }

  /// Process payment
  Future<PaymentTransaction?> processPayment({
    required String userId,
    required double amount,
    required String currency,
    required PaymentMethod method,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.info(_tag, 'Processing payment', {
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'method': method.name,
      });

      // Create transaction record
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
      var transaction = PaymentTransaction(
        id: transactionId,
        userId: userId,
        amount: amount,
        currency: currency,
        method: method,
        status: PaymentStatus.processing,
        description: description,
        metadata: metadata,
        createdAt: DateTime.now(),
      );

      // Save to Firestore
      await _firestore.collection('payment_transactions').doc(transactionId).set(
            transaction.toMap(),
          );

      // Process payment based on method
      bool success = false;
      String? errorMessage;

      switch (method) {
        case PaymentMethod.creditCard:
        case PaymentMethod.debitCard:
          success = await _processCardPayment(amount, currency, metadata);
          break;
        case PaymentMethod.paypal:
          success = await _processPayPalPayment(amount, currency, metadata);
          break;
        case PaymentMethod.googlePay:
          success = await _processGooglePay(amount, currency, metadata);
          break;
        case PaymentMethod.applePay:
          success = await _processApplePay(amount, currency, metadata);
          break;
      }

      // Update transaction status
      transaction = PaymentTransaction(
        id: transaction.id,
        userId: transaction.userId,
        amount: transaction.amount,
        currency: transaction.currency,
        method: transaction.method,
        status: success ? PaymentStatus.completed : PaymentStatus.failed,
        description: transaction.description,
        metadata: transaction.metadata,
        createdAt: transaction.createdAt,
        completedAt: success ? DateTime.now() : null,
        errorMessage: success ? null : errorMessage ?? 'Payment failed',
      );

      // Update Firestore
      await _firestore.collection('payment_transactions').doc(transactionId).update(
            transaction.toMap(),
          );

      if (success) {
        AppLogger.success(_tag, 'Payment completed successfully', {
          'transactionId': transactionId,
        });
      } else {
        AppLogger.error(_tag, 'Payment failed', {
          'transactionId': transactionId,
          'error': errorMessage,
        });
      }

      return transaction;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to process payment', e, stackTrace);
      return null;
    }
  }

  /// Process credit/debit card payment
  Future<bool> _processCardPayment(
    double amount,
    String currency,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      AppLogger.debug(_tag, 'Processing card payment');

      // In real implementation using Stripe:
      // final paymentMethod = await Stripe.instance.createPaymentMethod(...);
      // final paymentIntent = await createPaymentIntent(amount, currency);
      // final result = await Stripe.instance.confirmPayment(paymentIntent.clientSecret);
      // return result.status == PaymentIntentStatus.succeeded;

      // Mock: Simulate successful payment
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Card payment failed', e, stackTrace);
      return false;
    }
  }

  /// Process PayPal payment
  Future<bool> _processPayPalPayment(
    double amount,
    String currency,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      AppLogger.debug(_tag, 'Processing PayPal payment');

      // In real implementation:
      // Use flutter_paypal package
      // Navigate to PayPal checkout
      // Handle callback

      // Mock implementation
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'PayPal payment failed', e, stackTrace);
      return false;
    }
  }

  /// Process Google Pay payment
  Future<bool> _processGooglePay(
    double amount,
    String currency,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      AppLogger.debug(_tag, 'Processing Google Pay payment');

      // In real implementation:
      // Use pay package from Google
      // const _paymentItems = [PaymentItem(...)];
      // await Pay.showPaymentSheet(_paymentItems);

      // Mock implementation
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Google Pay payment failed', e, stackTrace);
      return false;
    }
  }

  /// Process Apple Pay payment
  Future<bool> _processApplePay(
    double amount,
    String currency,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      AppLogger.debug(_tag, 'Processing Apple Pay payment');

      // In real implementation:
      // Use pay package
      // Similar to Google Pay but for iOS

      // Mock implementation
      await Future.delayed(const Duration(seconds: 2));
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Apple Pay payment failed', e, stackTrace);
      return false;
    }
  }

  /// Get available subscription plans
  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      AppLogger.debug(_tag, 'Getting subscription plans');

      // In real app, fetch from Firestore or backend
      return [
        const SubscriptionPlan(
          id: 'free',
          name: 'Free',
          description: 'Basic travel planning features',
          price: 0,
          currency: 'USD',
          billingPeriod: 'monthly',
          features: [
            'Create up to 3 trips',
            'Basic itinerary planning',
            'Community features',
            'Limited AI recommendations',
          ],
        ),
        const SubscriptionPlan(
          id: 'premium_monthly',
          name: 'Premium',
          description: 'Full access to all features',
          price: 9.99,
          currency: 'USD',
          billingPeriod: 'monthly',
          features: [
            'Unlimited trips',
            'Advanced AI recommendations',
            'Budget optimization',
            'Offline mode',
            'Priority support',
            'No ads',
          ],
          isPopular: true,
        ),
        const SubscriptionPlan(
          id: 'premium_yearly',
          name: 'Premium Annual',
          description: 'Best value - 2 months free',
          price: 99.99,
          currency: 'USD',
          billingPeriod: 'yearly',
          features: [
            'All Premium features',
            '2 months free',
            'Early access to new features',
            'Exclusive travel guides',
          ],
        ),
      ];
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get subscription plans', e, stackTrace);
      return [];
    }
  }

  /// Subscribe to plan
  Future<bool> subscribeToPlan({
    required String userId,
    required String planId,
    required PaymentMethod paymentMethod,
  }) async {
    try {
      AppLogger.info(_tag, 'Subscribing to plan', {
        'userId': userId,
        'planId': planId,
      });

      final plans = await getSubscriptionPlans();
      final plan = plans.firstWhere((p) => p.id == planId);

      // Process payment for subscription
      final transaction = await processPayment(
        userId: userId,
        amount: plan.price,
        currency: plan.currency,
        method: paymentMethod,
        description: 'Subscription: ${plan.name}',
        metadata: {
          'planId': planId,
          'billingPeriod': plan.billingPeriod,
        },
      );

      if (transaction?.status == PaymentStatus.completed) {
        // Create subscription record
        await _firestore.collection('subscriptions').doc(userId).set({
          'planId': planId,
          'userId': userId,
          'startDate': FieldValue.serverTimestamp(),
          'endDate': _calculateEndDate(plan.billingPeriod),
          'status': 'active',
          'paymentMethod': paymentMethod.name,
        });

        AppLogger.success(_tag, 'Subscription created successfully');
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to subscribe', e, stackTrace);
      return false;
    }
  }

  /// Calculate subscription end date
  DateTime _calculateEndDate(String billingPeriod) {
    final now = DateTime.now();
    if (billingPeriod == 'yearly') {
      return DateTime(now.year + 1, now.month, now.day);
    }
    return DateTime(now.year, now.month + 1, now.day);
  }

  /// Cancel subscription
  Future<bool> cancelSubscription(String userId) async {
    try {
      AppLogger.info(_tag, 'Cancelling subscription', {
        'userId': userId,
      });

      await _firestore.collection('subscriptions').doc(userId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      AppLogger.success(_tag, 'Subscription cancelled');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cancel subscription', e, stackTrace);
      return false;
    }
  }

  /// Get user's payment history
  Future<List<PaymentTransaction>> getPaymentHistory(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('payment_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => PaymentTransaction.fromMap(doc.data()))
          .toList();
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get payment history', e, stackTrace);
      return [];
    }
  }

  /// Request refund
  Future<bool> requestRefund(String transactionId, String reason) async {
    try {
      AppLogger.info(_tag, 'Requesting refund', {
        'transactionId': transactionId,
      });

      await _firestore.collection('payment_transactions').doc(transactionId).update({
        'status': PaymentStatus.refunded.name,
        'refundReason': reason,
        'refundedAt': FieldValue.serverTimestamp(),
      });

      // In real implementation, process refund through payment gateway

      AppLogger.success(_tag, 'Refund requested');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to request refund', e, stackTrace);
      return false;
    }
  }
}
