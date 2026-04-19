import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_preview/device_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;
import 'config/supabase_config.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/login_screen.dart';
import 'database/data_repository.dart';
import 'database/in_memory_repository.dart';
import 'database/database_helper.dart';
import 'database/hybrid_repository.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';

late final DataRepository repo;
late final SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences for settings persistence
  prefs = await SharedPreferences.getInstance();

  // Initialize Supabase (no-op when credentials are not yet configured).
  await SupabaseService.instance.initialize();
  AuthService.instance.initialize();

  // Use in-memory on web (sqflite WASM is unreliable), SQLite on native.
  // When Supabase is configured we wrap the local store in HybridRepository so
  // every write is mirrored to the cloud and reads stay offline-first.
  if (kIsWeb) {
    repo = InMemoryRepository.instance;
  } else {
    // Pre-initialize the database to ensure it's ready
    await DatabaseHelper.instance.database;
    repo = SupabaseConfig.isConfigured
        ? HybridRepository.instance
        : DatabaseHelper.instance;
  }

  // Kick off connectivity-driven sync (no-op until the user signs in).
  SyncService.instance.initialize();

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

class DarkModeNotifier extends ValueNotifier<bool> {
  DarkModeNotifier() : super(prefs.getBool('darkMode') ?? true);

  void toggle() {
    value = !value;
    prefs.setBool('darkMode', value);
  }
}

class BudgetNotifier extends ValueNotifier<double> {
  BudgetNotifier() : super(_initBudget());

  static double _initBudget() {
    // Check if we need to reset for a new month
    final savedMonth = prefs.getInt('budgetMonth');
    final savedYear = prefs.getInt('budgetYear');
    final now = DateTime.now();

    if (savedMonth != null && savedYear != null) {
      // If it's a new month, keep the same budget (don't reset value)
      // Just update the month/year tracking
      if (savedMonth != now.month || savedYear != now.year) {
        prefs.setInt('budgetMonth', now.month);
        prefs.setInt('budgetYear', now.year);
      }
    } else {
      // First time - set current month/year
      prefs.setInt('budgetMonth', now.month);
      prefs.setInt('budgetYear', now.year);
    }

    return prefs.getDouble('monthlyBudget') ?? 0;
  }

  void setBudget(double budget) {
    value = budget;
    prefs.setDouble('monthlyBudget', budget);
    final now = DateTime.now();
    prefs.setInt('budgetMonth', now.month);
    prefs.setInt('budgetYear', now.year);
  }

  bool get isSet => value > 0;
}

final currencyNotifier = CurrencyNotifier();
final languageNotifier = LanguageNotifier();
final usernameNotifier = UsernameNotifier();
final profileImageNotifier = ProfileImageNotifier();
final notificationsNotifier = NotificationsNotifier();
final darkModeNotifier = DarkModeNotifier();
final budgetNotifier = BudgetNotifier();

// Navigation notifier to switch tabs from child screens
final navigationIndexNotifier = ValueNotifier<int>(0);

class DailyDashApp extends StatelessWidget {
  const DailyDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDarkMode, _) {
        return MaterialApp(
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          debugShowCheckedModeBanner: false,
          title: 'DailyDash',
          theme: isDarkMode ? DailyDashTheme.darkTheme : DailyDashTheme.lightTheme,
          home: const _AuthGate(),
        );
      },
    );
  }
}

/// Auth Guard: shows [LoginScreen] when Supabase is configured but no user is
/// signed in, otherwise shows the normal [MainShell]. When Supabase has not
/// been configured (developer is running pure-offline) the guard is a no-op
/// and forwards directly to [MainShell] so the app remains usable.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    if (!SupabaseConfig.isConfigured) {
      return const MainShell();
    }
    return ValueListenableBuilder<User?>(
      valueListenable: AuthService.instance.currentUserNotifier,
      builder: (context, user, _) {
        if (user == null) return const LoginScreen();
        return const MainShell();
      },
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
  final _analyticsKey = GlobalKey<AnalyticsScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = navigationIndexNotifier.value;
    navigationIndexNotifier.addListener(_onNavigationChange);
    darkModeNotifier.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    navigationIndexNotifier.removeListener(_onNavigationChange);
    darkModeNotifier.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onNavigationChange() {
    if (navigationIndexNotifier.value != _currentIndex) {
      setState(() {
        _currentIndex = navigationIndexNotifier.value;
      });
      // Reload data when switching tabs
      if (_currentIndex == 0) {
        _dashboardKey.currentState?.loadData();
      } else if (_currentIndex == 1) {
        _analyticsKey.currentState?.loadData();
      }
    }
  }

  void _onThemeChange() {
    setState(() {});
  }

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
              AnalyticsScreen(key: _analyticsKey),
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
        } else if (index == 1) {
          _analyticsKey.currentState?.loadData();
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
