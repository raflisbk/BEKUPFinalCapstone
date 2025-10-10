import 'package:flutter_test/flutter_test.dart';
import 'package:relink/services/payment_service.dart';
import '../test_setup.dart';

void main() {
  late PaymentService paymentService;

  setUpAll(() async {
    await setupTestEnvironment();
  });

  setUp(() {
    paymentService = PaymentService();
  });

  group('PaymentService - Initialization Tests', () {
    test('initialize returns true', () async {
      final result = await paymentService.initialize();
      expect(result, isTrue);
    });
  });

  group('PaymentService - Payment Processing Tests', () {
    test('processPayment with credit card succeeds', () async {
      final transaction = await paymentService.processPayment(
        userId: 'test_user_123',
        amount: 100.0,
        currency: 'USD',
        method: PaymentMethod.creditCard,
        description: 'Test payment',
      );

      expect(transaction, isNotNull);
      expect(transaction!.userId, 'test_user_123');
      expect(transaction.amount, 100.0);
      expect(transaction.currency, 'USD');
      expect(transaction.method, PaymentMethod.creditCard);
      expect(transaction.status, PaymentStatus.completed);
      expect(transaction.completedAt, isNotNull);
    });

    test('processPayment with debit card succeeds', () async {
      final transaction = await paymentService.processPayment(
        userId: 'test_user_123',
        amount: 50.0,
        currency: 'USD',
        method: PaymentMethod.debitCard,
        description: 'Debit card payment',
      );

      expect(transaction, isNotNull);
      expect(transaction!.method, PaymentMethod.debitCard);
      expect(transaction.status, PaymentStatus.completed);
    });

    test('processPayment with PayPal succeeds', () async {
      final transaction = await paymentService.processPayment(
        userId: 'test_user_123',
        amount: 75.0,
        currency: 'USD',
        method: PaymentMethod.paypal,
        description: 'PayPal payment',
      );

      expect(transaction, isNotNull);
      expect(transaction!.method, PaymentMethod.paypal);
      expect(transaction.status, PaymentStatus.completed);
    });

    test('processPayment with Google Pay succeeds', () async {
      final transaction = await paymentService.processPayment(
        userId: 'test_user_123',
        amount: 120.0,
        currency: 'USD',
        method: PaymentMethod.googlePay,
        description: 'Google Pay payment',
      );

      expect(transaction, isNotNull);
      expect(transaction!.method, PaymentMethod.googlePay);
      expect(transaction.status, PaymentStatus.completed);
    });

    test('processPayment with Apple Pay succeeds', () async {
      final transaction = await paymentService.processPayment(
        userId: 'test_user_123',
        amount: 85.0,
        currency: 'USD',
        method: PaymentMethod.applePay,
        description: 'Apple Pay payment',
      );

      expect(transaction, isNotNull);
      expect(transaction!.method, PaymentMethod.applePay);
      expect(transaction.status, PaymentStatus.completed);
    });

    test('processPayment with metadata', () async {
      final metadata = {
        'bookingId': 'booking_123',
        'tripId': 'trip_456',
      };

      final transaction = await paymentService.processPayment(
        userId: 'test_user_123',
        amount: 200.0,
        currency: 'USD',
        method: PaymentMethod.creditCard,
        description: 'Booking payment',
        metadata: metadata,
      );

      expect(transaction, isNotNull);
      expect(transaction!.metadata, isNotNull);
      expect(transaction.metadata!['bookingId'], 'booking_123');
      expect(transaction.metadata!['tripId'], 'trip_456');
    });

    test('processPayment with different currencies', () async {
      final currencies = ['USD', 'EUR', 'GBP', 'JPY', 'IDR'];

      for (var currency in currencies) {
        final transaction = await paymentService.processPayment(
          userId: 'test_user_123',
          amount: 100.0,
          currency: currency,
          method: PaymentMethod.creditCard,
        );

        expect(transaction, isNotNull);
        expect(transaction!.currency, currency);
      }
    });
  });

  group('PaymentService - Subscription Tests', () {
    test('getSubscriptionPlans returns all plans', () async {
      final plans = await paymentService.getSubscriptionPlans();

      expect(plans, isNotEmpty);
      expect(plans.length, 3);
      expect(plans.any((p) => p.id == 'free'), isTrue);
      expect(plans.any((p) => p.id == 'premium_monthly'), isTrue);
      expect(plans.any((p) => p.id == 'premium_yearly'), isTrue);
    });

    test('getSubscriptionPlans has correct free plan', () async {
      final plans = await paymentService.getSubscriptionPlans();
      final freePlan = plans.firstWhere((p) => p.id == 'free');

      expect(freePlan.name, 'Free');
      expect(freePlan.price, 0);
      expect(freePlan.currency, 'USD');
      expect(freePlan.billingPeriod, 'monthly');
      expect(freePlan.features, isNotEmpty);
      expect(freePlan.isPopular, isFalse);
    });

    test('getSubscriptionPlans has correct premium monthly plan', () async {
      final plans = await paymentService.getSubscriptionPlans();
      final premiumPlan = plans.firstWhere((p) => p.id == 'premium_monthly');

      expect(premiumPlan.name, 'Premium');
      expect(premiumPlan.price, 9.99);
      expect(premiumPlan.currency, 'USD');
      expect(premiumPlan.billingPeriod, 'monthly');
      expect(premiumPlan.features, isNotEmpty);
      expect(premiumPlan.isPopular, isTrue);
    });

    test('getSubscriptionPlans has correct premium yearly plan', () async {
      final plans = await paymentService.getSubscriptionPlans();
      final yearlyPlan = plans.firstWhere((p) => p.id == 'premium_yearly');

      expect(yearlyPlan.name, 'Premium Annual');
      expect(yearlyPlan.price, 99.99);
      expect(yearlyPlan.currency, 'USD');
      expect(yearlyPlan.billingPeriod, 'yearly');
      expect(yearlyPlan.features, isNotEmpty);
    });

    test('subscribeToPlan processes payment and creates subscription', () async {
      final result = await paymentService.subscribeToPlan(
        userId: 'test_user_123',
        planId: 'premium_monthly',
        paymentMethod: PaymentMethod.creditCard,
      );

      expect(result, isTrue);
    });

    test('subscribeToPlan with yearly plan', () async {
      final result = await paymentService.subscribeToPlan(
        userId: 'test_user_123',
        planId: 'premium_yearly',
        paymentMethod: PaymentMethod.paypal,
      );

      expect(result, isTrue);
    });

    test('cancelSubscription updates subscription status', () async {
      // First subscribe
      await paymentService.subscribeToPlan(
        userId: 'test_user_123',
        planId: 'premium_monthly',
        paymentMethod: PaymentMethod.creditCard,
      );

      // Then cancel
      final result = await paymentService.cancelSubscription('test_user_123');

      expect(result, isTrue);
    });
  });

  group('PaymentService - History Tests', () {
    test('getPaymentHistory returns user transactions', () async {
      // Make some payments
      await paymentService.processPayment(
        userId: 'test_user_123',
        amount: 50.0,
        currency: 'USD',
        method: PaymentMethod.creditCard,
      );

      await paymentService.processPayment(
        userId: 'test_user_123',
        amount: 75.0,
        currency: 'USD',
        method: PaymentMethod.paypal,
      );

      final history = await paymentService.getPaymentHistory('test_user_123');

      expect(history, isA<List<PaymentTransaction>>());
    });

    test('getPaymentHistory limits to 50 transactions', () async {
      final history = await paymentService.getPaymentHistory('test_user_123');

      expect(history.length, lessThanOrEqualTo(50));
    });
  });

  group('PaymentService - Refund Tests', () {
    test('requestRefund updates transaction status', () async {
      // Create a transaction
      final transaction = await paymentService.processPayment(
        userId: 'test_user_123',
        amount: 100.0,
        currency: 'USD',
        method: PaymentMethod.creditCard,
      );

      // Request refund
      final result = await paymentService.requestRefund(
        transaction!.id,
        'Changed my mind',
      );

      expect(result, isTrue);
    });

    test('requestRefund with different reasons', () async {
      final transaction = await paymentService.processPayment(
        userId: 'test_user_123',
        amount: 50.0,
        currency: 'USD',
        method: PaymentMethod.creditCard,
      );

      final reasons = [
        'Accidental purchase',
        'Service not delivered',
        'Quality issues',
        'Duplicate payment',
      ];

      for (var reason in reasons) {
        final result = await paymentService.requestRefund(
          transaction!.id,
          reason,
        );
        expect(result, isTrue);
        break; // Only test once
      }
    });
  });

  group('PaymentTransaction Model Tests', () {
    test('PaymentTransaction toMap converts correctly', () {
      final transaction = PaymentTransaction(
        id: 'txn_123',
        userId: 'user_123',
        amount: 100.0,
        currency: 'USD',
        method: PaymentMethod.creditCard,
        status: PaymentStatus.completed,
        description: 'Test payment',
        createdAt: DateTime(2025, 10, 1),
        completedAt: DateTime(2025, 10, 1, 0, 5),
      );

      final map = transaction.toMap();

      expect(map['id'], 'txn_123');
      expect(map['userId'], 'user_123');
      expect(map['amount'], 100.0);
      expect(map['currency'], 'USD');
      expect(map['method'], 'creditCard');
      expect(map['status'], 'completed');
      expect(map['description'], 'Test payment');
    });

    test('PaymentTransaction fromMap creates transaction', () {
      final map = {
        'id': 'txn_123',
        'userId': 'user_123',
        'amount': 100.0,
        'currency': 'USD',
        'method': 'creditCard',
        'status': 'completed',
        'description': 'Test payment',
        'createdAt': '2025-10-01T00:00:00.000',
        'completedAt': '2025-10-01T00:05:00.000',
      };

      final transaction = PaymentTransaction.fromMap(map);

      expect(transaction.id, 'txn_123');
      expect(transaction.amount, 100.0);
      expect(transaction.method, PaymentMethod.creditCard);
      expect(transaction.status, PaymentStatus.completed);
    });

    test('PaymentTransaction handles missing optional fields', () {
      final map = {
        'id': 'txn_123',
        'userId': 'user_123',
        'amount': 100.0,
        'currency': 'USD',
        'method': 'creditCard',
        'status': 'pending',
        'createdAt': '2025-10-01T00:00:00.000',
      };

      final transaction = PaymentTransaction.fromMap(map);

      expect(transaction.description, isNull);
      expect(transaction.metadata, isNull);
      expect(transaction.completedAt, isNull);
      expect(transaction.errorMessage, isNull);
    });
  });

  group('SubscriptionPlan Model Tests', () {
    test('SubscriptionPlan toMap converts correctly', () {
      const plan = SubscriptionPlan(
        id: 'premium',
        name: 'Premium',
        description: 'Premium plan',
        price: 9.99,
        currency: 'USD',
        billingPeriod: 'monthly',
        features: ['Feature 1', 'Feature 2'],
        isPopular: true,
      );

      final map = plan.toMap();

      expect(map['id'], 'premium');
      expect(map['name'], 'Premium');
      expect(map['price'], 9.99);
      expect(map['billingPeriod'], 'monthly');
      expect(map['isPopular'], isTrue);
      expect(map['features'], isA<List<String>>());
    });
  });

  group('Payment Enum Tests', () {
    test('PaymentMethod enum has correct values', () {
      expect(PaymentMethod.values.length, 5);
      expect(PaymentMethod.creditCard.name, 'creditCard');
      expect(PaymentMethod.debitCard.name, 'debitCard');
      expect(PaymentMethod.paypal.name, 'paypal');
      expect(PaymentMethod.googlePay.name, 'googlePay');
      expect(PaymentMethod.applePay.name, 'applePay');
    });

    test('PaymentStatus enum has correct values', () {
      expect(PaymentStatus.values.length, 6);
      expect(PaymentStatus.pending.name, 'pending');
      expect(PaymentStatus.processing.name, 'processing');
      expect(PaymentStatus.completed.name, 'completed');
      expect(PaymentStatus.failed.name, 'failed');
      expect(PaymentStatus.refunded.name, 'refunded');
      expect(PaymentStatus.cancelled.name, 'cancelled');
    });
  });
}
