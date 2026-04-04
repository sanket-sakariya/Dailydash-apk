class Expense {
  final int? id;
  final double amount;
  final DateTime dateTime;
  final String description;
  final String category;
  final String paymentMode;
  final bool isIncome;

  Expense({
    this.id,
    required this.amount,
    required this.dateTime,
    required this.description,
    required this.category,
    required this.paymentMode,
    this.isIncome = false,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'amount': amount,
      'date_time': dateTime.toIso8601String(),
      'description': description,
      'category': category,
      'payment_mode': paymentMode,
      'is_income': isIncome ? 1 : 0,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as int?,
      amount: (map['amount'] as num).toDouble(),
      dateTime: DateTime.parse(map['date_time'] as String),
      description: map['description'] as String,
      category: map['category'] as String,
      paymentMode: map['payment_mode'] as String,
      isIncome: (map['is_income'] as int?) == 1,
    );
  }

  Expense copyWith({
    int? id,
    double? amount,
    DateTime? dateTime,
    String? description,
    String? category,
    String? paymentMode,
    bool? isIncome,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      dateTime: dateTime ?? this.dateTime,
      description: description ?? this.description,
      category: category ?? this.category,
      paymentMode: paymentMode ?? this.paymentMode,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}
