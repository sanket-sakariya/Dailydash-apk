import 'package:uuid/uuid.dart';
import 'data_repository.dart';
import '../models/expense.dart';

const _uuid = Uuid();

class InMemoryRepository implements DataRepository {
  static final InMemoryRepository instance = InMemoryRepository._init();
  InMemoryRepository._init();

  final List<Expense> _expenses = [];

  // Seed with sample data
  void seedData() {
    if (_expenses.isNotEmpty) return;

    final now = DateTime.now();
    final sampleExpenses = [
      Expense(
        id: _uuid.v4(),
        amount: 84.20,
        dateTime: DateTime(now.year, now.month, now.day, 19, 22),
        description: 'Gourmet Bistro',
        category: 'Food',
        paymentMode: 'Credit Card',
      ),
      Expense(
        id: _uuid.v4(),
        amount: 1299.00,
        dateTime: DateTime(now.year, now.month, now.day, 14, 15),
        description: 'Apple Store',
        category: 'Shop',
        paymentMode: 'Credit Card',
      ),
      Expense(
        id: _uuid.v4(),
        amount: 42.00,
        dateTime: DateTime(now.year, now.month, now.day - 1, 23, 45),
        description: 'Uber Premium',
        category: 'Transport',
        paymentMode: 'Credit Card',
      ),
      Expense(
        id: _uuid.v4(),
        amount: 245.80,
        dateTime: DateTime(now.year, now.month, now.day - 1, 10, 0),
        description: 'Dividend Payout',
        category: 'Income',
        paymentMode: 'Bank Transfer',
        isIncome: true,
      ),
      Expense(
        id: _uuid.v4(),
        amount: 1498.00,
        dateTime: DateTime(now.year, now.month, now.day - 3, 12, 0),
        description: 'Monthly Rent',
        category: 'Housing',
        paymentMode: 'Bank Transfer',
      ),
      Expense(
        id: _uuid.v4(),
        amount: 856.00,
        dateTime: DateTime(now.year, now.month, now.day - 5, 9, 30),
        description: 'Groceries',
        category: 'Food',
        paymentMode: 'Debit Card',
      ),
      Expense(
        id: _uuid.v4(),
        amount: 350.00,
        dateTime: DateTime(now.year, now.month, now.day - 7, 16, 0),
        description: 'Gas Station',
        category: 'Transport',
        paymentMode: 'Debit Card',
      ),
      Expense(
        id: _uuid.v4(),
        amount: 120.00,
        dateTime: DateTime(now.year, now.month, now.day - 10, 20, 0),
        description: 'Electricity Bill',
        category: 'Bills',
        paymentMode: 'Bank Transfer',
      ),
    ];

    _expenses.addAll(sampleExpenses);
  }

  List<Expense> get _activeExpenses =>
      _expenses.where((e) => !e.isDeleted).toList();

  @override
  Future<List<Expense>> getAllExpenses() async {
    seedData();
    return List.from(_activeExpenses)
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    seedData();
    return _activeExpenses
        .where((e) => e.dateTime.isAfter(start) && e.dateTime.isBefore(end))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }

