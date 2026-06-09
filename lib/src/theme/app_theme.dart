import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF06111D);
  static const surfaceLow = Color(0xFF0A1826);
  static const surface = Color(0xFF0E2233);
  static const surfaceHigh = Color(0xFF132C40);
  static const border = Color(0xFF24435A);
  static const cyan = Color(0xFF35D4FF);
  static const cyanSoft = Color(0xFF8DEAFF);
  static const good = Color(0xFF5EE2A0);
  static const warn = Color(0xFFFFC857);
  static const danger = Color(0xFFFF6B6B);
  static const textHigh = Color(0xFFF4FBFF);
  static const textMuted = Color(0xFFA6B8C7);
}

class AppTheme {
  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.cyan,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: AppColors.cyan,
        secondary: AppColors.good,
        error: AppColors.danger,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surfaceLow,
        indicatorColor: AppColors.cyan.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.textHigh
                : AppColors.textMuted,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.cyan
              : AppColors.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.cyan.withValues(alpha: 0.25)
              : AppColors.surfaceHigh,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.cyan.withValues(alpha: 0.16)
                : AppColors.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? AppColors.textHigh
                : AppColors.textMuted,
          ),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.border),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: const Color(0xFF03111A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cyanSoft,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textHigh,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textHigh,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: AppColors.textHigh,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: AppColors.textHigh,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(color: AppColors.textHigh, letterSpacing: 0),
        bodyMedium: TextStyle(color: AppColors.textMuted, letterSpacing: 0),
        labelLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
      ),
    );
  }
}
