import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Extension to get theme-aware colors from BuildContext
extension DailyDashColorsExtension on BuildContext {
  DailyDashColorScheme get colors {
    return DailyDashColorScheme.dark();
  }
}

// The "Neon Nocturne" Design System Color Scheme
class DailyDashColorScheme {
  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color surfaceContainerLow;
  final Color surfaceContainerHigh;
  final Color surfaceContainerHighest;
  final Color surfaceVariant;
  final Color primary;
  final Color primaryContainer;
  final Color primaryDim;
  final Color secondary;
  final Color secondaryContainer;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color onSurfaceDim;
  final Color outlineVariant;
  final Color error;
  final Color success;

  // Chart colors
  final Color chartPurple;
  final Color chartCyan;
  final Color chartPink;
  final Color chartOrange;

  const DailyDashColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.surfaceContainerLow,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceVariant,
    required this.primary,
    required this.primaryContainer,
    required this.primaryDim,
    required this.secondary,
    required this.secondaryContainer,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.onSurfaceDim,
    required this.outlineVariant,
    required this.error,
    required this.success,
    required this.chartPurple,
    required this.chartCyan,
    required this.chartPink,
    required this.chartOrange,
  });

  // The "Neon Nocturne" Dark Theme
  factory DailyDashColorScheme.dark() => const DailyDashColorScheme(
    // Surface hierarchy - True Black foundation
    background: Color(0xFF0E0E0E),
    surface: Color(0xFF0E0E0E),
    surfaceContainer: Color(0xFF191919),
    surfaceContainerLow: Color(0xFF1A1A1A),
    surfaceContainerHigh: Color(0xFF262626),
    surfaceContainerHighest: Color(0xFF2E2E2E),
    surfaceVariant: Color(0xFF1E1E1E),

    // Primary - Electric Purple
    primary: Color(0xFFDB90FF),
    primaryContainer: Color(0xFFD37BFF),
    primaryDim: Color(0xFFB86FE0),

    // Secondary - Cyan
    secondary: Color(0xFF04C4FE),
    secondaryContainer: Color(0xFF0A3D4F),

    // Text colors
    onSurface: Color(0xFFE8E8E8),
    onSurfaceVariant: Color(0xFFABABAB),
    onSurfaceDim: Color(0xFF6B6B6B),

    // Outlines - Ghost borders
    outlineVariant: Color(0xFF404040),

    // Status colors
    error: Color(0xFFFF6E84),
    success: Color(0xFF04C4FE),

    // Chart colors
    chartPurple: Color(0xFFDB90FF),
    chartCyan: Color(0xFF04C4FE),
    chartPink: Color(0xFFFF6B9D),
    chartOrange: Color(0xFFFFB347),
  );
}

class DailyDashTheme {
  static ThemeData get darkTheme {
    final colors = DailyDashColorScheme.dark();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme.dark(
        surface: colors.surface,
        primary: colors.primary,
        primaryContainer: colors.primaryContainer,
        secondary: colors.secondary,
        secondaryContainer: colors.secondaryContainer,
        onSurface: colors.onSurface,
        onSurfaceVariant: colors.onSurfaceVariant,
        outline: colors.outlineVariant,
        error: colors.error,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colors.surfaceContainerLow,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceDim,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
