import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:device_preview/device_preview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/auth/login_screen.dart';
import 'database/data_repository.dart';
import 'database/in_memory_repository.dart';
import 'database/database_helper.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'services/profile_service.dart';

late final DataRepository repo;
late final SharedPreferences prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run SharedPreferences and Supabase initialization in parallel
  final results = await Future.wait([
    SharedPreferences.getInstance(),
    Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    ),
  ]);

  prefs = results[0] as SharedPreferences;

  // Use in-memory on web (sqflite WASM is unreliable), SQLite on native
  if (kIsWeb) {
    repo = InMemoryRepository.instance;
  } else {
    repo = DatabaseHelper.instance;
    // Initialize database in background - don't await
    (repo as DatabaseHelper).database;
  }

  // Initialize auth and sync services (these are fast, non-blocking)
  AuthService.instance.initialize();
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
    // Sync to Supabase
    ProfileService.instance.updateCurrency(currency);
  }

  void loadFromProfile(String currency) {
    value = currency;
    prefs.setString('currency', currency);
  }

  void clear() {
    value = 'INR';
    prefs.setString('currency', 'INR');
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
  UsernameNotifier() : super('User');

  void setUsername(String name) {
    value = name;
    // Don't save to prefs - use ProfileService for persistence
  }

  void loadFromProfile(String name) {
    value = name;
  }

  void clear() {
    value = 'User';
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

// Avatar notifier for profile avatar type - syncs with ProfileService
class AvatarNotifier extends ValueNotifier<AvatarType> {
  AvatarNotifier() : super(AvatarType.male);

  void setAvatar(AvatarType type) {
    value = type;
    ProfileService.instance.updateAvatarType(type);
  }

  void loadFromProfile(AvatarType type) {
    value = type;
  }

  void clear() {
    value = AvatarType.male;
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
    // Sync to Supabase
    ProfileService.instance.updateMonthlyBudget(budget);
  }

  void loadFromProfile(double budget) {
    value = budget;
    prefs.setDouble('monthlyBudget', budget);
    final now = DateTime.now();
    prefs.setInt('budgetMonth', now.month);
    prefs.setInt('budgetYear', now.year);
  }

  void clear() {
    value = 0;
    prefs.setDouble('monthlyBudget', 0);
  }

  bool get isSet => value > 0;
}

final currencyNotifier = CurrencyNotifier();
final languageNotifier = LanguageNotifier();
final usernameNotifier = UsernameNotifier();
final profileImageNotifier = ProfileImageNotifier();
final avatarNotifier = AvatarNotifier();
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
          theme: isDarkMode
              ? DailyDashTheme.darkTheme
              : DailyDashTheme.lightTheme,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Auth guard that shows login or main app based on auth state
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppAuthState>(
      valueListenable: AuthService.instance.authStateNotifier,
      builder: (context, authState, _) {
        switch (authState) {
          case AppAuthState.unknown:
            return const _LoadingScreen();
          case AppAuthState.authenticated:
            return const MainShell();
          case AppAuthState.unauthenticated:
            return const LoginScreen();
        }
      },
    );
  }
}

/// Loading screen shown while checking auth state - shows skeleton of dashboard
class _LoadingScreen extends StatefulWidget {
  const _LoadingScreen();

  @override
  State<_LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<_LoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar skeleton
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
                          _buildSkeletonBox(40, 40, colors, isCircle: true),
                          const SizedBox(width: 12),
                          _buildSkeletonBox(100, 20, colors),
                        ],
                      ),
                      _buildSkeletonBox(24, 24, colors, isCircle: true),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Total Spent Card skeleton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSkeletonBox(
                    double.infinity,
                    160,
                    colors,
                    borderRadius: 24,
                  ),
                ),

                const SizedBox(height: 20),

                // Savings & Budget Row skeleton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSkeletonBox(
                          double.infinity,
                          120,
                          colors,
                          borderRadius: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSkeletonBox(
                          double.infinity,
                          120,
                          colors,
                          borderRadius: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Recent Transactions Header skeleton
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSkeletonBox(160, 20, colors),
                      _buildSkeletonBox(60, 14, colors),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Transaction items skeleton
                ...List.generate(
                  3,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: _buildSkeletonBox(
                      double.infinity,
                      76,
                      colors,
                      borderRadius: 20,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonBox(
    double width,
    double height,
    DailyDashColorScheme colors, {
    double borderRadius = 8,
    bool isCircle = false,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius:
                isCircle ? null : BorderRadius.circular(borderRadius),
            shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
            gradient: LinearGradient(
              begin: Alignment(_animation.value, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: [
                colors.surfaceContainerLow,
                colors.surfaceContainerHigh.withValues(alpha: 0.5),
                colors.surfaceContainerLow,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
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

    // Load user profile from Supabase
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    await ProfileService.instance.loadProfile();
    final profile = ProfileService.instance.profileNotifier.value;
    if (profile != null) {
      usernameNotifier.loadFromProfile(profile.displayName);
      avatarNotifier.loadFromProfile(profile.avatarType);
      budgetNotifier.loadFromProfile(profile.monthlyBudget);
      currencyNotifier.loadFromProfile(profile.currency);
    }
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
