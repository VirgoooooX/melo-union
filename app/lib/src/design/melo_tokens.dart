import 'package:flutter/material.dart';

/// Central visual tokens for the approved MeloUnion light design direction.
///
/// Keep page code free of ad-hoc colors and spacing values where possible.
abstract final class MeloColors {
  static const canvas = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF8FAFC);
  static const border = Color(0xFFE6E9EE);

  static const primary700 = Color(0xFF0B8A81);
  static const primary600 = Color(0xFF0EA59A);
  static const primary500 = Color(0xFF14B8A6);
  static const primary100 = Color(0xFFCFF3EE);
  static const primary50 = Color(0xFFEAF8F6);

  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);

  static const favorite = Color(0xFFF05252);
  static const warning = Color(0xFFF59E0B);
  static const success = Color(0xFF22C55E);
  static const info = Color(0xFF3B82F6);
  static const error = Color(0xFFDC2626);

  static const neteaseForeground = Color(0xFFE95555);
  static const neteaseBackground = Color(0xFFFFF0F0);
  static const qqForeground = Color(0xFF238B4E);
  static const qqBackground = Color(0xFFECF8F0);
  static const localForeground = Color(0xFF2563EB);
  static const localBackground = Color(0xFFEEF4FF);
  static const mixedForeground = Color(0xFF0F9F8A);
  static const mixedBackground = Color(0xFFEAF8F6);
}

abstract final class MeloSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 40.0;
  static const page = 48.0;
}

abstract final class MeloRadii {
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(24));
}

abstract final class MeloDimensions {
  static const desktopSidebarWidth = 208.0;
  static const desktopNowPlayingWidth = 300.0;
  static const desktopPlayerBarHeight = 76.0;
  static const desktopProviderTabsHeight = 44.0;

  static const mobileAppBarHeight = 56.0;
  static const mobileProviderTabsHeight = 48.0;
  static const mobileMiniPlayerHeight = 64.0;
  static const mobileBottomNavigationHeight = 72.0;
}
