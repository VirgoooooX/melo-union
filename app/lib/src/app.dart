import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'design/melo_theme.dart';
import 'presentation/ui_router.dart';

class MeloUnionApp extends ConsumerWidget {
  const MeloUnionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'MeloUnion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: MeloTheme.light(),
      routerConfig: ref.watch(uiRouterProvider),
    );
  }
}
