/// Conflict resolution strategy for offline sync
enum ConflictStrategy {
  /// Local changes win (client-wins)
  localWins,
  
  /// Remote changes win (server-wins)
  remoteWins,
  
  /// Use timestamp - newer wins
  newerWins,
  
  /// Merge both changes (requires custom logic)
  merge,
}

/// Result of conflict resolution
class ConflictResolution<T> {
  final T data;
  final ConflictStrategy strategyUsed;
  final bool wasConflict;
  final String? reason;

  ConflictResolution({
    required this.data,
    required this.strategyUsed,
    required this.wasConflict,
    this.reason,
  });
}

/// Service for resolving sync conflicts between local and remote data
class ConflictResolver {
  static final ConflictResolver _instance = ConflictResolver._internal();
  factory ConflictResolver() => _instance;
  ConflictResolver._internal();

  /// Resolve conflict between local and remote data
  ConflictResolution<Map<String, dynamic>> resolve({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
    ConflictStrategy strategy = ConflictStrategy.newerWins,
  }) {
    try {
      // Check if there's actually a conflict
      if (_areEqual(localData, remoteData)) {
        return ConflictResolution(
          data: localData,
          strategyUsed: strategy,
          wasConflict: false,
          reason: 'No conflict - data is identical',
        );
      }

      switch (strategy) {
        case ConflictStrategy.localWins:
          return ConflictResolution(
            data: localData,
            strategyUsed: ConflictStrategy.localWins,
            wasConflict: true,
            reason: 'Local changes preserved (client-wins strategy)',
          );

        case ConflictStrategy.remoteWins:
          return ConflictResolution(
            data: remoteData,
            strategyUsed: ConflictStrategy.remoteWins,
            wasConflict: true,
            reason: 'Remote changes preserved (server-wins strategy)',
          );

        case ConflictStrategy.newerWins:
          return _resolveByTimestamp(localData, remoteData);

        case ConflictStrategy.merge:
          return _mergeData(localData, remoteData);
      }
    } catch (e) {
      print('Error resolving conflict: $e');
      // Default to remote wins on error
      return ConflictResolution(
        data: remoteData,
        strategyUsed: ConflictStrategy.remoteWins,
        wasConflict: true,
        reason: 'Error during resolution, defaulting to remote: $e',
      );
    }
  }

  /// Resolve by comparing timestamps
  ConflictResolution<Map<String, dynamic>> _resolveByTimestamp(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    try {
      final localUpdated = _getTimestamp(localData, 'updatedAt');
      final remoteUpdated = _getTimestamp(remoteData, 'updatedAt');

      if (localUpdated == null && remoteUpdated == null) {
        // No timestamps, use creation time
        final localCreated = _getTimestamp(localData, 'createdAt');
        final remoteCreated = _getTimestamp(remoteData, 'createdAt');

        if (localCreated != null && remoteCreated != null) {
          final useLocal = localCreated.isAfter(remoteCreated);
          return ConflictResolution(
            data: useLocal ? localData : remoteData,
            strategyUsed: ConflictStrategy.newerWins,
            wasConflict: true,
            reason: 'Resolved by createdAt: ${useLocal ? "local" : "remote"} is newer',
          );
        }

        // No timestamps at all, default to remote
        return ConflictResolution(
          data: remoteData,
          strategyUsed: ConflictStrategy.remoteWins,
          wasConflict: true,
          reason: 'No timestamps found, defaulting to remote',
        );
      }

      if (localUpdated == null) {
        return ConflictResolution(
          data: remoteData,
          strategyUsed: ConflictStrategy.newerWins,
          wasConflict: true,
          reason: 'Local has no updatedAt, using remote',
        );
      }

      if (remoteUpdated == null) {
        return ConflictResolution(
          data: localData,
          strategyUsed: ConflictStrategy.newerWins,
          wasConflict: true,
          reason: 'Remote has no updatedAt, using local',
        );
      }

      // Compare timestamps
      final useLocal = localUpdated.isAfter(remoteUpdated);
      return ConflictResolution(
        data: useLocal ? localData : remoteData,
        strategyUsed: ConflictStrategy.newerWins,
        wasConflict: true,
        reason: 'Resolved by updatedAt: ${useLocal ? "local" : "remote"} is newer '
                '(${useLocal ? localUpdated : remoteUpdated})',
      );
    } catch (e) {
      print('Error in timestamp resolution: $e');
      return ConflictResolution(
        data: remoteData,
        strategyUsed: ConflictStrategy.remoteWins,
        wasConflict: true,
        reason: 'Error parsing timestamps, defaulting to remote: $e',
      );
    }
  }

