import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/bootstrap/app_bootstrap.dart';
import 'src/bootstrap/demo_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bootstrap = await createAppBootstrap();

  runApp(
    ProviderScope(
      overrides: [
        demoRepositoryProvider.overrideWith((ref) {
          ref.onDispose(() {
            unawaited(bootstrap.close());
          });
          return bootstrap.repository;
        }),
      ],
      child: const MeloUnionApp(),
    ),
  );
}
