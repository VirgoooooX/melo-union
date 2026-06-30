import 'package:flutter/material.dart';

/// Central visual tokens for the approved MeloUnion light design direction.
///
/// Keep page code free of ad-hoc colors and spacing values where possible.
abstract final class MeloColors {
  static const canvas = Color(0xFFF6F8FB);
  static const canvasSoft = Color(0xFFFAFBFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceMuted = Color(0xFFF7F9FC);
  static const surfaceHover = Color(0xFFF2F7F7);
  static const surfaceSelected = Color(0xFFEAF8F6);
  static const border = Color(0xFFE7ECF1);
  static const borderStrong = Color(0xFFDDE4EA);

  static const primary700 = Color(0xFF087C76);
  static const primary600 = Color(0xFF0AA69A);
  static const primary500 = Color(0xFF18B8AA);
  static const primary300 = Color(0xFF9CE3DA);
  static const primary100 = Color(0xFFCFF3EE);
  static const primary50 = Color(0xFFEAF8F6);

  static const textPrimary = Color(0xFF1C2736);
  static const textSecondary = Color(0xFF667085);
  static const textTertiary = Color(0xFF98A2B3);
  static const textQuaternary = Color(0xFFB2BAC6);

  static const favorite = Color(0xFFF0525B);
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
  static const window = BorderRadius.all(Radius.circular(18));
  static const xl = BorderRadius.all(Radius.circular(24));
  static const pill = BorderRadius.all(Radius.circular(999));
}

abstract final class MeloShadows {
  static const card = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A1C2736),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
  ];

  static const floating = <BoxShadow>[
    BoxShadow(
      color: Color(0x121C2736),
      blurRadius: 28,
      offset: Offset(0, 12),
    ),
  ];

  static const control = <BoxShadow>[
    BoxShadow(
      color: Color(0x0C087C76),
      blurRadius: 10,
      offset: Offset(0, 4),
    ),
  ];
}

abstract final class MeloDimensions {
  static const desktopSidebarWidth = 216.0;
  static const desktopNowPlayingWidth = 280.0;
  static const desktopPlayerBarHeight = 82.0;
  static const desktopProviderTabsHeight = 46.0;

  static const mobileAppBarHeight = 56.0;
  static const mobileProviderTabsHeight = 48.0;
  static const mobileMiniPlayerHeight = 64.0;
  static const mobileBottomNavigationHeight = 72.0;
}
