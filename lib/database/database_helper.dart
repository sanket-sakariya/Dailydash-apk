import 'package:sqflite/sqflite.dart';
import 'data_repository.dart';
import '../models/expense.dart';

class DatabaseHelper implements DataRepository {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('dailydash.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/$filePath';
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        date_time TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        payment_mode TEXT NOT NULL,
        is_income INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  @override
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', orderBy: 'date_time DESC');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  @override
  Future<List<Expense>> getExpensesByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'date_time >= ? AND date_time <= ?',
      whereArgs: [start.toIso8601String(), end.toIso8601String()],
      orderBy: 'date_time DESC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  @override
  Future<List<Expense>> getExpensesForMonth(int year, int month) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return getExpensesByDateRange(start, end);
  }

  @override
  Future<int> insertExpense(Expense expense) async {
    final db = await database;
    return await db.insert('expenses', expense.toMap());
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  @override
  Future<void> deleteExpense(int id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<double> getTotalSpentThisMonth() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String();
    final end = DateTime(
      now.year,
      now.month + 1,
      0,
      23,
      59,
      59,
    ).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0',
      [start, end],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  @override
  Future<double> getTotalSpentLastMonth() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 1, 1).toIso8601String();
    final end = DateTime(now.year, now.month, 0, 23, 59, 59).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0',
      [start, end],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0;
  }

  @override
  Future<Map<String, double>> getCategorySpending() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String();
    final end = DateTime(
      now.year,
      now.month + 1,
      0,
      23,
      59,
      59,
    ).toIso8601String();
    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0 GROUP BY category ORDER BY total DESC',
      [start, end],
    );
    final map = <String, double>{};
    for (final row in result) {
      map[row['category'] as String] = (row['total'] as num).toDouble();
    }
    return map;
  }

  @override
  Future<Map<String, double>> getWeeklySpending() async {
    final db = await database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final map = <String, double>{};

    for (int i = 0; i < 5; i++) {
      final start = weekStart.subtract(Duration(days: 7 * (4 - i)));
      final end = start.add(
        const Duration(days: 6, hours: 23, minutes: 59, seconds: 59),
      );
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0',
        [start.toIso8601String(), end.toIso8601String()],
      );
      map['W${i + 1}'] = (result.first['total'] as num?)?.toDouble() ?? 0;
    }
    return map;
  }

  @override
  Future<double> getAverageDailySpend() async {
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String();
    final end = DateTime(
      now.year,
      now.month + 1,
      0,
      23,
      59,
      59,
    ).toIso8601String();
    final result = await db.rawQuery(
      'SELECT COALESCE(AVG(daily_total), 0) as avg FROM (SELECT DATE(date_time) as day, SUM(amount) as daily_total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0 GROUP BY DATE(date_time))',
      [start, end],
    );
    return (result.first['avg'] as num?)?.toDouble() ?? 0;
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
    final db = await database;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1).toIso8601String();
    final end = DateTime(
      now.year,
      now.month + 1,
      0,
      23,
      59,
      59,
    ).toIso8601String();

    final incomeResult = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 1',
      [start, end],
    );
    final income = (incomeResult.first['total'] as num?)?.toDouble() ?? 0;
    final spent = await getTotalSpentThisMonth();
    return income - spent;
  }

  @override
  Future<double> getBudgetPercentage() async {
    final categorySpending = await getCategorySpending();
    final total = categorySpending.values.fold<double>(0, (sum, v) => sum + v);
    if (total == 0) return 0;
    return (categorySpending.length / 10 * 100).clamp(0, 100);
  }
}
