import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../main.dart' show repo;
import '../models/expense.dart';
import 'auth_service.dart';

/// Sync status states
enum SyncStatus {
  /// Idle, no sync in progress
  idle,

  /// Currently syncing
  syncing,

  /// Successfully synced
  synced,

  /// Offline, sync pending
  offline,

  /// Sync error occurred
  error,
}

/// Service for bi-directional sync between local SQLite and Supabase
///
/// Implements the Outbox Pattern:
/// 1. All writes go to SQLite first with isSynced=false
/// 2. Background sync pushes unsynced records to Supabase
/// 3. Pull phase fetches new/updated records from server
/// 4. Conflict resolution uses Last-Write-Wins
class SyncService {
  static final SyncService instance = SyncService._init();

  final _supabase = Supabase.instance.client;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _debounceTimer;
  bool _isSyncing = false;

  /// Current sync status
  final syncStatusNotifier = ValueNotifier<SyncStatus>(SyncStatus.idle);

  /// Number of pending sync items
  final pendingCountNotifier = ValueNotifier<int>(0);

  /// Whether device is online
  final isOnlineNotifier = ValueNotifier<bool>(true);

  /// Last sync error message
  final lastErrorNotifier = ValueNotifier<String?>(null);

  SyncService._init();

  /// Initialize the sync service
  void initialize() {
    // Listen to connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) {
      final wasOffline = !isOnlineNotifier.value;
      final isOnline =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);

      isOnlineNotifier.value = isOnline;

