import 'package:flutter/material.dart';

import 'melo_tokens.dart';

abstract final class MeloTheme {
  static ThemeData light() {
    const colorScheme = ColorScheme.light(
      primary: MeloColors.primary600,
      onPrimary: Colors.white,
      secondary: MeloColors.info,
      onSecondary: Colors.white,
      surface: MeloColors.surface,
      onSurface: MeloColors.textPrimary,
      error: MeloColors.error,
      onError: Colors.white,
    );

    final baseTextTheme = Typography.material2021().black.apply(
      bodyColor: MeloColors.textPrimary,
      displayColor: MeloColors.textPrimary,
      fontFamilyFallback: const <String>[
        'Microsoft YaHei UI',
        'Microsoft YaHei',
        'Noto Sans CJK SC',
        'sans-serif',
      ],
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: MeloColors.canvas,
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 16,
          height: 1.5,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 14,
          height: 1.45,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: MeloColors.textSecondary,
          fontSize: 12,
          height: 1.5,
        ),
      ),
      dividerColor: MeloColors.border,
      cardTheme: const CardThemeData(
        color: MeloColors.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: MeloRadii.lg),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MeloColors.surface,
        hintStyle: const TextStyle(color: MeloColors.textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MeloSpacing.md,
          vertical: MeloSpacing.sm,
        ),
        border: const OutlineInputBorder(
          borderRadius: MeloRadii.sm,
          borderSide: BorderSide(color: MeloColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: MeloRadii.sm,
          borderSide: BorderSide(color: MeloColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: MeloRadii.sm,
          borderSide: BorderSide(color: MeloColors.primary500, width: 2),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: MeloColors.surface,
        selectedIconTheme: IconThemeData(color: MeloColors.primary700),
        selectedLabelTextStyle: TextStyle(
          color: MeloColors.primary700,
          fontWeight: FontWeight.w600,
        ),
        unselectedIconTheme: IconThemeData(color: MeloColors.textSecondary),
        unselectedLabelTextStyle: TextStyle(color: MeloColors.textPrimary),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: MeloColors.surface,
        indicatorColor: MeloColors.primary50,
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: MeloColors.primary700,
        unselectedLabelColor: MeloColors.textSecondary,
        indicatorColor: MeloColors.primary600,
        dividerColor: MeloColors.border,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: MeloColors.textPrimary,
        contentTextStyle: TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: MeloRadii.md),
      ),
    );
  }
}
