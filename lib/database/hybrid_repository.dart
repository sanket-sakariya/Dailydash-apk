import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';
import 'data_repository.dart';
import 'database_helper.dart';

/// Local-first [DataRepository] that transparently mirrors writes to Supabase.
///
/// **Reads** are always served from SQLite — the local DB is the single source
/// of truth for the UI, so the app remains snappy and works fully offline.
///
/// **Writes** are also always committed to SQLite first (with `is_synced = false`)
/// and then a best-effort push to Supabase is fired in the background. If the
/// remote write fails (offline, timeout, server error) the row stays flagged
/// for retry by [SyncService] on the next connectivity / app-resume event.
class HybridRepository implements DataRepository {
  HybridRepository._();
  static final HybridRepository instance = HybridRepository._();

  final DatabaseHelper _local = DatabaseHelper.instance;

  // ---------------------------------------------------------------------------
  // Reads — delegated straight to the local cache.
  // ---------------------------------------------------------------------------

  @override
  Future<List<Expense>> getAllExpenses() => _local.getAllExpenses();

  @override
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end) =>
      _local.getExpensesByDateRange(start, end);

  @override
  Future<List<Expense>> getExpensesForMonth(int year, int month) =>
      _local.getExpensesForMonth(year, month);

  @override
  Future<double> getTotalSpentThisMonth() => _local.getTotalSpentThisMonth();

  @override
  Future<double> getTotalSpentLastMonth() => _local.getTotalSpentLastMonth();

  @override
  Future<Map<String, double>> getCategorySpending() =>
      _local.getCategorySpending();

  @override
  Future<Map<String, double>> getWeeklySpending() => _local.getWeeklySpending();

  @override
  Future<Map<String, double>> getDailySpending() => _local.getDailySpending();

  @override
  Future<Map<String, double>> getMonthlySpending() =>
      _local.getMonthlySpending();

  @override
  Future<double> getAverageDailySpend() => _local.getAverageDailySpend();

  @override
  Future<String> getHighestCategory() => _local.getHighestCategory();

  @override
  Future<double> getSavings() => _local.getSavings();

  @override
  Future<double> getBudgetPercentage() => _local.getBudgetPercentage();

  // ---------------------------------------------------------------------------
  // Writes — local-first, then best-effort remote sync.
  // ---------------------------------------------------------------------------

  @override
  Future<int> insertExpense(Expense expense) async {
    final stamped = expense.copyWith(
      userId: expense.userId ?? AuthService.instance.currentUser?.id,
      isSynced: false,
      updatedAt: DateTime.now().toUtc(),
    );
    final localId = await _local.insertExpense(stamped);
    _scheduleSync();
    return localId;
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final stamped = expense.copyWith(
      userId: expense.userId ?? AuthService.instance.currentUser?.id,
      isSynced: false,
      updatedAt: DateTime.now().toUtc(),
    );
    await _local.updateExpense(stamped);
    _scheduleSync();
  }

  @override
  Future<void> deleteExpense(int id) async {
    // NOTE: For a full implementation, hard deletes should also be tombstoned
    // in a `deletions` table so the SyncService can replay them remotely. This
    // scaffolding deletes locally and triggers a sync; remote delete handling
    // can be layered in once the tombstone table is added.
    await _local.deleteExpense(id);
    _scheduleSync();
  }

  /// Triggers a non-blocking sync. Errors are swallowed here — the
  /// [SyncService] surfaces them through its [statusNotifier].
  void _scheduleSync() {
    unawaited(
      SyncService.instance.syncNow().catchError(
        (Object e, StackTrace s) => debugPrint('HybridRepository sync: $e'),
      ),
    );
  }
}
