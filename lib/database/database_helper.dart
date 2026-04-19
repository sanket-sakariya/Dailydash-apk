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
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id TEXT,
        user_id TEXT,
        amount REAL NOT NULL,
        date_time TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        payment_mode TEXT NOT NULL,
        is_income INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// Migrates existing v1 installations to the v2 schema (Supabase sync
  /// columns). Existing rows are flagged unsynced so the next sync push will
  /// upload them once the user signs in.
  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE expenses ADD COLUMN remote_id TEXT');
      await db.execute('ALTER TABLE expenses ADD COLUMN user_id TEXT');
      await db.execute(
        'ALTER TABLE expenses ADD COLUMN is_synced INTEGER DEFAULT 0',
      );
      await db.execute(
        "ALTER TABLE expenses ADD COLUMN updated_at TEXT NOT NULL DEFAULT '1970-01-01T00:00:00.000Z'",
      );
    }
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

  /// Returns all locally-modified rows that have not yet been pushed to
  /// Supabase. Used by [SyncService] / [HybridRepository] during push.
  Future<List<Expense>> getUnsyncedExpenses() async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'is_synced = 0',
      orderBy: 'updated_at ASC',
    );
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  /// Marks a single local row as synced and stores the assigned remote UUID.
  Future<void> markSynced(int localId, String remoteId) async {
    final db = await database;
    await db.update(
      'expenses',
      {'is_synced': 1, 'remote_id': remoteId},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }

  /// Inserts or updates a row coming from Supabase (matched by `remote_id`).
  /// The merged row is always flagged as synced.
  Future<void> upsertFromRemote(Expense remote) async {
    if (remote.remoteId == null) return;
    final db = await database;
    final existing = await db.query(
      'expenses',
      where: 'remote_id = ?',
      whereArgs: [remote.remoteId],
      limit: 1,
    );
    final values = remote.copyWith(isSynced: true).toMap()..remove('id');
    if (existing.isEmpty) {
      await db.insert('expenses', values);
    } else {
      await db.update(
        'expenses',
        values,
        where: 'remote_id = ?',
        whereArgs: [remote.remoteId],
      );
    }
  }

  /// Clears all user-owned data. Called on sign-out so the next user does not
  /// inherit cached rows.
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('expenses');
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
  Future<Map<String, double>> getDailySpending() async {
    final db = await database;
    final now = DateTime.now();
    final map = <String, double>{};
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0',
        [start.toIso8601String(), end.toIso8601String()],
      );
      map[dayNames[day.weekday - 1]] = (result.first['total'] as num?)?.toDouble() ?? 0;
    }
    return map;
  }

  @override
  Future<Map<String, double>> getMonthlySpending() async {
    final db = await database;
    final now = DateTime.now();
    final map = <String, double>{};
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (int i = 11; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final start = DateTime(month.year, month.month, 1);
      final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0',
        [start.toIso8601String(), end.toIso8601String()],
      );
      map[monthNames[month.month - 1]] = (result.first['total'] as num?)?.toDouble() ?? 0;
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
