import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../main.dart' show repo, currencyNotifier, navigationIndexNotifier;

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => AnalyticsScreenState();
}

class AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, double> _categorySpending = {};
  Map<String, double> _dailySpending = {};
  Map<String, double> _weeklySpending = {};
  Map<String, double> _monthlySpending = {};
  double _totalSpent = 0;
  double _avgDailySpend = 0;
  String _highestCategory = '';
  double _highestCategoryAmount = 0;
  bool _loading = true;
  String _selectedPeriod = 'Daily'; // Daily, Weekly, Monthly

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final categorySpending = await repo.getCategorySpending();
    final dailySpending = await repo.getDailySpending();
    final weeklySpending = await repo.getWeeklySpending();
    final monthlySpending = await repo.getMonthlySpending();
    final totalSpent = await repo.getTotalSpentThisMonth();
    final avgDailySpend = await repo.getAverageDailySpend();
    final highestCategory = await repo.getHighestCategory();

    double highestAmount = 0;
    if (categorySpending.isNotEmpty) {
      highestAmount = categorySpending.values.reduce((a, b) => a > b ? a : b);
    }

    if (mounted) {
      setState(() {
        _categorySpending = categorySpending;
        _dailySpending = dailySpending;
        _weeklySpending = weeklySpending;
        _monthlySpending = monthlySpending;
        _totalSpent = totalSpent;
        _avgDailySpend = avgDailySpend;
        _highestCategory = highestCategory;
        _highestCategoryAmount = highestAmount;
        _loading = false;
      });
    }
  }

  String _formatAmount(double amount) {
    return NumberFormat('#,##0.00', 'en_US').format(amount);
  }

  Color _getCategoryColor(
    String category,
    int index,
    DailyDashColorScheme colors,
  ) {
    final categoryColors = [
      colors.chartPurple,
      colors.chartCyan,
      colors.chartPink,
      colors.chartOrange,
      colors.primary,
      colors.secondary,
    ];

    switch (category.toLowerCase()) {
      case 'food':
        return colors.chartCyan;
      case 'bills':
        return colors.chartOrange;
      case 'transport':
        return colors.chartPurple;
      case 'shop':
      case 'shopping':
        return colors.chartPink;
      case 'health':
        return colors.primary;
      case 'housing':
        return colors.secondary;
      default:
        return categoryColors[index % categoryColors.length];
    }
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
                    // Header
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
                              // DailyDash Logo
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: colors.primary,
                                  size: 22,
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

                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FINANCIAL INSIGHTS',
                            style: TextStyle(
                              color: colors.onSurfaceDim,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Analytics',
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Donut Chart Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildDonutChartCard(colors),
                    ),

                    const SizedBox(height: 20),

                    // Stats Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(child: _buildHighestCategoryCard(colors)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildAvgDailySpendCard(colors)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Weekly Trends Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildTrendsCard(colors),
                    ),

                    const SizedBox(height: 20),

                    // Smart Insight Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSmartInsightCard(colors),
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDonutChartCard(DailyDashColorScheme colors) {
    if (_categorySpending.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              'No spending data yet',
              style: TextStyle(color: colors.onSurfaceDim),
            ),
          ),
        ),
      );
    }

    final sections = <PieChartSectionData>[];
    int index = 0;
    for (final entry in _categorySpending.entries) {
      sections.add(
        PieChartSectionData(
          value: entry.value,
          color: _getCategoryColor(entry.key, index, colors),
          radius: 24,
          showTitle: false,
        ),
      );
      index++;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CATEGORY DISTRIBUTION',
            style: TextStyle(
              color: colors.onSurfaceDim,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: 70,
                    sectionsSpace: 3,
                    startDegreeOffset: -90,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'TOTAL SPENT',
                      style: TextStyle(
                        color: colors.onSurfaceDim,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${currencyNotifier.symbol}${_formatAmount(_totalSpent)}',
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: _categorySpending.entries.map((entry) {
              final index = _categorySpending.keys.toList().indexOf(entry.key);
              final percentage = (_totalSpent > 0)
                  ? (entry.value / _totalSpent * 100).toStringAsFixed(0)
                  : '0';
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(entry.key, index, colors),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$percentage% • ${currencyNotifier.symbol}${_formatAmount(entry.value)}',
                    style: TextStyle(color: colors.onSurfaceDim, fontSize: 12),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHighestCategoryCard(DailyDashColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.trending_up, color: colors.secondary, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            'HIGHEST CATEGORY',
            style: TextStyle(
              color: colors.onSurfaceDim,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _highestCategory.isEmpty ? 'None' : _highestCategory,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '+${currencyNotifier.symbol}${_formatAmount(_highestCategoryAmount)} this month',
            style: TextStyle(
              color: colors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvgDailySpendCard(DailyDashColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today,
              color: colors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'AVG DAILY SPEND',
            style: TextStyle(
              color: colors.onSurfaceDim,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${currencyNotifier.symbol}${_formatAmount(_avgDailySpend)}',
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Within budget',
            style: TextStyle(
              color: colors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsCard(DailyDashColorScheme colors) {
    Map<String, double> spendingData;
    String title;
    String lastLabel;

    switch (_selectedPeriod) {
      case 'Daily':
        spendingData = _dailySpending;
        title = 'DAILY TRENDS';
        break;
      case 'Weekly':
        spendingData = _weeklySpending;
        title = 'WEEKLY TRENDS';
        break;
      case 'Monthly':
        spendingData = _monthlySpending;
        title = 'MONTHLY TRENDS';
        break;
      default:
        spendingData = _dailySpending;
        title = 'DAILY TRENDS';
    }

    final maxValue = spendingData.values.isEmpty
        ? 1.0
        : spendingData.values.reduce((a, b) => a > b ? a : b);

    final entries = spendingData.entries.toList();
    lastLabel = entries.isNotEmpty ? entries.last.key : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: colors.onSurfaceDim,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              GestureDetector(
                onTap: _showPeriodPicker,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedPeriod,
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        color: colors.onSurfaceDim,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: entries.map((entry) {
                final isLast = entry.key == lastLabel;
                final barHeight = maxValue > 0
                    ? (entry.value / maxValue * 120).clamp(8.0, 120.0)
                    : 8.0;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        width: _selectedPeriod == 'Monthly' ? 18 : 28,
                        height: barHeight,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: isLast
                                ? [
                                    colors.secondary,
                                    colors.secondary.withValues(alpha: 0.6),
                                  ]
                                : [
                                    colors.secondary.withValues(alpha: 0.5),
                                    colors.secondary.withValues(alpha: 0.3),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        entry.key,
                        style: TextStyle(
                          color: isLast
                              ? colors.secondary
                              : colors.onSurfaceDim,
                          fontSize: _selectedPeriod == 'Monthly' ? 9 : 11,
                          fontWeight: isLast
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showPeriodPicker() {
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
                'Select Period',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _buildPeriodOption('Daily', 'Last 7 days', Icons.today, colors),
              const SizedBox(height: 8),
              _buildPeriodOption(
                'Weekly',
                'Last 5 weeks',
                Icons.date_range,
                colors,
              ),
              const SizedBox(height: 8),
              _buildPeriodOption(
                'Monthly',
                'Last 12 months',
                Icons.calendar_month,
                colors,
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(
    String period,
    String subtitle,
    IconData icon,
    DailyDashColorScheme colors,
  ) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedPeriod = period);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.15)
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: colors.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.primary.withValues(alpha: 0.2)
                    : colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? colors.primary : colors.onSurfaceDim,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    period,
                    style: TextStyle(
                      color: isSelected ? colors.primary : colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.onSurfaceDim, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSmartInsightCard(DailyDashColorScheme colors) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.surfaceContainerHigh, colors.surfaceContainerLow],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.auto_awesome, color: colors.secondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smart Insight',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.4,
                    ),
                    children: [
                      const TextSpan(text: 'You spent 12% less on '),
                      TextSpan(
                        text: 'Dining Out',
                        style: TextStyle(
                          color: colors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const TextSpan(text: ' than last week. Keep it up!'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
