import 'dart:io';

import 'package:melo_union_app/src/bootstrap/qq_music_background_refresh.dart';
import 'package:melo_union_app/src/platform/windows_qq_refresh_task_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory temporaryDirectory;

  setUp(() async {
    temporaryDirectory =
        await Directory.systemTemp.createTemp('melo_qq_task_test_');
  });

  tearDown(() async {
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('registers an hourly hidden refresh task for an existing session',
      () async {
    final calls = <_ProcessCall>[];
    final controller = WindowsQqRefreshTaskController(
      supportedOverride: true,
      executablePath: r'C:\Program Files\MeloUnion\MeloUnion.exe',
      stateFile: File('${temporaryDirectory.path}/state.json'),
      processRunner: (executable, arguments) async {
        calls.add(_ProcessCall(executable, arguments));
        return ProcessResult(1, 0, '', '');
      },
    );

    await controller.initialize(hasQqSession: true);

    expect(controller.desiredEnabled, isTrue);
    expect(controller.taskRegistered, isTrue);
    expect(calls, hasLength(1));
    expect(calls.single.executable, 'schtasks.exe');
    expect(calls.single.arguments,
        containsAllInOrder(['/Create', '/SC', 'HOURLY']));
    final action =
        calls.single.arguments[calls.single.arguments.indexOf('/TR') + 1];
    expect(action, contains(r'"C:\Program Files\MeloUnion\MeloUnion.exe"'));
    expect(action, contains('--refresh-qq-and-exit'));
    expect(action, isNot(contains('Cookie')));
  });

  test('disabling refresh removes an existing scheduled task', () async {
    final calls = <_ProcessCall>[];
    final controller = WindowsQqRefreshTaskController(
      supportedOverride: true,
      stateFile: File('${temporaryDirectory.path}/state.json'),
      processRunner: (executable, arguments) async {
        calls.add(_ProcessCall(executable, arguments));
        return ProcessResult(1, 0, '', '');
      },
    );
    await controller.initialize(hasQqSession: true);
    calls.clear();

    await controller.setEnabled(false);

    expect(controller.desiredEnabled, isFalse);
    expect(controller.taskRegistered, isFalse);
    expect(calls.map((call) => call.arguments.first), ['/Query', '/Delete']);
  });

  test('does not register a task until a QQ session exists', () async {
    final calls = <_ProcessCall>[];
    final controller = WindowsQqRefreshTaskController(
      supportedOverride: true,
      stateFile: File('${temporaryDirectory.path}/state.json'),
      processRunner: (executable, arguments) async {
        calls.add(_ProcessCall(executable, arguments));
        return ProcessResult(1, 1, '', '');
      },
    );

    await controller.initialize(hasQqSession: false);

    expect(controller.desiredEnabled, isTrue);
    expect(controller.taskRegistered, isFalse);
    expect(calls.single.arguments.first, '/Query');
  });

  test('persists a redacted background refresh result', () async {
    final stateFile = File('${temporaryDirectory.path}/state.json');
    final controller = WindowsQqRefreshTaskController(
      supportedOverride: true,
      stateFile: stateFile,
      processRunner: (executable, arguments) async =>
          ProcessResult(1, 1, '', ''),
    );
    await controller.recordRefreshOutcome(
      const QqMusicBackgroundRefreshOutcome(
        status: QqMusicBackgroundRefreshStatus.failed,
        message: 'QQConnect 返回码 0/20002',
      ),
      occurredAt: DateTime.utc(2026, 8, 5, 10),
    );

    final restored = WindowsQqRefreshTaskController(
      supportedOverride: true,
      stateFile: stateFile,
      processRunner: (executable, arguments) async =>
          ProcessResult(1, 1, '', ''),
    );
    await restored.initialize(hasQqSession: false);

    expect(restored.lastRunAt, DateTime.utc(2026, 8, 5, 10));
    expect(restored.lastStatus, QqMusicBackgroundRefreshStatus.failed);
    expect(restored.lastMessage, 'QQConnect 返回码 0/20002');
  });
}

final class _ProcessCall {
  const _ProcessCall(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
}
