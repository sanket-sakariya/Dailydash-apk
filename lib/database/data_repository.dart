import '../models/expense.dart';

abstract class DataRepository {
  Future<List<Expense>> getAllExpenses();
  Future<List<Expense>> getExpensesByDateRange(DateTime start, DateTime end);
  Future<List<Expense>> getExpensesForMonth(int year, int month);
  Future<int> insertExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<void> deleteExpense(int id);
  Future<double> getTotalSpentThisMonth();
  Future<double> getTotalSpentLastMonth();
  Future<Map<String, double>> getCategorySpending();
  Future<Map<String, double>> getWeeklySpending();
  Future<double> getAverageDailySpend();
  Future<String> getHighestCategory();
  Future<double> getSavings();
  Future<double> getBudgetPercentage();
}
