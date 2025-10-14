import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../core/utils/logger.dart';

/// Supabase Database Service
/// 
/// FREE TIER BENEFITS:
/// - 500MB PostgreSQL database storage
/// - Unlimited API requests
/// - Real-time subscriptions
/// - Row Level Security (RLS)
/// - Full SQL support with relationships
/// - Automatic API generation
/// - Built-in caching
class SupabaseDatabaseService {
  static const String _tag = 'SupabaseDatabaseService';
  
  /// Create a document in a table
  static Future<SupabaseResponse<Map<String, dynamic>>> create({
    required String table,
    required Map<String, dynamic> data,
  }) async {
    try {
      AppLogger.info(_tag, 'Creating document in table: $table');
      
      final response = await SupabaseConfig.table(table)
          .insert(data)
          .select()
          .single();
      
      AppLogger.success(_tag, 'Document created successfully in $table');
      return SupabaseResponse.success(response);
    } on PostgrestException catch (e) {
      AppLogger.error(_tag, 'Database error during create: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during create', e, stackTrace);
      return SupabaseResponse.error('Create failed: $e');
    }
  }
  
  /// Get a single document by ID
  static Future<SupabaseResponse<Map<String, dynamic>?>> getById({
    required String table,
    required String id,
  }) async {
    try {
      AppLogger.info(_tag, 'Getting document from $table with ID: $id');
      
      final response = await SupabaseConfig.table(table)
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (response != null) {
        AppLogger.success(_tag, 'Document found in $table');
        return SupabaseResponse.success(response);
      } else {
        AppLogger.info(_tag, 'Document not found in $table');
        return SupabaseResponse.success(null);
      }
    } on PostgrestException catch (e) {
      AppLogger.error(_tag, 'Database error during get: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during get', e, stackTrace);
      return SupabaseResponse.error('Get failed: $e');
    }
  }
  
