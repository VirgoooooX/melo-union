import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'src/app.dart';
import 'src/bootstrap/app_bootstrap.dart';
import 'src/bootstrap/demo_repository.dart';

class MeloHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  }
}

Future<void> main() async {
  HttpOverrides.global = MeloHttpOverrides();
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
