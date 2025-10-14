import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';

/// Service for handling payments and transactions - Supabase version
/// Note: This uses free payment processing alternatives
class PaymentService {
  static const String _tag = 'PaymentService';

  final SupabaseClient _supabase = Supabase.instance.client;

  // Table names
  static const String _transactionsTable = 'transactions';
  static const String _paymentMethodsTable = 'payment_methods';
  static const String _subscriptionsTable = 'subscriptions';

  /// Process payment (mock implementation)
  /// In production, integrate with free payment processors like Stripe, PayPal, or local providers
  Future<Map<String, dynamic>?> processPayment({
    required String userId,
    required double amount,
    required String currency,
    required String description,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      AppLogger.debug(_tag, 'Processing payment', {
        'userId': userId,
        'amount': amount,
        'currency': currency,
        'description': description,
      });

      // Mock payment processing - in production, integrate with actual payment gateway
      final transactionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final response = await _supabase
          .from(_transactionsTable)
          .insert({
            'id': transactionId,
            'user_id': userId,
            'amount': amount,
            'currency': currency,
            'description': description,
            'payment_method_id': paymentMethodId,
            'status': 'completed', // Mock successful payment
            'provider': 'mock_payment',
            'provider_transaction_id': 'mock_$transactionId',
            'metadata': metadata ?? {},
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      AppLogger.success(_tag, 'Payment processed successfully', {
        'transactionId': transactionId,
      });

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to process payment', e, stackTrace);
      return null;
    }
  }

  /// Get transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory({
    required String userId,
    int limit = 20,
    int offset = 0,
    String? status,
  }) async {
    try {
      AppLogger.debug(_tag, 'Fetching transaction history', {
        'userId': userId,
        'limit': limit,
        'offset': offset,
      });

      var query = _supabase
          .from(_transactionsTable)
          .select()
          .eq('user_id', userId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      AppLogger.success(_tag, 'Transaction history fetched', {
        'count': response.length,
      });

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch transaction history', e, stackTrace);
      return [];
    }
  }

  /// Get transaction by ID
  Future<Map<String, dynamic>?> getTransaction(String transactionId) async {
    try {
      final response = await _supabase
          .from(_transactionsTable)
          .select()
          .eq('id', transactionId)
          .maybeSingle();

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch transaction', e, stackTrace);
      return null;
    }
  }

  /// Add payment method
  Future<String?> addPaymentMethod({
    required String userId,
    required String type, // 'card', 'bank_account', 'wallet'
    required String provider, // 'visa', 'mastercard', 'paypal', etc.
    required Map<String, dynamic> details,
    bool isDefault = false,
  }) async {
    try {
      AppLogger.debug(_tag, 'Adding payment method', {
        'userId': userId,
        'type': type,
        'provider': provider,
      });

      final response = await _supabase
          .from(_paymentMethodsTable)
          .insert({
            'user_id': userId,
            'type': type,
            'provider': provider,
            'details': details,
            'is_default': isDefault,
            'is_verified': false, // Requires verification
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final paymentMethodId = response['id'] as String;

      AppLogger.success(_tag, 'Payment method added', {
        'paymentMethodId': paymentMethodId,
      });

      return paymentMethodId;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to add payment method', e, stackTrace);
      return null;
    }
  }

  /// Get user payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods(String userId) async {
    try {
      final response = await _supabase
          .from(_paymentMethodsTable)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch payment methods', e, stackTrace);
      return [];
    }
  }

  /// Remove payment method
  Future<bool> removePaymentMethod({
    required String paymentMethodId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from(_paymentMethodsTable)
          .delete()
          .eq('id', paymentMethodId)
          .eq('user_id', userId);

      AppLogger.success(_tag, 'Payment method removed');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to remove payment method', e, stackTrace);
      return false;
    }
  }

  /// Set default payment method
  Future<bool> setDefaultPaymentMethod({
    required String paymentMethodId,
    required String userId,
  }) async {
    try {
      // First, unset all current defaults
      await _supabase
          .from(_paymentMethodsTable)
          .update({'is_default': false})
          .eq('user_id', userId);

      // Set the new default
      await _supabase
          .from(_paymentMethodsTable)
          .update({'is_default': true})
          .eq('id', paymentMethodId)
          .eq('user_id', userId);

      AppLogger.success(_tag, 'Default payment method updated');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to set default payment method', e, stackTrace);
      return false;
    }
  }

  /// Create subscription (for premium features)
  /// Note: This is a mock implementation - integrate with actual subscription service
  Future<String?> createSubscription({
    required String userId,
    required String planId,
    required String planName,
    required double price,
    required String currency,
    required String interval, // 'monthly', 'yearly'
    String? paymentMethodId,
  }) async {
    try {
      AppLogger.debug(_tag, 'Creating subscription', {
        'userId': userId,
        'planId': planId,
        'price': price,
      });

      final response = await _supabase
          .from(_subscriptionsTable)
          .insert({
            'user_id': userId,
            'plan_id': planId,
            'plan_name': planName,
            'price': price,
            'currency': currency,
            'interval': interval,
            'payment_method_id': paymentMethodId,
            'status': 'active',
            'current_period_start': DateTime.now().toIso8601String(),
            'current_period_end': _calculatePeriodEnd(interval).toIso8601String(),
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();

      final subscriptionId = response['id'] as String;

      AppLogger.success(_tag, 'Subscription created', {
        'subscriptionId': subscriptionId,
      });

      return subscriptionId;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to create subscription', e, stackTrace);
      return null;
    }
  }

  /// Get user subscription
  Future<Map<String, dynamic>?> getUserSubscription(String userId) async {
    try {
      final response = await _supabase
          .from(_subscriptionsTable)
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      return response;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to fetch user subscription', e, stackTrace);
      return null;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription({
    required String subscriptionId,
    required String userId,
  }) async {
    try {
      await _supabase
          .from(_subscriptionsTable)
          .update({
            'status': 'canceled',
            'canceled_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', subscriptionId)
          .eq('user_id', userId);

      AppLogger.success(_tag, 'Subscription canceled');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to cancel subscription', e, stackTrace);
      return false;
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final subscription = await getUserSubscription(userId);
      return subscription != null;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to check subscription status', e, stackTrace);
      return false;
    }
  }

  /// Get revenue analytics (for admin)
  Future<Map<String, dynamic>> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final response = await _supabase.rpc('get_revenue_analytics', params: {
        'start_date': start.toIso8601String(),
        'end_date': end.toIso8601String(),
      });

      return response ?? {
        'total_revenue': 0.0,
        'transaction_count': 0,
        'average_transaction': 0.0,
        'daily_breakdown': [],
      };
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get revenue analytics', e, stackTrace);
      return {
        'total_revenue': 0.0,
        'transaction_count': 0,
        'average_transaction': 0.0,
        'daily_breakdown': [],
      };
    }
  }

  /// Refund transaction
  Future<bool> refundTransaction({
    required String transactionId,
    required double amount,
    required String reason,
  }) async {
    try {
      AppLogger.debug(_tag, 'Processing refund', {
        'transactionId': transactionId,
        'amount': amount,
        'reason': reason,
      });

      await _supabase
          .from(_transactionsTable)
          .update({
            'status': 'refunded',
            'refund_amount': amount,
            'refund_reason': reason,
            'refunded_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      AppLogger.success(_tag, 'Refund processed successfully');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to process refund', e, stackTrace);
      return false;
    }
  }

  // Private helper methods

  DateTime _calculatePeriodEnd(String interval) {
    final now = DateTime.now();
    switch (interval) {
      case 'monthly':
        return DateTime(now.year, now.month + 1, now.day);
      case 'yearly':
        return DateTime(now.year + 1, now.month, now.day);
      default:
        return DateTime(now.year, now.month + 1, now.day);
    }
  }
}
