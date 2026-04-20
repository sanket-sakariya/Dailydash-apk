import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'data_repository.dart';
import '../models/expense.dart';

const _uuid = Uuid();

class DatabaseHelper implements DataRepository {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  static const int _dbVersion = 2;

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
      version: _dbVersion,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        date_time TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        payment_mode TEXT NOT NULL,
        is_income INTEGER DEFAULT 0,
        user_id TEXT NOT NULL DEFAULT '',
        last_modified TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        is_deleted INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_log (
        id INTEGER PRIMARY KEY,
        last_pulled_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Create indices for sync performance
    await db.execute('CREATE INDEX idx_expenses_user_id ON expenses(user_id)');
    await db.execute(
      'CREATE INDEX idx_expenses_is_synced ON expenses(is_synced)',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_last_modified ON expenses(last_modified)',
    );
    await db.execute(
      'CREATE INDEX idx_expenses_is_deleted ON expenses(is_deleted)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from version 1 to version 2
      // Create new expenses table with sync fields
      await db.execute('''
        CREATE TABLE expenses_new (
          id TEXT PRIMARY KEY,
          amount REAL NOT NULL,
          date_time TEXT NOT NULL,
          description TEXT NOT NULL,
          category TEXT NOT NULL,
          payment_mode TEXT NOT NULL,
          is_income INTEGER DEFAULT 0,
          user_id TEXT NOT NULL DEFAULT '',
          last_modified TEXT NOT NULL,
          is_synced INTEGER DEFAULT 0,
          is_deleted INTEGER DEFAULT 0
        )
      ''');

      // Copy existing data with new UUID ids
      final now = DateTime.now().toIso8601String();
      final oldExpenses = await db.query('expenses');
      for (final row in oldExpenses) {
        await db.insert('expenses_new', {
          'id': _uuid.v4(),
          'amount': row['amount'],
          'date_time': row['date_time'],
          'description': row['description'],
          'category': row['category'],
          'payment_mode': row['payment_mode'],
          'is_income': row['is_income'] ?? 0,
          'user_id': '', // Will be assigned on first login
          'last_modified': now,
          'is_synced': 0, // Needs to be synced
          'is_deleted': 0,
        });
      }

      // Drop old table and rename new one
      await db.execute('DROP TABLE expenses');
      await db.execute('ALTER TABLE expenses_new RENAME TO expenses');

      // Create sync_log table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_log (
          id INTEGER PRIMARY KEY,
          last_pulled_at TEXT
        )
      ''');

      // Create indices
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON expenses(user_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_is_synced ON expenses(is_synced)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_last_modified ON expenses(last_modified)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_expenses_is_deleted ON expenses(is_deleted)',
      );
    }
  }

  // ============= Core CRUD Operations =============

  @override
  Future<List<Expense>> getAllExpenses() async {
    final db = await database;
    final maps = await db.query(
      'expenses',
      where: 'is_deleted = 0',
      orderBy: 'date_time DESC',
    );
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
      where: 'date_time >= ? AND date_time <= ? AND is_deleted = 0',
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
  Future<Expense?> getExpenseById(String id) async {
    final db = await database;
    final maps = await db.query('expenses', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Expense.fromMap(maps.first);
  }

  @override
  Future<String> insertExpense(Expense expense) async {
    final db = await database;
    final expenseToInsert = expense.copyWith(
      lastModified: DateTime.now(),
      isSynced: false,
    );
    await db.insert(
      'expenses',
      expenseToInsert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return expenseToInsert.id;
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    final db = await database;
    final expenseToUpdate = expense.copyWith(
      lastModified: DateTime.now(),
      isSynced: false,
    );
    await db.update(
      'expenses',
      expenseToUpdate.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  @override
  Future<void> deleteExpense(String id) async {
    final db = await database;
    // Soft delete: mark as deleted and unsynced
    await db.update(
      'expenses',
      {
        'is_deleted': 1,
        'is_synced': 0,
        'last_modified': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============= Sync Operations =============

  @override
  Future<DateTime?> getLastPulledAt() async {
    final db = await database;
    final result = await db.query('sync_log', limit: 1);
    if (result.isEmpty || result.first['last_pulled_at'] == null) {
      return null;
    }
    return DateTime.parse(result.first['last_pulled_at'] as String);
  }

  @override
  Future<void> setLastPulledAt(DateTime timestamp) async {
    final db = await database;
    await db.insert('sync_log', {
      'id': 1,
      'last_pulled_at': timestamp.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<List<Expense>> getUnsyncedExpenses() async {
    final db = await database;
    final maps = await db.query('expenses', where: 'is_synced = 0');
    return maps.map((m) => Expense.fromMap(m)).toList();
  }

  @override
  Future<void> markAsSynced(List<String> ids) async {
    if (ids.isEmpty) return;
    final db = await database;
    final placeholders = List.filled(ids.length, '?').join(',');
    await db.rawUpdate(
      'UPDATE expenses SET is_synced = 1 WHERE id IN ($placeholders)',
      ids,
    );
  }

  @override
  Future<void> upsertFromRemote(Expense expense) async {
    final db = await database;
    // Mark as synced since it came from the server
    final expenseToUpsert = expense.copyWith(isSynced: true);
    await db.insert(
      'expenses',
      expenseToUpsert.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> hardDelete(String id) async {
    final db = await database;
    await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('expenses');
    await db.delete('sync_log');
  }

  @override
  Future<void> assignUserIdToOrphans(String userId) async {
    final db = await database;
    await db.rawUpdate(
      "UPDATE expenses SET user_id = ?, is_synced = 0, last_modified = ? WHERE user_id = ''",
      [userId, DateTime.now().toIso8601String()],
    );
  }

  @override
  Future<int> getPendingSyncCount() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM expenses WHERE is_synced = 0',
    );
    return (result.first['count'] as int?) ?? 0;
  }

  // ============= Analytics Operations =============

  String _activeExpensesCondition() => 'is_deleted = 0';

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
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0 AND ${_activeExpensesCondition()}',
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
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0 AND ${_activeExpensesCondition()}',
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
      'SELECT category, SUM(amount) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0 AND ${_activeExpensesCondition()} GROUP BY category ORDER BY total DESC',
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
        'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0 AND ${_activeExpensesCondition()}',
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
        'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0 AND ${_activeExpensesCondition()}',
        [start.toIso8601String(), end.toIso8601String()],
      );
      map[dayNames[day.weekday - 1]] =
          (result.first['total'] as num?)?.toDouble() ?? 0;
    }
    return map;
  }

  @override
  Future<Map<String, double>> getMonthlySpending() async {
    final db = await database;
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
      final result = await db.rawQuery(
        'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0 AND ${_activeExpensesCondition()}',
        [start.toIso8601String(), end.toIso8601String()],
      );
      map[monthNames[month.month - 1]] =
          (result.first['total'] as num?)?.toDouble() ?? 0;
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

    // Get total spent this month
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 0 AND ${_activeExpensesCondition()}',
      [start, end],
    );
    final totalSpent = (result.first['total'] as num?)?.toDouble() ?? 0;

    // Divide by days passed in current month (minimum 1)
    final daysPassed = now.day;
    return totalSpent / daysPassed;
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
      'SELECT COALESCE(SUM(amount), 0) as total FROM expenses WHERE date_time >= ? AND date_time <= ? AND is_income = 1 AND ${_activeExpensesCondition()}',
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
