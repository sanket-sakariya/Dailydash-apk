import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../main.dart' show repo, currencyNotifier;
import '../models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  final Expense? expense; // For editing existing expense

  const AddExpenseScreen({super.key, this.expense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  String _amount = '0';
  String _selectedCategory = 'Food';
  String _selectedPaymentMode = 'Credit Card';
  DateTime _selectedDateTime = DateTime.now();
  final _descriptionController = TextEditingController();

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    if (widget.expense != null) {
      final e = widget.expense!;
      _amount = e.amount.toString();
      _selectedCategory = e.category;
      _selectedPaymentMode = e.paymentMode;
      _selectedDateTime = e.dateTime;
      _descriptionController.text = e.description;
    }
  }

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Bills', 'icon': Icons.bolt},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Shop', 'icon': Icons.shopping_bag},
    {'name': 'Health', 'icon': Icons.medical_services},
  ];

  final List<Map<String, dynamic>> _paymentModes = [
    {'name': 'Credit Card', 'icon': Icons.credit_card},
    {'name': 'Debit Card', 'icon': Icons.credit_card_outlined},
    {'name': 'UPI', 'icon': Icons.qr_code},
    {'name': 'Cash', 'icon': Icons.money},
    {'name': 'Bank Transfer', 'icon': Icons.account_balance},
  ];

  void _onKeyTap(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
          if (_amount.endsWith('.')) {
            _amount = _amount.substring(0, _amount.length - 1);
          }
        }
        if (_amount.isEmpty) {
          _amount = '0';
        }
      } else if (key == '.') {
        if (!_amount.contains('.')) {
          _amount = '$_amount.';
        }
      } else {
        if (_amount == '0') {
          _amount = key;
        } else {
          if (_amount.contains('.')) {
            final parts = _amount.split('.');
            if (parts[1].length < 2) {
              _amount = '$_amount$key';
            }
          } else {
            _amount = '$_amount$key';
          }
        }
      }
    });
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amount.replaceAll(',', ''));
    if (amount == null || amount <= 0) return;

    final expense = Expense(
      id: widget.expense?.id,
      amount: amount,
      dateTime: _selectedDateTime,
      description: _descriptionController.text.isEmpty
          ? _selectedCategory
          : _descriptionController.text,
      category: _selectedCategory,
      paymentMode: _selectedPaymentMode,
    );

    if (_isEditing) {
      await repo.updateExpense(expense);
    } else {
      await repo.insertExpense(expense);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _selectDateTime() async {
    final colors = context.colors;

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.primary,
              onPrimary: Colors.white,
              surface: colors.surfaceContainerHigh,
              onSurface: colors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.dark(
                primary: colors.primary,
                onPrimary: Colors.white,
                surface: colors.surfaceContainerHigh,
                onSurface: colors.onSurface,
              ),
            ),
            child: child!,
          );
        },
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _showCategoryPicker() {
    final colors = context.colors;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 20),
              Text(
                'Select Category',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  ..._categories.map((cat) => _buildCategoryChip(cat, colors)),
                  _buildCategoryChip({
                    'name': 'Housing',
                    'icon': Icons.home,
                  }, colors),
                  _buildCategoryChip({
                    'name': 'Entertainment',
                    'icon': Icons.movie,
                  }, colors),
                  _buildCategoryChip({
                    'name': 'Education',
                    'icon': Icons.school,
                  }, colors),
                  _buildCategoryChip({
                    'name': 'Other',
                    'icon': Icons.more_horiz,
                  }, colors),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(
    Map<String, dynamic> cat,
    DailyDashColorScheme colors,
  ) {
    final isSelected = _selectedCategory == cat['name'];
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = cat['name'] as String);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.2)
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? Border.all(color: colors.primary, width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              cat['icon'] as IconData,
              color: isSelected ? colors.primary : colors.onSurfaceVariant,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              cat['name'] as String,
              style: TextStyle(
                color: isSelected ? colors.primary : colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentModePicker() {
    final colors = context.colors;
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              const SizedBox(height: 20),
              Text(
                'Payment Mode',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              ...(_paymentModes.map((mode) {
                final isSelected = _selectedPaymentMode == mode['name'];
                return ListTile(
                  onTap: () {
                    setState(
                      () => _selectedPaymentMode = mode['name'] as String,
                    );
                    Navigator.pop(context);
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isSelected
                      ? colors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.2)
                          : colors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      mode['icon'] as IconData,
                      color: isSelected
                          ? colors.primary
                          : colors.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    mode['name'] as String,
                    style: TextStyle(
                      color: isSelected ? colors.primary : colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: colors.primary,
                          size: 22,
                        )
                      : null,
                );
              })),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: colors.primary,
                      size: 18,
                    ),
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
            ),

            // Add Expense Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditing ? 'Edit Expense' : 'Add Expense',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.close,
                        color: colors.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Amount Display
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'ENTER AMOUNT',
                    style: TextStyle(
                      color: colors.onSurfaceDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currencyNotifier.symbol,
                        style: TextStyle(
                          color: colors.primary,
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _amount,
                        style: TextStyle(
                          color: _amount == '0'
                              ? colors.onSurfaceDim.withValues(alpha: 0.4)
                              : colors.onSurface,
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -2,
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 56,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Category Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CATEGORY',
                    style: TextStyle(
                      color: colors.onSurfaceDim,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _showCategoryPicker,
                    child: Text(
                      'See All',
                      style: TextStyle(
                        color: colors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Category chips
            SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['name'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => setState(
                        () => _selectedCategory = cat['name'] as String,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? colors.primary.withValues(alpha: 0.2)
                                  : colors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(18),
                              border: isSelected
                                  ? Border.all(color: colors.primary, width: 2)
                                  : null,
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurfaceDim,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? colors.onSurface
                                  : colors.onSurfaceDim,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Payment Mode & Date Time Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _showPaymentModePicker,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PAYMENT MODE',
                              style: TextStyle(
                                color: colors.onSurfaceDim,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.credit_card,
                                  color: colors.secondary,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    _selectedPaymentMode,
                                    style: TextStyle(
                                      color: colors.secondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDateTime,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DATE & TIME',
                              style: TextStyle(
                                color: colors.onSurfaceDim,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  color: colors.onSurface,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    DateFormat(
                                      'MMM dd, HH:mm',
                                    ).format(_selectedDateTime),
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Description
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DESCRIPTION',
                      style: TextStyle(
                        color: colors.onSurfaceDim,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      style: TextStyle(color: colors.onSurface, fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'What was this for?',
                        hintStyle: TextStyle(
                          color: colors.onSurfaceDim.withValues(alpha: 0.5),
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Numpad
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  children: [
                    _buildKeyRow(['1', '2', '3'], colors),
                    _buildKeyRow(['4', '5', '6'], colors),
                    _buildKeyRow(['7', '8', '9'], colors),
                    _buildKeyRow(['.', '0', '⌫'], colors),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Confirm Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: GestureDetector(
                onTap: _saveExpense,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [colors.primary, colors.primaryDim],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isEditing ? 'Update Transaction' : 'Confirm Transaction',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyRow(List<String> keys, DailyDashColorScheme colors) {
    return SizedBox(
      height: 48,
      child: Row(
        children: keys.map((key) {
          return Expanded(
            child: GestureDetector(
              onTap: () => _onKeyTap(key),
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: key == '⌫'
                      ? Icon(
                          Icons.backspace_outlined,
                          color: colors.onSurfaceVariant,
                          size: 22,
                        )
                      : Text(
                          key,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
