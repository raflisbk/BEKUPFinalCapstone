import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/logger.dart';
import 'supabase_config.dart';

/// Supabase Database Service
/// Handles all database operations with Supabase PostgreSQL
class SupabaseDatabaseService {
  static const String _tag = 'SupabaseDatabaseService';
  static final SupabaseClient _client = SupabaseConfig.client;

  // ===============================
  // GENERIC DATABASE OPERATIONS
  // ===============================

  /// Generic select operation
  static Future<List<Map<String, dynamic>>> select({
    required String table,
    String columns = '*',
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
    int? limit,
    int? offset,
  }) async {
    try {
      AppLogger.debug(_tag, 'Selecting from table: $table');

      PostgrestFilterBuilder query = _client.from(table).select(columns);

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            query = query.eq(key, value);
          }
        });
      }

      PostgrestTransformBuilder finalQuery = query;

      // Apply ordering
      if (orderBy != null) {
        finalQuery = finalQuery.order(orderBy, ascending: ascending);
      }

      // Apply limit and offset
      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }
      if (offset != null) {
        finalQuery = finalQuery.range(offset, offset + (limit ?? 1000) - 1);
      }

      final data = await finalQuery;
      AppLogger.success(_tag, 'Selected ${data.length} records from $table');
      return data;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to select from $table', e, stackTrace);
      rethrow;
    }
  }

  /// Generic insert operation
  static Future<Map<String, dynamic>> insert({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      AppLogger.debug(_tag, 'Inserting into table: $table');

      // Add timestamps
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = DateTime.now().toIso8601String();

      final result = await _client
          .from(table)
          .insert(data)
          .select()
          .single();

      AppLogger.success(_tag, 'Inserted record into $table');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to insert into $table', e, stackTrace);
      rethrow;
    }
  }

  /// Generic update operation
  static Future<Map<String, dynamic>> update({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      AppLogger.debug(_tag, 'Updating record in table: $table');

      // Add updated timestamp
      data['updated_at'] = DateTime.now().toIso8601String();

      final result = await _client
          .from(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();

      AppLogger.success(_tag, 'Updated record in $table');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to update record in $table', e, stackTrace);
      rethrow;
    }
  }

  /// Generic delete operation
  static Future<void> delete({
    required String table,
    required String id,
  }) async {
    try {
      AppLogger.debug(_tag, 'Deleting record from table: $table');

      await _client
          .from(table)
          .delete()
          .eq('id', id);

      AppLogger.success(_tag, 'Deleted record from $table');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to delete record from $table', e, stackTrace);
      rethrow;
    }
  }

  /// Count records in table
  static Future<int> count({
    required String table,
    Map<String, dynamic>? filters,
  }) async {
    try {
      AppLogger.debug(_tag, 'Counting records in table: $table');

      PostgrestFilterBuilder query = _client.from(table).select('id');

      // Apply filters
      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            query = query.eq(key, value);
          }
        });
      }

      final response = await query;
      final count = response.length;
      
      AppLogger.success(_tag, 'Counted $count records in $table');
      return count;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to count records in $table', e, stackTrace);
      return 0;
    }
  }

  // ===============================
  // REAL-TIME SUBSCRIPTIONS
  // ===============================

  /// Subscribe to table changes
  static RealtimeChannel subscribeToTable({
    required String table,
    String? filter,
    required void Function(PostgresChangePayload payload) onInsert,
    required void Function(PostgresChangePayload payload) onUpdate,
    required void Function(PostgresChangePayload payload) onDelete,
  }) {
    AppLogger.info(_tag, 'Subscribing to real-time changes for table: $table');

    final channel = _client.channel('public:$table');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: table,
      callback: (payload) {
        AppLogger.debug(_tag, 'Real-time INSERT event for $table');
        onInsert(payload);
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: table,
      callback: (payload) {
        AppLogger.debug(_tag, 'Real-time UPDATE event for $table');
        onUpdate(payload);
      },
    );

    channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: table,
      callback: (payload) {
        AppLogger.debug(_tag, 'Real-time DELETE event for $table');
        onDelete(payload);
      },
    );

    channel.subscribe();
    return channel;
  }

  /// Unsubscribe from real-time channel
  static Future<void> unsubscribe(RealtimeChannel channel) async {
    try {
      AppLogger.debug(_tag, 'Unsubscribing from real-time channel');
      await _client.removeChannel(channel);
      AppLogger.success(_tag, 'Unsubscribed from real-time channel');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to unsubscribe from channel', e, stackTrace);
    }
  }

  // ===============================
  // ADVANCED QUERIES
  // ===============================

  /// Search across multiple columns
  static Future<List<Map<String, dynamic>>> textSearch({
    required String table,
    required String searchTerm,
    required List<String> searchColumns,
    int? limit,
  }) async {
    try {
      AppLogger.debug(_tag, 'Text search in table: $table');

      PostgrestFilterBuilder query = _client.from(table).select();

      // Build OR condition for multiple columns
      String orCondition = searchColumns
          .map((column) => '$column.ilike.%$searchTerm%')
          .join(',');

      PostgrestTransformBuilder finalQuery = query.or(orCondition);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final data = await finalQuery;
      AppLogger.success(_tag, 'Text search returned ${data.length} results');
      return data;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to perform text search', e, stackTrace);
      rethrow;
    }
  }

  /// Get records with pagination
  static Future<Map<String, dynamic>> getPaginated({
    required String table,
    required int page,
    required int pageSize,
    String columns = '*',
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = true,
  }) async {
    try {
      AppLogger.debug(_tag, 'Getting paginated data from table: $table (page $page)');

      final offset = (page - 1) * pageSize;

      // Get total count
      final totalCount = await count(table: table, filters: filters);

      // Get paginated data
      final data = await select(
        table: table,
        columns: columns,
        filters: filters,
        orderBy: orderBy,
        ascending: ascending,
        limit: pageSize,
        offset: offset,
      );

      final totalPages = (totalCount / pageSize).ceil();

      final result = {
        'data': data,
        'pagination': {
          'currentPage': page,
          'pageSize': pageSize,
          'totalCount': totalCount,
          'totalPages': totalPages,
          'hasNextPage': page < totalPages,
          'hasPreviousPage': page > 1,
        },
      };

      AppLogger.success(_tag, 'Retrieved paginated data: ${data.length} records');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to get paginated data', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // BATCH OPERATIONS
  // ===============================

  /// Batch insert multiple records
  static Future<List<Map<String, dynamic>>> batchInsert({
    required String table,
    required List<Map<String, dynamic>> dataList,
  }) async {
    try {
      AppLogger.debug(_tag, 'Batch inserting ${dataList.length} records into $table');

      // Add timestamps to all records
      final timestamp = DateTime.now().toIso8601String();
      final updatedDataList = dataList.map((data) {
        data['created_at'] = timestamp;
        data['updated_at'] = timestamp;
        return data;
      }).toList();

      final result = await _client
          .from(table)
          .insert(updatedDataList)
          .select();

      AppLogger.success(_tag, 'Batch inserted ${result.length} records into $table');
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to batch insert into $table', e, stackTrace);
      rethrow;
    }
  }

  /// Batch delete multiple records
  static Future<void> batchDelete({
    required String table,
    required List<String> ids,
  }) async {
    try {
      AppLogger.debug(_tag, 'Batch deleting ${ids.length} records from $table');

      await _client
          .from(table)
          .delete()
          .inFilter('id', ids);

      AppLogger.success(_tag, 'Batch deleted ${ids.length} records from $table');
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Failed to batch delete from $table', e, stackTrace);
      rethrow;
    }
  }

  // ===============================
  // CONNECTION UTILITIES
  // ===============================

  /// Check database connection
  static Future<bool> checkConnection() async {
    try {
      AppLogger.debug(_tag, 'Checking database connection...');
      
      await _client.from('users').select('id').limit(1);
      
      AppLogger.success(_tag, 'Database connection is healthy');
      return true;
    } catch (e) {
      AppLogger.error(_tag, 'Database connection failed', e);
      return false;
    }
  }

  /// Get database health status
  static Future<Map<String, dynamic>> getHealthStatus() async {
    try {
      final isConnected = await checkConnection();
      final currentUser = SupabaseConfig.currentUser;
      
      return {
        'connected': isConnected,
        'authenticated': currentUser != null,
        'userId': currentUser?.id,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'connected': false,
        'authenticated': false,
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
}