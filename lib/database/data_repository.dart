import '../models/expense.dart';

abstract class DataRepository {
  // Core CRUD operations
  Future<List<Expense>> getAllExpenses();
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end);
  Future<List<Expense>> getExpensesForMonth(int year, int month);
  Future<Expense?> getExpenseById(String id);
  Future<String> insertExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(String id);

  // Analytics operations
  Future<double> getTotalSpentThisMonth();
  Future<double> getTotalSpentLastMonth();
  Future<Map<String, double>> getCategorySpending();
  Future<Map<String, double>> getWeeklySpending();
  Future<Map<String, double>> getDailySpending();
  Future<Map<String, double>> getMonthlySpending();
  Future<double> getAverageDailySpend();
  Future<String> getHighestCategory();
  Future<double> getSavings();
  Future<double> getBudgetPercentage();

  // Sync operations (default implementations for non-syncing repos)
  Future<DateTime?> getLastPulledAt() async => null;
  Future<void> setLastPulledAt(DateTime timestamp) async {}
  Future<List<Expense>> getUnsyncedExpenses() async => [];
  Future<void> markAsSynced(List<String> ids) async {}
  Future<void> upsertFromRemote(Expense expense) async {}
  Future<void> hardDelete(String id) async {}
  Future<void> clearAllData() async {}
  Future<void> assignUserIdToOrphans(String userId) async {}
  Future<int> getPendingSyncCount() async => 0;
}
