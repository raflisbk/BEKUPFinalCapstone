import 'package:flutter/material.dart';
import '../../services/sync/sync_queue_manager.dart';
import '../../services/sync/background_sync_service.dart';
import '../../core/utils/connectivity_service.dart';

/// Widget that displays sync status and allows manual sync trigger
class SyncStatusWidget extends StatefulWidget {
  final bool showLabel;
  final bool compact;
  
  const SyncStatusWidget({
    super.key,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  State<SyncStatusWidget> createState() => _SyncStatusWidgetState();
}

class _SyncStatusWidgetState extends State<SyncStatusWidget> {
  final SyncQueueManager _syncQueue = SyncQueueManager();
  final BackgroundSyncService _backgroundSync = BackgroundSyncService();
  final ConnectivityService _connectivity = ConnectivityService.instance;
  
  bool _isSyncing = false;
  int _pendingCount = 0;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _updateSyncStatus();
    
    // Listen to sync progress
    _syncQueue.syncProgress.listen((progress) {
      if (mounted) {
        setState(() {
          _isSyncing = progress.status == SyncStatus.syncing;
          _totalCount = progress.total ?? 0;
        });
      }
    });
  }

  Future<void> _updateSyncStatus() async {
    final count = _syncQueue.getPendingCount();
    if (mounted) {
      setState(() {
        _pendingCount = count;
      });
    }
  }

  Future<void> _triggerManualSync() async {
    if (_isSyncing || !_connectivity.isOnline) {
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      await _backgroundSync.syncNow(showNotification: false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync completed successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
        await _updateSyncStatus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildCompactView() {
    return InkWell(
      onTap: _triggerManualSync,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getSyncColor().withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _getSyncColor().withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isSyncing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_getSyncColor()),
                ),
              )
            else
              Icon(
                _getSyncIcon(),
                size: 16,
                color: _getSyncColor(),
              ),
            if (_pendingCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getSyncColor(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$_pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFullView() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _connectivity.isOnline ? _triggerManualSync : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getSyncColor().withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getSyncColor().withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (_isSyncing)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(_getSyncColor()),
                        value: _totalCount > 0 ? (_totalCount - _pendingCount) / _totalCount : null,
                      ),
                    )
                  else
                    Icon(
                      _getSyncIcon(),
                      color: _getSyncColor(),
                      size: 24,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getSyncStatusText(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _getSyncColor(),
                          ),
                        ),
                        if (widget.showLabel)
                          Text(
                            _getSyncDetailText(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_pendingCount > 0 && !_isSyncing)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _getSyncColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_pendingCount pending',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              if (_isSyncing && _totalCount > 0) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_totalCount - _pendingCount) / _totalCount,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(_getSyncColor()),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Syncing ${_totalCount - _pendingCount} of $_totalCount items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getSyncColor() {
    if (!_connectivity.isOnline) {
      return Colors.orange;
    }
    if (_isSyncing) {
      return Colors.blue;
    }
    if (_pendingCount > 0) {
      return Colors.amber;
    }
    return Colors.green;
  }

  IconData _getSyncIcon() {
    if (!_connectivity.isOnline) {
      return Icons.cloud_off;
    }
    if (_pendingCount > 0) {
      return Icons.cloud_upload;
    }
    return Icons.cloud_done;
  }

  String _getSyncStatusText() {
    if (!_connectivity.isOnline) {
      return 'Offline Mode';
    }
    if (_isSyncing) {
      return 'Syncing...';
    }
    if (_pendingCount > 0) {
      return 'Pending Sync';
    }
    return 'All Synced';
  }

  String _getSyncDetailText() {
    if (!_connectivity.isOnline) {
      return 'Changes will sync when online';
    }
    if (_isSyncing) {
      return 'Syncing your data';
    }
    if (_pendingCount > 0) {
      return 'Tap to sync now';
    }
    return 'Everything is up to date';
  }
}

/// Icon button variant for app bars
class SyncStatusIconButton extends StatelessWidget {
  const SyncStatusIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    final syncQueue = SyncQueueManager();
    
    return StreamBuilder<SyncProgress>(
      stream: syncQueue.syncProgress,
      builder: (context, snapshot) {
        final progress = snapshot.data;
        final isSyncing = progress?.status == SyncStatus.syncing;
        final pending = syncQueue.getPendingCount();

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                isSyncing ? Icons.sync : Icons.cloud_queue,
                color: pending > 0 ? Colors.orange : Colors.grey[700],
              ),
              onPressed: () => _showSyncDialog(context),
            ),
            if (pending > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    pending > 9 ? '9+' : '$pending',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showSyncDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Sync Status',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              const SyncStatusWidget(
                showLabel: true,
                compact: false,
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
