import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../theme/app_theme.dart';
import '../main.dart'
    show
        currencyNotifier,
        languageNotifier,
        usernameNotifier,
        profileImageNotifier,
        darkModeNotifier,
        repo;
import '../services/auth_service.dart';
import '../services/sync_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'INR',
    'CAD',
    'AUD',
    'CHF',
  ];

  final List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'German',
    'Japanese',
    'Hindi',
    'Portuguese',
  ];

  @override
  void initState() {
    super.initState();
    darkModeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    darkModeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onThemeChange() {
    setState(() {});
  }

  Future<void> _showLogoutConfirmation() async {
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Sign Out',
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to sign out? All local data will be cleared.',
          style: TextStyle(color: colors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: colors.onSurfaceDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out', style: TextStyle(color: colors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.instance.signOut();
    }
  }

  void _showCurrencyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final colors = context.colors;
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
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
                'Select Currency',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _currencies.map((currency) {
                    final isSelected = currency == currencyNotifier.value;
                    return ListTile(
                      onTap: () {
                        currencyNotifier.setCurrency(currency);
                        Navigator.pop(context);
                        setState(() {});
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
                        child: Center(
                          child: Text(
                            _getCurrencySymbol(currency),
                            style: TextStyle(
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        currency,
                        style: TextStyle(
                          color: isSelected ? colors.primary : colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        _getCurrencyName(currency),
                        style: TextStyle(
                          color: colors.onSurfaceDim,
                          fontSize: 12,
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
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (context) {
        final colors = context.colors;
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
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
                'Select Language',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _languages.map((lang) {
                    final isSelected = lang == languageNotifier.value;
                    return ListTile(
                      onTap: () {
                        languageNotifier.setLanguage(lang);
                        Navigator.pop(context);
                        setState(() {});
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
                          Icons.language,
                          color: isSelected
                              ? colors.primary
                              : colors.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        lang,
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
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final colors = context.colors;
    final source = await showModalBottomSheet<ImageSource>(
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
                'Choose Photo',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: colors.primary),
                ),
                title: Text(
                  'Camera',
                  style: TextStyle(color: colors.onSurface),
                ),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.secondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: colors.secondary),
                ),
                title: Text(
                  'Gallery',
                  style: TextStyle(color: colors.onSurface),
                ),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (profileImageNotifier.value != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.delete, color: colors.error),
                  ),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(color: colors.error),
                  ),
                  onTap: () {
                    profileImageNotifier.setImage(null);
                    Navigator.pop(context);
                    setState(() {});
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (source != null) {
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (pickedFile != null) {
        profileImageNotifier.setImage(pickedFile.path);
        setState(() {});
      }
    }
  }

  void _showEditUsernameDialog() {
    final controller = TextEditingController(text: usernameNotifier.value);
    showDialog(
      context: context,
      builder: (context) {
        final colors = context.colors;
        return AlertDialog(
          backgroundColor: colors.surfaceContainerHigh,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text('Edit Name', style: TextStyle(color: colors.onSurface)),
          content: TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: colors.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: colors.onSurfaceDim),
              filled: true,
              fillColor: colors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: colors.onSurfaceDim),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: () {
                if (controller.text.trim().isNotEmpty) {
                  usernameNotifier.setUsername(controller.text.trim());
                  Navigator.pop(context);
                  setState(() {});
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'INR':
        return '₹';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'CHF':
        return 'Fr';
      default:
        return code;
    }
  }

  String _getCurrencyName(String code) {
    switch (code) {
      case 'USD':
        return 'US Dollar';
      case 'EUR':
        return 'Euro';
      case 'GBP':
        return 'British Pound';
      case 'JPY':
        return 'Japanese Yen';
      case 'INR':
        return 'Indian Rupee';
      case 'CAD':
        return 'Canadian Dollar';
      case 'AUD':
        return 'Australian Dollar';
      case 'CHF':
        return 'Swiss Franc';
      default:
        return code;
    }
  }

  String _getPdfCurrencySymbol(String code) {
    // Return currency symbol that will work with NotoSans font
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      case 'INR':
        return '₹';
      case 'CAD':
        return 'C\$';
      case 'AUD':
        return 'A\$';
      case 'CHF':
        return 'Fr';
      default:
        return code;
    }
  }

  void _showDownloadOptions() {
    final colors = context.colors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surfaceContainerLow,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
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
                  'Download History',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select time period for expense report',
                  style: TextStyle(color: colors.onSurfaceDim, fontSize: 14),
                ),
                const SizedBox(height: 20),
                _buildDownloadOption(
                  icon: Icons.calendar_today,
                  title: 'Current Month',
                  subtitle: DateFormat('MMMM yyyy').format(DateTime.now()),
                  colors: colors,
                  onTap: () {
                    Navigator.pop(context);
                    _downloadReport('current_month');
                  },
                ),
                const SizedBox(height: 8),
                _buildDownloadOption(
                  icon: Icons.history,
                  title: 'Last Month',
                  subtitle: DateFormat('MMMM yyyy').format(
                    DateTime(DateTime.now().year, DateTime.now().month - 1),
                  ),
                  colors: colors,
                  onTap: () {
                    Navigator.pop(context);
                    _downloadReport('last_month');
                  },
                ),
                const SizedBox(height: 8),
                _buildDownloadOption(
                  icon: Icons.calendar_month,
                  title: 'Last Year',
                  subtitle: '${DateTime.now().year - 1}',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(context);
                    _downloadReport('last_year');
                  },
                ),
                const SizedBox(height: 8),
                _buildDownloadOption(
                  icon: Icons.date_range,
                  title: 'Custom Date',
                  subtitle: 'Select date range',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(context);
                    _showCustomDatePicker();
                  },
                ),
                const SizedBox(height: 8),
                _buildDownloadOption(
                  icon: Icons.all_inclusive,
                  title: 'All Time',
                  subtitle: 'Complete expense history',
                  colors: colors,
                  onTap: () {
                    Navigator.pop(context);
                    _downloadReport('all_time');
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDownloadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required DailyDashColorScheme colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colors.primary, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
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
            Icon(Icons.download, color: colors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final colors = context.colors;
    DateTime? startDate;
    DateTime? endDate;

    startDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Select Start Date',
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

    if (startDate == null || !mounted) return;

    endDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: startDate,
      lastDate: DateTime.now(),
      helpText: 'Select End Date',
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

    if (endDate == null || !mounted) return;

    _downloadReport('custom', startDate: startDate, endDate: endDate);
  }

  Future<void> _downloadReport(
    String period, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final colors = context.colors;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 16),
              Text(
                'Generating PDF...',
                style: TextStyle(color: colors.onSurface),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Calculate date range based on period
      final now = DateTime.now();
      DateTime start;
      DateTime end;
      String periodName;

      switch (period) {
        case 'current_month':
          start = DateTime(now.year, now.month, 1);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          periodName = DateFormat('MMMM_yyyy').format(now);
          break;
        case 'last_month':
          start = DateTime(now.year, now.month - 1, 1);
          end = DateTime(now.year, now.month, 0, 23, 59, 59);
          periodName = DateFormat(
            'MMMM_yyyy',
          ).format(DateTime(now.year, now.month - 1));
          break;
        case 'last_year':
          start = DateTime(now.year - 1, 1, 1);
          end = DateTime(now.year - 1, 12, 31, 23, 59, 59);
          periodName = '${now.year - 1}';
          break;
        case 'custom':
          start = startDate!;
          end = DateTime(endDate!.year, endDate.month, endDate.day, 23, 59, 59);
          periodName =
              '${DateFormat('dd_MMM').format(start)}_to_${DateFormat('dd_MMM_yyyy').format(end)}';
          break;
        case 'all_time':
        default:
          start = DateTime(2020, 1, 1);
          end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
          periodName = 'All_Time';
          break;
      }

      // Fetch expenses for the date range
      final expenses = await repo.getExpensesByDateRange(start, end);

      // Load font that supports Unicode currency symbols
      final fontData = await rootBundle.load(
        'assets/fonts/NotoSans-Regular.ttf',
      );
      final ttf = pw.Font.ttf(fontData);
      final boldFontData = await rootBundle.load(
        'assets/fonts/NotoSans-Bold.ttf',
      );
      final ttfBold = pw.Font.ttf(boldFontData);

      // Get currency symbol for PDF
      final currencySymbol = _getPdfCurrencySymbol(currencyNotifier.value);

      // Generate PDF
      final pdf = pw.Document();

      // Define text styles with custom font
      final headerStyle = pw.TextStyle(
        font: ttfBold,
        fontSize: 24,
        color: PdfColors.white,
      );
      final subHeaderStyle = pw.TextStyle(
        font: ttf,
        fontSize: 14,
        color: PdfColors.white,
      );
      final bodyStyle = pw.TextStyle(font: ttf, fontSize: 12);
      final smallStyle = pw.TextStyle(
        font: ttf,
        fontSize: 10,
        color: PdfColors.grey700,
      );
      final boldStyle = pw.TextStyle(font: ttfBold, fontSize: 12);

      // Calculate totals
      double totalExpense = 0;
      final categoryTotals = <String, double>{};

      for (final e in expenses) {
        if (!e.isIncome) {
          totalExpense += e.amount;
          categoryTotals[e.category] =
              (categoryTotals[e.category] ?? 0) + e.amount;
        }
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.cyan800,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('DailyDash', style: headerStyle),
                      pw.SizedBox(height: 4),
                      pw.Text('Expense Report', style: subHeaderStyle),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        usernameNotifier.value,
                        style: pw.TextStyle(
                          font: ttfBold,
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                        style: pw.TextStyle(
                          font: ttf,
                          fontSize: 10,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Period Info
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Period', style: smallStyle),
                      pw.Text(
                        '${DateFormat('dd MMM yyyy').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}',
                        style: boldStyle,
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Total Transactions', style: smallStyle),
                      pw.Text('${expenses.length}', style: boldStyle),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Summary
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.red50,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.red200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text(
                    'Total Expenses: ',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 14,
                      color: PdfColors.red800,
                    ),
                  ),
                  pw.Text(
                    '$currencySymbol${NumberFormat('#,##0.00').format(totalExpense)}',
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 18,
                      color: PdfColors.red800,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Category Breakdown
            if (categoryTotals.isNotEmpty) ...[
              pw.Text(
                'Category Breakdown',
                style: pw.TextStyle(font: ttfBold, fontSize: 14),
              ),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.grey200,
                    ),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Category', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount', style: boldStyle),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Percentage', style: boldStyle),
                      ),
                    ],
                  ),
                  ...categoryTotals.entries.map(
                    (entry) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(entry.key, style: bodyStyle),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '$currencySymbol${NumberFormat('#,##0.00').format(entry.value)}',
                            style: bodyStyle,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            '${(entry.value / totalExpense * 100).toStringAsFixed(1)}%',
                            style: bodyStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // Transactions Table
            pw.Text(
              'Transaction Details',
              style: pw.TextStyle(font: ttfBold, fontSize: 14),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(2),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Date',
                        style: pw.TextStyle(font: ttfBold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Description',
                        style: pw.TextStyle(font: ttfBold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Category',
                        style: pw.TextStyle(font: ttfBold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Payment',
                        style: pw.TextStyle(font: ttfBold, fontSize: 10),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(6),
                      child: pw.Text(
                        'Amount',
                        style: pw.TextStyle(font: ttfBold, fontSize: 10),
                      ),
                    ),
                  ],
                ),
                ...expenses.map(
                  (e) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          DateFormat('dd/MM/yy').format(e.dateTime),
                          style: pw.TextStyle(font: ttf, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          e.description,
                          style: pw.TextStyle(font: ttf, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          e.category,
                          style: pw.TextStyle(font: ttf, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          e.paymentMode,
                          style: pw.TextStyle(font: ttf, fontSize: 9),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          '${e.isIncome ? '+' : '-'}$currencySymbol${NumberFormat('#,##0.00').format(e.amount)}',
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 9,
                            color: e.isIncome
                                ? PdfColors.green700
                                : PdfColors.red700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      // Get directory to save PDF
      Directory? saveDir;
      String savePath;

      if (Platform.isAndroid) {
        // Use app's external storage directory (no permission needed on Android 10+)
        saveDir = await getExternalStorageDirectory();
        saveDir ??= await getApplicationDocumentsDirectory();
        savePath = saveDir.path;
      } else if (Platform.isIOS) {
        saveDir = await getApplicationDocumentsDirectory();
        savePath = saveDir.path;
      } else {
        saveDir = await getDownloadsDirectory();
        savePath =
            saveDir?.path ?? (await getApplicationDocumentsDirectory()).path;
      }

      if (saveDir == null && savePath.isEmpty) {
        if (mounted) Navigator.pop(context);
        _showMessage('Could not access storage');
        return;
      }

      // Save PDF
      final fileName =
          'DailyDash_${periodName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('$savePath/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) Navigator.pop(context);

      // Show success and open file option
      _showDownloadSuccess(file.path);
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showMessage('Error generating PDF: $e');
    }
  }

  void _showMessage(String message) {
    final colors = context.colors;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colors.surfaceContainerHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDownloadSuccess(String filePath) {
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
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colors.secondary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: colors.secondary,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PDF Downloaded!',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Saved to Downloads folder',
                style: TextStyle(color: colors.onSurfaceDim, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Close',
                            style: TextStyle(
                              color: colors.onSurfaceDim,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        OpenFile.open(filePath);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: colors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Text(
                            'Open PDF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(
                  'DailyDash',
                  style: TextStyle(
                    color: colors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Profile Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.secondary,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 33,
                            backgroundColor: colors.surfaceContainerHigh,
                            backgroundImage: profileImageNotifier.value != null
                                ? FileImage(File(profileImageNotifier.value!))
                                : null,
                            child: profileImageNotifier.value == null
                                ? Icon(
                                    Icons.person,
                                    color: colors.onSurfaceDim,
                                    size: 36,
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          usernameNotifier.value,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _showEditUsernameDialog,
                        child: Icon(
                          Icons.edit,
                          color: colors.onSurfaceDim,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Appearance Section
              _buildSectionHeader('APPEARANCE', colors),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          darkModeNotifier.value
                              ? Icons.dark_mode
                              : Icons.light_mode,
                          color: colors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dark Mode',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              darkModeNotifier.value
                                  ? 'Neon Nocturne theme'
                                  : 'Light theme enabled',
                              style: TextStyle(
                                color: colors.onSurfaceDim,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: darkModeNotifier,
                        builder: (context, isDarkMode, _) {
                          return Switch(
                            value: isDarkMode,
                            onChanged: (v) {
                              darkModeNotifier.toggle();
                              setState(() {});
                            },
                            activeThumbColor: colors.primary,
                            activeTrackColor: colors.primary.withValues(
                              alpha: 0.4,
                            ),
                            inactiveThumbColor: colors.onSurfaceDim,
                            inactiveTrackColor: colors.surfaceContainerHigh,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Preferences Section
              _buildSectionHeader('PREFERENCES', colors),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildPreferenceItem(
                      icon: Icons.attach_money,
                      title: 'Currency',
                      subtitle:
                          '${currencyNotifier.value} (${_getCurrencySymbol(currencyNotifier.value)})',
                      colors: colors,
                      onTap: _showCurrencyPicker,
                    ),
                    const SizedBox(height: 8),
                    _buildPreferenceItem(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: languageNotifier.value,
                      colors: colors,
                      onTap: _showLanguagePicker,
                    ),
                    const SizedBox(height: 8),
                    _buildPreferenceItem(
                      icon: Icons.download,
                      title: 'Download History',
                      subtitle: 'Export expenses as PDF',
                      colors: colors,
                      onTap: _showDownloadOptions,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Account Section
              _buildSectionHeader('ACCOUNT', colors),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // User email display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.email_outlined,
                              color: colors.primary,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email',
                                  style: TextStyle(
                                    color: colors.onSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  AuthService.instance.currentUserEmail ??
                                      'Not signed in',
                                  style: TextStyle(
                                    color: colors.onSurfaceDim,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Sync status
                    GestureDetector(
                      onTap: () => SyncService.instance.triggerSync(),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colors.secondary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ValueListenableBuilder<SyncStatus>(
                                valueListenable:
                                    SyncService.instance.syncStatusNotifier,
                                builder: (context, status, _) {
                                  IconData icon;
                                  Color color;
                                  switch (status) {
                                    case SyncStatus.synced:
                                      icon = Icons.cloud_done;
                                      color = colors.success;
                                      break;
                                    case SyncStatus.syncing:
                                      icon = Icons.cloud_sync;
                                      color = colors.primary;
                                      break;
                                    case SyncStatus.offline:
                                      icon = Icons.cloud_off;
                                      color = colors.chartOrange;
                                      break;
                                    case SyncStatus.error:
                                      icon = Icons.cloud_off;
                                      color = colors.error;
                                      break;
                                    case SyncStatus.idle:
                                      icon = Icons.cloud_done;
                                      color = colors.secondary;
                                      break;
                                  }
                                  return Icon(icon, color: color, size: 22);
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sync Status',
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  ValueListenableBuilder<SyncStatus>(
                                    valueListenable:
                                        SyncService.instance.syncStatusNotifier,
                                    builder: (context, status, _) {
                                      String statusText;
                                      switch (status) {
                                        case SyncStatus.synced:
                                          statusText = 'All data synced';
                                          break;
                                        case SyncStatus.syncing:
                                          statusText = 'Syncing...';
                                          break;
                                        case SyncStatus.offline:
                                          statusText =
                                              'Offline - changes pending';
                                          break;
                                        case SyncStatus.error:
                                          statusText =
                                              'Sync error - tap to retry';
                                          break;
                                        case SyncStatus.idle:
                                          statusText = 'Tap to sync now';
                                          break;
                                      }
                                      return Text(
                                        statusText,
                                        style: TextStyle(
                                          color: colors.onSurfaceDim,
                                          fontSize: 13,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.sync,
                              color: colors.onSurfaceDim,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Logout button
                    GestureDetector(
                      onTap: _showLogoutConfirmation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: colors.error.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                Icons.logout,
                                color: colors.error,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sign Out',
                                    style: TextStyle(
                                      color: colors.error,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Sign out and clear local data',
                                    style: TextStyle(
                                      color: colors.error.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
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

              // About Section
              _buildSectionHeader('ABOUT', colors),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildAboutItem(
                      icon: Icons.info_outline,
                      title: 'Version',
                      subtitle: 'DailyDash v4.2.0 (Premium)',
                      colors: colors,
                    ),
                    const SizedBox(height: 8),
                    _buildAboutItem(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      subtitle: '',
                      colors: colors,
                      showArrow: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Text(
                'DESIGNED BY DAILYDASH LABS',
                style: TextStyle(
                  color: colors.onSurfaceDim.withValues(alpha: 0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(colors.onSurfaceDim),
                  const SizedBox(width: 8),
                  _buildDot(colors.onSurfaceDim),
                  const SizedBox(width: 8),
                  _buildDot(colors.onSurfaceDim),
                ],
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, DailyDashColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 2,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: colors.onSurfaceDim,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required DailyDashColorScheme colors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.onSurfaceDim.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.onSurfaceVariant, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.secondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colors.onSurfaceDim, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required DailyDashColorScheme colors,
    bool showArrow = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: colors.secondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(color: colors.onSurfaceDim, fontSize: 12),
                  ),
              ],
            ),
          ),
          if (showArrow)
            Icon(Icons.open_in_new, color: colors.onSurfaceDim, size: 18),
        ],
      ),
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
