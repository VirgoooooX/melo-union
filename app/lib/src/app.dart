import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/demo_repository.dart';

class MeloUnionApp extends ConsumerWidget {
  const MeloUnionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    const baseScheme = ColorScheme.dark(
      primary: Color(0xFF4DD0E1),
      secondary: Color(0xFFFFB74D),
      tertiary: Color(0xFFF06292),
      surface: Color(0xFF12161D),
      onPrimary: Color(0xFF001C21),
      onSecondary: Color(0xFF2E1700),
      onSurface: Color(0xFFE8EEF5),
    );

    return MaterialApp.router(
      title: 'MeloUnion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: baseScheme,
        scaffoldBackgroundColor: const Color(0xFF0C1015),
        textTheme: Typography.whiteMountainView.apply(
          bodyColor: baseScheme.onSurface,
          displayColor: baseScheme.onSurface,
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF161C24),
          margin: EdgeInsets.zero,
        ),
        dividerColor: const Color(0xFF2B3440),
      ),
      routerConfig: router,
    );
  }
}