  /// Get multiple documents with optional filtering
  static Future<SupabaseResponse<List<Map<String, dynamic>>>> getMultiple({
    required String table,
    String? column,
    dynamic value,
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      AppLogger.info(_tag, 'Getting multiple documents from $table');
      
      PostgrestFilterBuilder<PostgrestList> query = SupabaseConfig.table(table).select();
      
      // Apply filter if provided
      if (column != null && value != null) {
        query = query.eq(column, value);
      }
      
      // Apply ordering and limit
      PostgrestTransformBuilder<PostgrestList> transformQuery = query;
      
      if (orderBy != null) {
        transformQuery = transformQuery.order(orderBy, ascending: ascending);
      }
      
      if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }
      
      final response = await transformQuery;
      
      AppLogger.success(_tag, 'Retrieved ${response.length} documents from $table');
      return SupabaseResponse.success(response);
    } on PostgrestException catch (e) {
      AppLogger.error(_tag, 'Database error during getMultiple: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during getMultiple', e, stackTrace);
      return SupabaseResponse.error('GetMultiple failed: $e');
    }
  }
  
  /// Update a document by ID
  static Future<SupabaseResponse<Map<String, dynamic>>> update({
    required String table,
    required String id,
    required Map<String, dynamic> data,
  }) async {
    try {
      AppLogger.info(_tag, 'Updating document in $table with ID: $id');
      
      final response = await SupabaseConfig.table(table)
          .update(data)
          .eq('id', id)
          .select()
          .single();
      
      AppLogger.success(_tag, 'Document updated successfully in $table');
      return SupabaseResponse.success(response);
    } on PostgrestException catch (e) {
      AppLogger.error(_tag, 'Database error during update: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during update', e, stackTrace);
      return SupabaseResponse.error('Update failed: $e');
    }
  }
  
  /// Delete a document by ID
  static Future<SupabaseResponse<void>> delete({
    required String table,
    required String id,
  }) async {
    try {
      AppLogger.info(_tag, 'Deleting document from $table with ID: $id');
      
      await SupabaseConfig.table(table)
          .delete()
          .eq('id', id);
      
      AppLogger.success(_tag, 'Document deleted successfully from $table');
      return SupabaseResponse.success(null);
    } on PostgrestException catch (e) {
      AppLogger.error(_tag, 'Database error during delete: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during delete', e, stackTrace);
      return SupabaseResponse.error('Delete failed: $e');
    }
  }
  
  /// Get documents for current user
  static Future<SupabaseResponse<List<Map<String, dynamic>>>> getUserDocuments({
    required String table,
    String userColumn = 'user_id',
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    final userId = SupabaseConfig.userId;
    if (userId == null) {
      return SupabaseResponse.error('User not authenticated');
    }
    
    return getMultiple(
      table: table,
      column: userColumn,
      value: userId,
      orderBy: orderBy,
      ascending: ascending,
      limit: limit,
    );
  }
  
  /// Real-time subscription to table changes
  static RealtimeChannel subscribeToTable({
    required String table,
    required void Function(PostgresChangePayload) onInsert,
    required void Function(PostgresChangePayload) onUpdate,
    required void Function(PostgresChangePayload) onDelete,
  }) {
    AppLogger.info(_tag, 'Setting up real-time subscription for $table');
    
    final channel = SupabaseConfig.channel('public:$table');
    
    channel
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: table,
        callback: onInsert,
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: table,
        callback: onUpdate,
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.delete,
        schema: 'public',
        table: table,
        callback: onDelete,
      )
      .subscribe();
    
    return channel;
  }
  
  /// Execute custom SQL query (for complex operations)
  static Future<SupabaseResponse<List<Map<String, dynamic>>>> executeQuery({
    required String query,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      AppLogger.info(_tag, 'Executing custom query');
      
      final response = await SupabaseConfig.client
          .rpc(query, params: parameters ?? {});
      
      AppLogger.success(_tag, 'Custom query executed successfully');
      return SupabaseResponse.success(List<Map<String, dynamic>>.from(response));
    } on PostgrestException catch (e) {
      AppLogger.error(_tag, 'Database error during custom query: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during custom query', e, stackTrace);
      return SupabaseResponse.error('Custom query failed: $e');
    }
  }
  
  /// Search documents with text search
  static Future<SupabaseResponse<List<Map<String, dynamic>>>> searchText({
    required String table,
    required String column,
    required String searchTerm,
    int? limit,
  }) async {
    try {
      AppLogger.info(_tag, 'Searching text in $table.$column for: $searchTerm');
      
      PostgrestFilterBuilder<PostgrestList> query = SupabaseConfig.table(table)
          .select()
          .textSearch(column, searchTerm);
      
      PostgrestTransformBuilder<PostgrestList> transformQuery = query;
      
      if (limit != null) {
        transformQuery = transformQuery.limit(limit);
      }
      
      final response = await transformQuery;
      
      AppLogger.success(_tag, 'Text search completed, found ${response.length} results');
      return SupabaseResponse.success(response);
    } on PostgrestException catch (e) {
      AppLogger.error(_tag, 'Database error during text search: ${e.message}');
      return SupabaseResponse.error(e.message);
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during text search', e, stackTrace);
      return SupabaseResponse.error('Text search failed: $e');
    }
  }
  
  /// Count documents in table (simplified implementation)
  static Future<SupabaseResponse<int>> count({
    required String table,
    String? column,
    dynamic value,
  }) async {
    try {
      AppLogger.info(_tag, 'Counting documents in $table');
      
      // Get all documents and count them (simple approach)
      final result = await getMultiple(
        table: table,
        column: column,
        value: value,
      );
      
      if (result.success && result.data != null) {
        final count = result.data!.length;
        AppLogger.success(_tag, 'Count completed: $count documents in $table');
        return SupabaseResponse.success(count);
      } else {
        return SupabaseResponse.error(result.error ?? 'Count failed');
      }
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Unexpected error during count', e, stackTrace);
      return SupabaseResponse.error('Count failed: $e');
    }
  }
}
