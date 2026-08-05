import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:window_manager/window_manager.dart';

import 'src/app.dart';
import 'src/bootstrap/app_bootstrap.dart';
import 'src/bootstrap/demo_repository.dart';
import 'src/bootstrap/qq_music_background_refresh.dart';
import 'src/bootstrap/qq_music_session_store_factory.dart';
import 'src/platform/desktop_lifecycle_controller.dart';
import 'src/platform/windows_qq_refresh_task_controller.dart';

class MeloHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..userAgent =
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';
  }
}

Future<void> main(List<String> arguments) async {
  HttpOverrides.global = MeloHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows && arguments.contains('--refresh-qq-and-exit')) {
    final exitCode = await _runScheduledQqMusicRefresh();
    exit(exitCode);
  }

  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.melounion.app.channel.audio',
      androidNotificationChannelName: 'MeloUnion 播放',
      androidNotificationOngoing: true,
    );
  }

  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1600, 1000),
      minimumSize: Size(960, 640),
      center: true,
      backgroundColor: Colors.transparent,
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions);
    await windowManager.setAsFrameless();
    if (Platform.isWindows) {
      await desktopLifecycleController.initialize();
    }
    final startHidden =
        arguments.contains('--hidden') && desktopLifecycleController.trayReady;
    if (startHidden) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }

  final bootstrap = await createAppBootstrap();
  if (Platform.isWindows) {
    desktopLifecycleController.setExitHandler(bootstrap.close);
    bootstrap.repository.setQqSessionLifecycleCallback(
      windowsQqRefreshTaskController.onQqSessionChanged,
    );
    await windowsQqRefreshTaskController.initialize(
      hasQqSession: bootstrap.repository.hasQqMusicSession,
    );
  }

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

Future<int> _runScheduledQqMusicRefresh() async {
  final outcome = await refreshQqMusicCredentialsInBackground(
    sessionStore: createQqMusicSessionStore(),
  );
  await windowsQqRefreshTaskController.recordRefreshOutcome(outcome);
  return outcome.taskSucceeded ? 0 : 2;
}
