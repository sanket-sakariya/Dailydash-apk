class Expense {
  /// Local SQLite primary key (autoincrement). `null` until inserted locally.
  final int? id;

  /// Remote Supabase primary key (UUID). `null` until the record has been
  /// pushed to Supabase at least once.
  final String? remoteId;

  /// Owning Supabase auth user id (UUID). `null` for legacy / pre-auth rows.
  final String? userId;

  final double amount;
  final DateTime dateTime;
  final String description;
  final String category;
  final String paymentMode;
  final bool isIncome;

  /// `false` when the row has local changes that have not been pushed to
  /// Supabase yet. Set to `true` after a successful upsert.
  final bool isSynced;

  /// Last local mutation timestamp. Used as the conflict-resolution / pull
  /// watermark and mirrors the `last_updated` column in Supabase.
  final DateTime updatedAt;

  Expense({
    this.id,
    this.remoteId,
    this.userId,
    required this.amount,
    required this.dateTime,
    required this.description,
    required this.category,
    required this.paymentMode,
    this.isIncome = false,
    this.isSynced = false,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toUtc();

  // ---------------------------------------------------------------------------
  // SQLite (snake_case columns, ints for booleans, ISO-8601 strings for dates)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'amount': amount,
      'date_time': dateTime.toIso8601String(),
      'description': description,
      'category': category,
      'payment_mode': paymentMode,
      'is_income': isIncome ? 1 : 0,
      'is_synced': isSynced ? 1 : 0,
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'remote_id': remoteId,
      'user_id': userId,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      remoteId: map['remote_id'] as String?,
      userId: map['user_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      dateTime: DateTime.parse(map['date_time'] as String),
      description: map['description'] as String,
      category: map['category'] as String,
      paymentMode: map['payment_mode'] as String,
      isIncome: _parseBool(map['is_income']),
      isSynced: _parseBool(map['is_synced']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String).toUtc()
          : DateTime.now().toUtc(),
    );
  }

  // ---------------------------------------------------------------------------
  // Supabase (JSON: native bool/timestamptz, UUID primary key in `id`)
  // ---------------------------------------------------------------------------

  /// Serializes for Supabase. The remote PK is `id` (UUID) — local int ids are
  /// intentionally not sent. `last_updated` mirrors the SQLite `updated_at`.
  Map<String, dynamic> toSupabaseJson() {
    return {
      if (remoteId != null) 'id': remoteId,
      'user_id': userId,
      'amount': amount,
      'date_time': dateTime.toUtc().toIso8601String(),
      'description': description,
      'category': category,
      'payment_mode': paymentMode,
      'is_income': isIncome,
      'last_updated': updatedAt.toUtc().toIso8601String(),
    };
  }

  /// Builds an Expense from a Supabase row. Local `id` is left null — callers
  /// resolve / merge against any existing local row by `remoteId`.
  factory Expense.fromSupabaseJson(Map<String, dynamic> json) {
    return Expense(
      id: null,
      remoteId: json['id']?.toString(),
      userId: json['user_id']?.toString(),
      amount: (json['amount'] as num).toDouble(),
      dateTime: DateTime.parse(json['date_time'] as String),
      description: (json['description'] ?? '') as String,
      category: (json['category'] ?? '') as String,
      paymentMode: (json['payment_mode'] ?? '') as String,
      isIncome: _parseBool(json['is_income']),
      isSynced: true,
      updatedAt: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String).toUtc()
          : DateTime.now().toUtc(),
    );
  }

  static bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return false;
  }

  Expense copyWith({
    int? id,
    String? remoteId,
    String? userId,
    double? amount,
    DateTime? dateTime,
    String? description,
    String? category,
    String? paymentMode,
    bool? isIncome,
    bool? isSynced,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      category: category ?? this.category,
      paymentMode: paymentMode ?? this.paymentMode,
      isIncome: isIncome ?? this.isIncome,
      isSynced: isSynced ?? this.isSynced,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
