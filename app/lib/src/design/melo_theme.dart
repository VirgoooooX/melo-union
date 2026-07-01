import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'melo_tokens.dart';

abstract final class MeloTheme {
  static ThemeData light() {
    const fontFallback = <String>[
      'Noto Sans SC',
      'PingFang SC',
      'Hiragino Sans GB',
      'Microsoft YaHei UI',
      'Microsoft YaHei',
      'sans-serif',
    ];
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

    final materialTextTheme = Typography.material2021().black.apply(
          bodyColor: MeloColors.textPrimary,
          displayColor: MeloColors.textPrimary,
        );
    GoogleFonts.getFont('Noto Sans SC');
    final baseTextTheme = GoogleFonts.getTextTheme(
      'Geist',
      materialTextTheme,
    ).apply(
      bodyColor: MeloColors.textPrimary,
      displayColor: MeloColors.textPrimary,
      fontFamilyFallback: fontFallback,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.getFont('Geist').fontFamily,
      fontFamilyFallback: fontFallback,
      scaffoldBackgroundColor: MeloColors.canvas,
      splashFactory: InkSparkle.splashFactory,
      textTheme: baseTextTheme.copyWith(
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 16,
          height: 1.45,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          fontSize: 14,
          height: 1.48,
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: MeloColors.textSecondary,
          fontSize: 12,
          height: 1.45,
          fontWeight: FontWeight.w500,
        ),
      ),
      dividerColor: MeloColors.border,
      iconTheme: const IconThemeData(color: MeloColors.textSecondary),
      cardTheme: const CardThemeData(
        color: MeloColors.surface,
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: MeloRadii.lg),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: MeloColors.surface,
        hintStyle: const TextStyle(
          color: MeloColors.textTertiary,
          fontWeight: FontWeight.w500,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MeloSpacing.md,
          vertical: MeloSpacing.sm,
        ),
        border: const OutlineInputBorder(
          borderRadius: MeloRadii.md,
          borderSide: BorderSide(color: MeloColors.border),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: MeloRadii.md,
          borderSide: BorderSide(color: MeloColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: MeloRadii.md,
          borderSide: BorderSide(color: MeloColors.primary500, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MeloColors.primary600,
          foregroundColor: Colors.white,
          disabledBackgroundColor: MeloColors.primary100,
          disabledForegroundColor: MeloColors.primary700.withValues(alpha: .45),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MeloColors.textPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          side: const BorderSide(color: MeloColors.borderStrong),
          shape: const RoundedRectangleBorder(borderRadius: MeloRadii.md),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: MeloColors.surface,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: MeloRadii.md),
        textStyle: TextStyle(color: MeloColors.textPrimary),
      ),
      tooltipTheme: const TooltipThemeData(
        decoration: BoxDecoration(
          color: MeloColors.textPrimary,
          borderRadius: MeloRadii.sm,
        ),
        textStyle: TextStyle(color: Colors.white, fontSize: 12),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(MeloColors.borderStrong),
        radius: const Radius.circular(999),
        thickness: WidgetStateProperty.all(5),
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
          TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: MeloColors.primary700,
        unselectedLabelColor: MeloColors.textSecondary,
        indicatorColor: MeloColors.primary600,
        dividerColor: MeloColors.border,
        labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: MeloColors.surface,
        contentTextStyle: TextStyle(color: MeloColors.textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: MeloRadii.md,
          side: BorderSide(color: MeloColors.border),
        ),
      ),
    );
  }
}