      if (isOnline) {
        syncStatusNotifier.value = SyncStatus.idle;
        // Trigger sync when coming back online
        if (wasOffline) {
          triggerSync();
        }
      } else {
        syncStatusNotifier.value = SyncStatus.offline;
      }
    });

    // Initial connectivity check
    _checkConnectivity();

    // Update pending count
    _updatePendingCount();
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    final isOnline =
        results.isNotEmpty && !results.contains(ConnectivityResult.none);
    isOnlineNotifier.value = isOnline;
    if (!isOnline) {
      syncStatusNotifier.value = SyncStatus.offline;
    }
  }

  Future<void> _updatePendingCount() async {
    try {
      final count = await repo.getPendingSyncCount();
      pendingCountNotifier.value = count;
    } catch (e) {
      debugPrint('Error updating pending count: $e');
    }
  }

  /// Trigger a debounced sync
  ///
  /// Call this after any CRUD operation. The actual sync will be
  /// debounced to avoid excessive network requests.
  void triggerSync() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _syncIfNeeded();
    });
  }

  Future<void> _syncIfNeeded() async {
    if (!isOnlineNotifier.value) {
      syncStatusNotifier.value = SyncStatus.offline;
      return;
    }

    if (!AuthService.instance.isAuthenticated) {
      return;
    }

    if (_isSyncing) {
      return;
    }

    await _performSync();
  }

  /// Perform a full sync (used after first login)
  Future<void> fullSync() async {
    if (!AuthService.instance.isAuthenticated) {
      return;
    }

    await _performSync(isFullSync: true);
  }

  Future<void> _performSync({bool isFullSync = false}) async {
    if (_isSyncing) return;
    _isSyncing = true;

    syncStatusNotifier.value = SyncStatus.syncing;
    lastErrorNotifier.value = null;

    try {
      // Push local changes to server
      await _pushChanges();

      // Pull remote changes
      await _pullChanges(isFullSync: isFullSync);

      // Update pending count
      await _updatePendingCount();

      syncStatusNotifier.value = pendingCountNotifier.value > 0
          ? SyncStatus.idle
          : SyncStatus.synced;
    } catch (e) {
      debugPrint('Sync error: $e');
      lastErrorNotifier.value = e.toString();
      syncStatusNotifier.value = SyncStatus.error;
    } finally {
      _isSyncing = false;
    }
  }

  /// Push Phase: Upload unsynced local records to Supabase
  Future<void> _pushChanges() async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) return;

    List<Expense> unsyncedExpenses;
    try {
      unsyncedExpenses = await repo.getUnsyncedExpenses();
    } catch (e) {
      debugPrint('Error getting unsynced expenses: $e');
      return;
    }

    if (unsyncedExpenses.isEmpty) return;

    debugPrint('Pushing ${unsyncedExpenses.length} unsynced expenses');

    final syncedIds = <String>[];

    for (final expense in unsyncedExpenses) {
      try {
        // Ensure user ID is set
        final expenseWithUserId = expense.userId.isEmpty
            ? expense.copyWith(userId: userId)
            : expense;

        // Upsert to Supabase (handles both insert and update)
        await _supabase
            .from('expenses')
            .upsert(expenseWithUserId.toJson(), onConflict: 'id');

        syncedIds.add(expense.id);
      } catch (e) {
        debugPrint('Error pushing expense ${expense.id}: $e');
        // Continue with other expenses even if one fails
      }
    }

    // Mark successfully synced expenses
    if (syncedIds.isNotEmpty) {
      try {
        await repo.markAsSynced(syncedIds);
        debugPrint('Marked ${syncedIds.length} expenses as synced');
      } catch (e) {
        debugPrint('Error marking as synced: $e');
      }
    }
  }

  /// Pull Phase: Fetch updated records from Supabase
  Future<void> _pullChanges({bool isFullSync = false}) async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) return;

    DateTime? lastPulledAt;
    try {
      lastPulledAt = isFullSync ? null : await repo.getLastPulledAt();
    } catch (e) {
      debugPrint('Error getting lastPulledAt: $e');
    }
    final pullTimestamp = DateTime.now().toUtc();

    debugPrint('Pulling changes since: $lastPulledAt (fullSync: $isFullSync)');

    try {
      // Build query
      var query = _supabase.from('expenses').select().eq('user_id', userId);

      // Only fetch changes since last pull (unless full sync)
      if (lastPulledAt != null) {
        query = query.gt(
          'last_modified',
          lastPulledAt.toUtc().toIso8601String(),
        );
      }

      final response = await query;
      final remoteExpenses = (response as List)
          .map((json) => Expense.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('Pulled ${remoteExpenses.length} expenses from server');

      // Apply remote changes with conflict resolution
      for (final remoteExpense in remoteExpenses) {
        try {
          await _applyRemoteChange(remoteExpense);
        } catch (e) {
          debugPrint('Error applying remote change ${remoteExpense.id}: $e');
        }
      }

      // Update last pulled timestamp
      try {
        await repo.setLastPulledAt(pullTimestamp);
      } catch (e) {
        debugPrint('Error setting lastPulledAt: $e');
      }
    } catch (e) {
      debugPrint('Error pulling changes: $e');
      // Don't rethrow - allow partial sync to complete
    }
  }

  /// Apply a remote change with Last-Write-Wins conflict resolution
  Future<void> _applyRemoteChange(Expense remoteExpense) async {
    if (remoteExpense.isDeleted) {
      // Remote deleted - hard delete locally
      await repo.hardDelete(remoteExpense.id);
      debugPrint('Hard deleted expense ${remoteExpense.id}');
      return;
    }

    final localExpense = await repo.getExpenseById(remoteExpense.id);

    if (localExpense == null) {
      // New from remote - insert
      await repo.upsertFromRemote(remoteExpense);
      debugPrint('Inserted new expense from remote: ${remoteExpense.id}');
      return;
    }

    // Conflict resolution: Last Write Wins
    if (remoteExpense.lastModified.isAfter(localExpense.lastModified)) {
      // Remote is newer - overwrite local
      await repo.upsertFromRemote(remoteExpense);
      debugPrint('Remote wins conflict for expense ${remoteExpense.id}');
    } else {
      // Local is newer - will be pushed in next sync
      debugPrint('Local wins conflict for expense ${remoteExpense.id}');
    }
  }

  /// Dispose resources (call only on app termination)
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _isSyncing = false;
    // Reset notifiers instead of disposing (service is singleton)
    syncStatusNotifier.value = SyncStatus.idle;
    pendingCountNotifier.value = 0;
    lastErrorNotifier.value = null;
  }
}