  @override
  Future<List<Expense>> getExpensesForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getExpensesByDateRange(start, end);
  }

  @override
  Future<Expense?> getExpenseById(String id) async {
    seedData();
    try {
      return _expenses.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String> insertExpense(Expense expense) async {
    seedData();
    final newExpense = expense.copyWith(
      lastModified: DateTime.now(),
      isSynced: false,
    );
    _expenses.add(newExpense);
    return newExpense.id;
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      _expenses[index] = expense.copyWith(
        lastModified: DateTime.now(),
        isSynced: false,
      );
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    // Soft delete for consistency with sync behavior
    final index = _expenses.indexWhere((e) => e.id == id);
    if (index != -1) {
      _expenses[index] = _expenses[index].markAsDeleted();
    }
  }

  @override
  Future<double> getTotalSpentThisMonth() async {
    seedData();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return _activeExpenses
        .where(
          (e) =>
              !e.isIncome &&
              e.dateTime.isAfter(start) &&
              e.dateTime.isBefore(end),
        )
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  @override
  Future<double> getTotalSpentLastMonth() async {
    seedData();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1);
    final end = DateTime(now.year, now.month, 0, 23, 59, 59);
    return _activeExpenses
        .where(
          (e) =>
              !e.isIncome &&
              e.dateTime.isAfter(start) &&
              e.dateTime.isBefore(end),
        )
        .fold<double>(0, (sum, e) => sum + e.amount);
  }

  @override
  Future<Map<String, double>> getCategorySpending() async {
    seedData();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final map = <String, double>{};
    for (final expense in _activeExpenses) {
      if (!expense.isIncome &&
          expense.dateTime.isAfter(start) &&
          expense.dateTime.isBefore(end)) {
        map[expense.category] = (map[expense.category] ?? 0) + expense.amount;
      }
    }
    return map;
  }

  @override
  Future<Map<String, double>> getWeeklySpending() async {
    seedData();
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final map = <String, double>{};

    for (int i = 0; i < 5; i++) {
      final start = weekStart.subtract(Duration(days: 7 * (4 - i)));
      final end = start.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      final total = _activeExpenses
          .where(
            (e) =>
                !e.isIncome &&
                e.dateTime.isAfter(start) &&
                e.dateTime.isBefore(end),
          )
          .fold<double>(0, (sum, e) => sum + e.amount);
      map['W${i + 1}'] = total;
    }
    return map;
  }

  @override
  Future<Map<String, double>> getDailySpending() async {
    seedData();
    final now = DateTime.now();
    final map = <String, double>{};
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
      final total = _activeExpenses
          .where(
            (e) =>
                !e.isIncome &&
                e.dateTime.isAfter(
                  start.subtract(const Duration(seconds: 1)),
                ) &&
                e.dateTime.isBefore(end.add(const Duration(seconds: 1))),
          )
          .fold<double>(0, (sum, e) => sum + e.amount);
      map[dayNames[day.weekday - 1]] = total;
    }
    return map;
  }

  @override
  Future<Map<String, double>> getMonthlySpending() async {
    seedData();
    final now = DateTime.now();
    final map = <String, double>{};
    final monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final total = _activeExpenses
          .where(
            (e) =>
                !e.isIncome &&
                e.dateTime.isAfter(
                  start.subtract(const Duration(seconds: 1)),
                ) &&
                e.dateTime.isBefore(end.add(const Duration(seconds: 1))),
          )
          .fold<double>(0, (sum, e) => sum + e.amount);
      map[monthNames[month.month - 1]] = total;
    }
    return map;
  }

  @override
  Future<double> getAverageDailySpend() async {
    seedData();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final dailyTotals = <String, double>{};
    for (final expense in _activeExpenses) {
      if (!expense.isIncome &&
          expense.dateTime.isAfter(start) &&
          expense.dateTime.isBefore(end)) {
        final day =
            '${expense.dateTime.year}-${expense.dateTime.month}-${expense.dateTime.day}';
        dailyTotals[day] = (dailyTotals[day] ?? 0) + expense.amount;
      }
    }

    if (dailyTotals.isEmpty) return 0;
    return dailyTotals.values.reduce((a, b) => a + b) / dailyTotals.length;
  }

  @override
  Future<String> getHighestCategory() async {
    final categorySpending = await getCategorySpending();
    if (categorySpending.isEmpty) return 'None';
    return categorySpending.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  @override
  Future<double> getSavings() async {
    seedData();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final income = _activeExpenses
        .where(
          (e) =>
              e.isIncome &&
              e.dateTime.isAfter(start) &&
              e.dateTime.isBefore(end),
        )
        .fold<double>(0, (sum, e) => sum + e.amount);

    final spent = await getTotalSpentThisMonth();
    return income - spent + 1240; // Add base savings
  }

  @override
  Future<double> getBudgetPercentage() async {
    final categorySpending = await getCategorySpending();
    if (categorySpending.isEmpty) return 0;
    return (categorySpending.length / 5 * 100).clamp(0, 100);
  }

  // Sync operations (no-op for in-memory repository)
  @override
  Future<void> clearAllData() async {
    _expenses.clear();
  }

  @override
  Future<DateTime?> getLastPulledAt() async => null;

  @override
  Future<void> setLastPulledAt(DateTime timestamp) async {}

  @override
  Future<List<Expense>> getUnsyncedExpenses() async => [];

  @override
  Future<void> markAsSynced(List<String> ids) async {}

  @override
  Future<void> upsertFromRemote(Expense expense) async {}

  @override
  Future<void> hardDelete(String id) async {
    _expenses.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> assignUserIdToOrphans(String userId) async {}

  @override
  Future<int> getPendingSyncCount() async => 0;
}
