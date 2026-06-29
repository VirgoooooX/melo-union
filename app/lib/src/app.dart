import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bootstrap/demo_repository.dart';
import 'design/melo_theme.dart';

class MeloUnionApp extends ConsumerWidget {
  const MeloUnionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'MeloUnion',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: MeloTheme.light(),
      routerConfig: router,
    );
  }
}
