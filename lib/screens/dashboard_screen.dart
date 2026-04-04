import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../main.dart' show repo, currencyNotifier, profileImageNotifier, navigationIndexNotifier;
import '../models/expense.dart';
import 'add_expense_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  List<Expense> _recentExpenses = [];
  double _totalSpentThisMonth = 0;
  double _totalSpentLastMonth = 0;
  double _savings = 0;
  double _budgetPercentage = 0;
  Map<String, double> _categorySpending = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final expenses = await repo.getAllExpenses();
    final totalThisMonth = await repo.getTotalSpentThisMonth();
    final totalLastMonth = await repo.getTotalSpentLastMonth();
    final savings = await repo.getSavings();
    final budgetPercentage = await repo.getBudgetPercentage();
    final categorySpending = await repo.getCategorySpending();

    if (mounted) {
      setState(() {
        _recentExpenses = expenses.take(10).toList();
        _totalSpentThisMonth = totalThisMonth;
        _totalSpentLastMonth = totalLastMonth;
        _savings = savings;
        _budgetPercentage = budgetPercentage;
        _categorySpending = categorySpending;
        _loading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  double _getPercentageChange() {
    if (_totalSpentLastMonth == 0) return 0;
    return ((_totalSpentThisMonth - _totalSpentLastMonth) /
        _totalSpentLastMonth *
        100);
  }

  Color _getCategoryColor(String category, DailyDashColorScheme colors) {
    switch (category.toLowerCase()) {
      case 'food':
        return colors.chartCyan;
      case 'shop':
      case 'shopping':
        return colors.chartCyan;
      case 'transport':
        return colors.chartPurple;
      case 'housing':
        return colors.chartPurple;
      case 'bills':
        return colors.chartOrange;
      case 'health':
        return colors.chartPink;
      case 'income':
        return colors.success;
      default:
        return colors.chartPink;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'shop':
      case 'shopping':
        return Icons.shopping_bag;
      case 'transport':
        return Icons.directions_car;
      case 'housing':
        return Icons.home;
      case 'bills':
        return Icons.bolt;
      case 'health':
        return Icons.medical_services;
      case 'income':
        return Icons.account_balance;
      default:
        return Icons.category;
    }
  }

  String _getRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final expenseDate = DateTime(date.year, date.month, date.day);

    if (expenseDate == today) return 'TODAY';
    if (expenseDate == yesterday) return 'YESTERDAY';
    return DateFormat('MMM dd').format(date).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.primary))
          : SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // Profile Avatar
                              ValueListenableBuilder<String?>(
                                valueListenable: profileImageNotifier,
                                builder: (context, profileImage, _) {
                                  return Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colors.primaryContainer.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                      image: profileImage != null
                                          ? DecorationImage(
                                              image: FileImage(File(profileImage)),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: profileImage == null
                                        ? Icon(
                                            Icons.person,
                                            color: colors.primary,
                                            size: 22,
                                          )
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'DailyDash',
                                style: TextStyle(
                                  color: colors.primary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => navigationIndexNotifier.value = 2,
                            child: Icon(
                              Icons.settings,
                              color: colors.onSurfaceDim,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Total Spent Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.primaryContainer.withValues(alpha: 0.8),
                              colors.primaryDim.withValues(alpha: 0.6),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TOTAL SPENT THIS MONTH',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currencyNotifier.symbol,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatAmount(_totalSpentThisMonth),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 42,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getPercentageChange() >= 0
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${_getPercentageChange().abs().toStringAsFixed(0)}% vs last month',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Savings & Budgets Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SAVINGS',
                                    style: TextStyle(
                                      color: colors.onSurfaceDim,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${currencyNotifier.symbol}${_formatAmount(_savings.abs())}',
                                    style: TextStyle(
                                      color: colors.secondary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: 0.6,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colors.secondary,
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BUDGETS',
                                    style: TextStyle(
                                      color: colors.onSurfaceDim,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${_budgetPercentage.toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Used across ${_categorySpending.length} categories',
                                    style: TextStyle(
                                      color: colors.onSurfaceDim,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Recent Transactions Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Transactions',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'VIEW ALL',
                            style: TextStyle(
                              color: colors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Transactions List
                    ..._buildTransactionList(colors),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 10),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
            ).then((_) => loadData());
          },
          backgroundColor: colors.primary,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  List<Widget> _buildTransactionList(DailyDashColorScheme colors) {
    final widgets = <Widget>[];
    String? currentDate;

    for (final expense in _recentExpenses) {
      final date = _getRelativeDate(expense.dateTime);

      if (date != currentDate) {
        currentDate = date;
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              date,
              style: TextStyle(
                color: colors.onSurfaceDim,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ),
        );
      }

      widgets.add(_buildTransactionItem(expense, colors));
    }

    return widgets;
  }

  Future<void> _deleteExpense(Expense expense) async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Transaction',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Are you sure you want to delete "${expense.description}"?',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: colors.onSurfaceDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && expense.id != null) {
      await repo.deleteExpense(expense.id!);
      loadData();
    }
  }

  void _editExpense(Expense expense) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddExpenseScreen(expense: expense)),
    ).then((_) => loadData());
  }

  void _showTransactionDetails(Expense expense) {
    final colors = context.colors;
    final isIncome = expense.isIncome;
    final categoryColor = _getCategoryColor(expense.category, colors);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceDim,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category icon and amount
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getCategoryIcon(expense.category),
                      color: categoryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expense.description,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          expense.category,
                          style: TextStyle(
                            color: categoryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? '+' : '-'}${currencyNotifier.symbol}${_formatAmount(expense.amount)}',
                    style: TextStyle(
                      color: isIncome ? colors.success : colors.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: DateFormat('EEEE, MMM dd, yyyy').format(expense.dateTime),
                      colors: colors,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: DateFormat('hh:mm a').format(expense.dateTime),
                      colors: colors,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      icon: Icons.payment,
                      label: 'Payment Mode',
                      value: expense.paymentMode,
                      colors: colors,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _editExpense(expense);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.edit, color: colors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _deleteExpense(expense);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete, color: colors.error, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: colors.error,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required DailyDashColorScheme colors,
  }) {
    return Row(
      children: [
        Icon(icon, color: colors.onSurfaceDim, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: colors.onSurfaceDim,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Expense expense, DailyDashColorScheme colors) {
    final isIncome = expense.isIncome;
    final categoryColor = _getCategoryColor(expense.category, colors);

    return Dismissible(
      key: Key('expense_${expense.id}'),
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(Icons.edit, color: colors.primary, size: 24),
            const SizedBox(width: 8),
            Text('Edit', style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('Delete', style: TextStyle(color: colors.error, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Icon(Icons.delete, color: colors.error, size: 24),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          _editExpense(expense);
          return false;
        } else if (direction == DismissDirection.endToStart) {
          await _deleteExpense(expense);
          return false;
        }
        return false;
      },
      child: GestureDetector(
        onTap: () => _showTransactionDetails(expense),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              // Category indicator pill
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 14),
              // Icon
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _getCategoryIcon(expense.category),
                  color: categoryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              // Title and category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.description,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      expense.category,
                      style: TextStyle(color: colors.onSurfaceDim, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Amount and time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : '-'}${currencyNotifier.symbol}${_formatAmount(expense.amount)}',
                    style: TextStyle(
                      color: isIncome ? colors.success : colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('hh:mm a').format(expense.dateTime),
                    style: TextStyle(color: colors.onSurfaceDim, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
