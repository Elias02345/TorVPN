import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0B0F14);
  static const backgroundHigh = Color(0xFF111821);
  static const surfaceLow = Color(0xFF121923);
  static const surface = Color(0xFF17212C);
  static const surfaceHigh = Color(0xFF202B37);
  static const surfaceWarm = Color(0xFF242119);
  static const border = Color(0xFF2F3D4B);
  static const borderStrong = Color(0xFF506172);
  static const cyan = Color(0xFF48C7E8);
  static const cyanSoft = Color(0xFF9FE9F6);
  static const violetGrey = Color(0xFFB8B7D9);
  static const good = Color(0xFF72D69A);
  static const warn = Color(0xFFFFC45D);
  static const danger = Color(0xFFFF6D74);
  static const textHigh = Color(0xFFF7FAFC);
  static const textMuted = Color(0xFFB4C0CB);
  static const textFaint = Color(0xFF7D8A97);
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
      fontFamily: 'Segoe UI',
      colorScheme: scheme.copyWith(
        primary: AppColors.cyan,
        secondary: AppColors.good,
        error: AppColors.danger,
        surface: AppColors.surface,
      ),
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: AppColors.border,
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
        indicatorColor: AppColors.cyan.withValues(alpha: 0.13),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? AppColors.textHigh
                : AppColors.textMuted,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
            letterSpacing: 0,
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
                ? AppColors.cyan.withValues(alpha: 0.15)
                : AppColors.surfaceLow,
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
          textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.cyan,
          foregroundColor: const Color(0xFF061016),
          disabledBackgroundColor: AppColors.surfaceHigh,
          disabledForegroundColor: AppColors.textFaint,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 0,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.cyanSoft,
          side: const BorderSide(color: AppColors.borderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceHigh,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cyan),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceHigh,
        selectedColor: AppColors.cyan.withValues(alpha: 0.16),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: const TextStyle(
          color: AppColors.textHigh,
          fontWeight: FontWeight.w700,
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          color: AppColors.textHigh,
          fontWeight: FontWeight.w900,
          fontSize: 32,
          height: 1.08,
          letterSpacing: 0,
        ),
        headlineSmall: TextStyle(
          color: AppColors.textHigh,
          fontWeight: FontWeight.w900,
          fontSize: 24,
          height: 1.15,
          letterSpacing: 0,
        ),
        titleLarge: TextStyle(
          color: AppColors.textHigh,
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: 0,
        ),
        titleMedium: TextStyle(
          color: AppColors.textHigh,
          fontWeight: FontWeight.w800,
          fontSize: 16,
          letterSpacing: 0,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textHigh,
          fontSize: 15,
          height: 1.45,
          letterSpacing: 0,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          height: 1.45,
          letterSpacing: 0,
        ),
        bodySmall: TextStyle(
          color: AppColors.textFaint,
          fontSize: 12,
          height: 1.35,
          letterSpacing: 0,
        ),
        labelLarge: TextStyle(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          fontSize: 13,
        ),
      ),
    );
  }
}