  /// Merge local and remote data (simple field-level merge)
  ConflictResolution<Map<String, dynamic>> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    try {
      final merged = Map<String, dynamic>.from(remoteData);

      // For each field in local data
      for (final key in localData.keys) {
        if (!remoteData.containsKey(key)) {
          // Field only exists locally, keep it
          merged[key] = localData[key];
        } else {
          // Field exists in both, compare timestamps for this field
          final localValue = localData[key];
          final remoteValue = remoteData[key];

          if (localValue == remoteValue) continue;

          // For nested maps, recursively merge
          if (localValue is Map && remoteValue is Map) {
            merged[key] = _mergeData(
              Map<String, dynamic>.from(localValue),
              Map<String, dynamic>.from(remoteValue),
            ).data;
          } else {
            // For other types, use timestamp to decide
            final localUpdated = _getTimestamp(localData, 'updatedAt');
            final remoteUpdated = _getTimestamp(remoteData, 'updatedAt');

            if (localUpdated != null && remoteUpdated != null) {
              merged[key] = localUpdated.isAfter(remoteUpdated) 
                  ? localValue 
                  : remoteValue;
            } else {
              // Default to remote if no timestamps
              merged[key] = remoteValue;
            }
          }
        }
      }

      return ConflictResolution(
        data: merged,
        strategyUsed: ConflictStrategy.merge,
        wasConflict: true,
        reason: 'Data merged field-by-field',
      );
    } catch (e) {
      print('Error merging data: $e');
      return ConflictResolution(
        data: remoteData,
        strategyUsed: ConflictStrategy.remoteWins,
        wasConflict: true,
        reason: 'Error during merge, defaulting to remote: $e',
      );
    }
  }

  /// Extract timestamp from data
  DateTime? _getTimestamp(Map<String, dynamic> data, String field) {
    try {
      final value = data[field];
      if (value == null) return null;

      if (value is DateTime) {
        return value;
      } else if (value is String) {
        return DateTime.parse(value);
      } else if (value is int) {
        // Assume milliseconds since epoch
        return DateTime.fromMillisecondsSinceEpoch(value);
      }

      return null;
    } catch (e) {
      print('Error parsing timestamp from $field: $e');
      return null;
    }
  }

  /// Check if two data maps are equal (deep comparison)
  bool _areEqual(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;

    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;

      final aValue = a[key];
      final bValue = b[key];

      if (aValue is Map && bValue is Map) {
        if (!_areEqual(
          Map<String, dynamic>.from(aValue),
          Map<String, dynamic>.from(bValue),
        )) {
          return false;
        }
      } else if (aValue is List && bValue is List) {
        if (aValue.length != bValue.length) return false;
        for (int i = 0; i < aValue.length; i++) {
          if (aValue[i] != bValue[i]) return false;
        }
      } else if (aValue != bValue) {
        return false;
      }
    }

    return true;
  }

  /// Get conflict resolution strategy based on entity type
  ConflictStrategy getStrategyForEntity(String entityType) {
    switch (entityType) {
      case 'trip':
      case 'review':
        // User-generated content - prefer newer
        return ConflictStrategy.newerWins;
      
      case 'destination':
        // Shared data - prefer remote (admin-managed)
        return ConflictStrategy.remoteWins;
      
      case 'profile':
        // User profile - prefer local changes
        return ConflictStrategy.localWins;
      
      default:
        return ConflictStrategy.newerWins;
    }
  }
}
