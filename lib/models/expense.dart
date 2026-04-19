import 'package:uuid/uuid.dart';

const _uuid = Uuid();

class Expense {
  final String id;
  final double amount;
  final DateTime dateTime;
  final String description;
  final String category;
  final String paymentMode;
  final bool isIncome;

  // Sync metadata
  final String userId;
  final DateTime lastModified;
  final bool isSynced;
  final bool isDeleted;

  Expense({
    String? id,
    required this.amount,
    required this.dateTime,
    required this.description,
    required this.category,
    required this.paymentMode,
    this.isIncome = false,
    this.userId = '',
    DateTime? lastModified,
    this.isSynced = false,
    this.isDeleted = false,
  }) : id = id ?? _uuid.v4(),
       lastModified = lastModified ?? DateTime.now();

  /// Converts to SQLite-compatible map (bools as ints, DateTime as ISO8601)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date_time': dateTime.toIso8601String(),
      'description': description,
      'category': category,
      'payment_mode': paymentMode,
      'is_income': isIncome ? 1 : 0,
      'user_id': userId,
      'last_modified': lastModified.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
    };
  }

  /// Creates from SQLite row (ints as bools, ISO8601 as DateTime)
  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      dateTime: DateTime.parse(map['date_time'] as String),
      description: map['description'] as String,
      category: map['category'] as String,
      paymentMode: map['payment_mode'] as String,
      isIncome: (map['is_income'] as int?) == 1,
      userId: map['user_id'] as String? ?? '',
      lastModified: map['last_modified'] != null
          ? DateTime.parse(map['last_modified'] as String)
          : DateTime.now(),
      isSynced: (map['is_synced'] as int?) == 1,
      isDeleted: (map['is_deleted'] as int?) == 1,
    );
  }

  /// Converts to Supabase JSON (native booleans, UUID strings)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'date_time': dateTime.toUtc().toIso8601String(),
      'description': description,
      'category': category,
      'payment_mode': paymentMode,
      'is_income': isIncome,
      'user_id': userId,
      'last_modified': lastModified.toUtc().toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  /// Creates from Supabase JSON response
  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      dateTime: DateTime.parse(json['date_time'] as String).toLocal(),
      description: json['description'] as String,
      category: json['category'] as String,
      paymentMode: json['payment_mode'] as String,
      isIncome: json['is_income'] as bool? ?? false,
      userId: json['user_id'] as String,
      lastModified: DateTime.parse(json['last_modified'] as String).toLocal(),
      isSynced: true, // Coming from server means it's synced
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  Expense copyWith({
    String? id,
    double? amount,
    DateTime? dateTime,
    String? description,
    String? category,
    String? paymentMode,
    bool? isIncome,
    String? userId,
    DateTime? lastModified,
    bool? isSynced,
    bool? isDeleted,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      category: category ?? this.category,
      paymentMode: paymentMode ?? this.paymentMode,
      isIncome: isIncome ?? this.isIncome,
      userId: userId ?? this.userId,
      lastModified: lastModified ?? this.lastModified,
      isSynced: isSynced ?? this.isSynced,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  /// Creates a copy marked for sync (isSynced=false, updated lastModified)
  Expense markForSync() {
    return copyWith(isSynced: false, lastModified: DateTime.now());
  }

  /// Creates a copy marked as synced
  Expense markAsSynced() {
    return copyWith(isSynced: true);
  }

  /// Creates a soft-deleted copy for sync
  Expense markAsDeleted() {
    return copyWith(
      isDeleted: true,
      isSynced: false,
      lastModified: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'Expense(id: $id, amount: $amount, category: $category, '
        'isSynced: $isSynced, isDeleted: $isDeleted)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Expense && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
