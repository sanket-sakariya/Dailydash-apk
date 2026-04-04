import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_preview/device_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'database/data_repository.dart';
import 'database/in_memory_repository.dart';
import 'database/database_helper.dart';

late final DataRepository repo;
late final SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences for settings persistence
  prefs = await SharedPreferences.getInstance();

  // Use in-memory on web (sqflite WASM is unreliable), SQLite on native
  if (kIsWeb) {
    repo = InMemoryRepository.instance;
  } else {
    repo = DatabaseHelper.instance;
    // Pre-initialize the database to ensure it's ready
    await (repo as DatabaseHelper).database;
  }

  runApp(
    DevicePreview(enabled: false, builder: (context) => const DailyDashApp()),
  );
}

class CurrencyNotifier extends ValueNotifier<String> {
  CurrencyNotifier() : super(prefs.getString('currency') ?? 'INR');

  void setCurrency(String currency) {
    value = currency;
    prefs.setString('currency', currency);
  }

  String get symbol {
    switch (value) {
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
        return value;
    }
  }
}

class LanguageNotifier extends ValueNotifier<String> {
  LanguageNotifier() : super(prefs.getString('language') ?? 'English');

  void setLanguage(String language) {
    value = language;
    prefs.setString('language', language);
  }
}

class UsernameNotifier extends ValueNotifier<String> {
  UsernameNotifier() : super(prefs.getString('username') ?? 'Alex Rivera');

  void setUsername(String name) {
    value = name;
    prefs.setString('username', name);
  }
}

class ProfileImageNotifier extends ValueNotifier<String?> {
  ProfileImageNotifier() : super(prefs.getString('profileImage'));

  void setImage(String? path) {
    value = path;
    if (path != null) {
      prefs.setString('profileImage', path);
    } else {
      prefs.remove('profileImage');
    }
  }
}

class NotificationsNotifier extends ValueNotifier<bool> {
  NotificationsNotifier() : super(prefs.getBool('notifications') ?? false);

  void toggle() {
    value = !value;
    prefs.setBool('notifications', value);
  }
}

final currencyNotifier = CurrencyNotifier();
final languageNotifier = LanguageNotifier();
final usernameNotifier = UsernameNotifier();
final profileImageNotifier = ProfileImageNotifier();
final notificationsNotifier = NotificationsNotifier();

class DailyDashApp extends StatelessWidget {
  const DailyDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
      title: 'DailyDash',
      theme: DailyDashTheme.darkTheme,
      home: const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final _dashboardKey = GlobalKey<DashboardScreenState>();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: ValueListenableBuilder<String>(
        valueListenable: currencyNotifier,
        builder: (context, currency, _) => ValueListenableBuilder<String?>(
          valueListenable: profileImageNotifier,
          builder: (context, profileImage, _) => IndexedStack(
            index: _currentIndex,
            children: [
              DashboardScreen(key: _dashboardKey),
              const AnalyticsScreen(),
              const SettingsScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLow,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.grid_view_rounded,
                  colors: colors,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.show_chart_rounded,
                  colors: colors,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.person_rounded,
                  colors: colors,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required DailyDashColorScheme colors,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0) {
          _dashboardKey.currentState?.loadData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.primary.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          color: isSelected ? colors.primary : colors.onSurfaceDim,
          size: 26,
        ),
      ),
    );
  }
}
