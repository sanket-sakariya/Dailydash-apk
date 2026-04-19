import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../database/database_helper.dart';
import '../models/expense.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// High-level synchronization status surfaced in the UI (e.g. dashboard
/// cloud icon: green when [synced], amber when [pending] / [syncing], red
/// on [error], grey when [offline]).
enum SyncStatus { synced, pending, syncing, offline, error }

/// Background synchronization between the local SQLite cache and Supabase.
///
/// * **Push** – uploads any rows where `is_synced = false`.
/// * **Pull** – downloads rows updated since the last successful pull.
///
/// The service is connectivity-aware: it pauses while offline and resumes
/// automatically when the device comes back online.
class SyncService {
  SyncService._();
  static final SyncService instance = SyncService._();

  final ValueNotifier<SyncStatus> statusNotifier =
      ValueNotifier<SyncStatus>(SyncStatus.pending);

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _initialized = false;
  bool _syncing = false;
  DateTime? _lastPulledAt;

  void initialize() {
    if (_initialized) return;
    _initialized = true;

    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (online) {
        // Fire-and-forget: surface failures via the notifier.
        unawaited(syncNow());
      } else {
        statusNotifier.value = SyncStatus.offline;
      }
    });

    // Re-sync whenever the user changes (sign-in/out).
    AuthService.instance.currentUserNotifier.addListener(() {
      if (AuthService.instance.isSignedIn) {
        unawaited(syncNow());
      } else {
        statusNotifier.value = SyncStatus.pending;
      }
    });
  }

  /// Performs one push + pull cycle. Safe to invoke concurrently — repeated
  /// calls while a sync is in flight are coalesced.
  Future<void> syncNow() async {
    if (_syncing) return;
    if (!SupabaseService.instance.isReady) return;
    if (!AuthService.instance.isSignedIn) return;

    final results = await Connectivity().checkConnectivity();
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online) {
      statusNotifier.value = SyncStatus.offline;
      return;
    }

    _syncing = true;
    statusNotifier.value = SyncStatus.syncing;
    try {
      await _pull();
      await _push();
      statusNotifier.value = SyncStatus.synced;
    } on TimeoutException {
      statusNotifier.value = SyncStatus.error;
    } catch (e) {
      debugPrint('SyncService: sync failed → $e');
      statusNotifier.value = SyncStatus.error;
    } finally {
      _syncing = false;
    }
  }

  /// Pushes all locally modified rows to Supabase via upsert. The remote
  /// returns the canonical row (with its UUID) which we use to flip
  /// `is_synced = true` and persist the assigned `remote_id`.
  Future<void> _push() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final pending = await DatabaseHelper.instance.getUnsyncedExpenses();
    if (pending.isEmpty) return;

    for (final expense in pending) {
      final payload = expense.copyWith(userId: user.id).toSupabaseJson();
      try {
        final response = await SupabaseService.instance.expenses
            .upsert(payload)
            .select()
            .single()
            .timeout(const Duration(seconds: 15));

        final remoteId = response['id']?.toString();
        if (expense.id != null && remoteId != null) {
          await DatabaseHelper.instance.markSynced(expense.id!, remoteId);
        }
      } on TimeoutException {
        rethrow;
      } catch (e) {
        debugPrint('SyncService: failed to push expense ${expense.id}: $e');
        // Leave row unsynced; will retry on next cycle.
      }
    }
  }

  /// Pulls any rows updated since the last successful pull and merges them
  /// into the local cache.
  Future<void> _pull() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return;

    final query = SupabaseService.instance.expenses
        .select()
        .eq('user_id', user.id);

    final dynamic filtered = _lastPulledAt != null
        ? query.gte('last_updated', _lastPulledAt!.toUtc().toIso8601String())
        : query;

    final List<dynamic> rows = await filtered
        .order('last_updated', ascending: true)
        .timeout(const Duration(seconds: 15));

    for (final row in rows) {
      final remote = Expense.fromSupabaseJson(
        Map<String, dynamic>.from(row as Map),
      );
      await DatabaseHelper.instance.upsertFromRemote(remote);
    }

    _lastPulledAt = DateTime.now().toUtc();
  }

  void dispose() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
    _initialized = false;
  }
}
