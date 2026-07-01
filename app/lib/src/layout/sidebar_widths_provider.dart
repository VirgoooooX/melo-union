import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

class SidebarWidths {
  final double left;
  final double right;

  const SidebarWidths({required this.left, required this.right});
}

class SidebarWidthsNotifier extends StateNotifier<SidebarWidths> {
  SidebarWidthsNotifier()
      : super(const SidebarWidths(left: 216.0, right: 280.0)) {
    _load();
  }

  Future<File> _getSettingsFile() async {
    final environment = Platform.environment;
    Directory root;
    if (Platform.isWindows) {
      root = Directory(
        environment['APPDATA'] ??
            environment['LOCALAPPDATA'] ??
            Directory.systemTemp.path,
      );
    } else if (Platform.isMacOS) {
      final home = environment['HOME'];
      root = (home != null && home.isNotEmpty)
          ? Directory(p.join(home, 'Library', 'Application Support'))
          : Directory.systemTemp;
    } else if (Platform.isLinux) {
      final xdgDataHome = environment['XDG_DATA_HOME'];
      if (xdgDataHome != null && xdgDataHome.isNotEmpty) {
        root = Directory(xdgDataHome);
      } else {
        final home = environment['HOME'];
        root = (home != null && home.isNotEmpty)
            ? Directory(p.join(home, '.local', 'share'))
            : Directory.systemTemp;
      }
    } else {
      root = Directory.systemTemp;
    }
    final dir = Directory(p.join(root.path, 'MeloUnion'));
    await dir.create(recursive: true);
    return File(p.join(dir.path, 'sidebar_settings.json'));
  }

  Future<void> _load() async {
    try {
      final file = await _getSettingsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        state = SidebarWidths(
          left: (json['left'] as num?)?.toDouble() ?? 216.0,
          right: (json['right'] as num?)?.toDouble() ?? 280.0,
        );
      }
    } catch (_) {}
  }

  Future<void> updateLeft(double width) async {
    final clamped = width.clamp(160.0, 360.0);
    state = SidebarWidths(left: clamped, right: state.right);
    _save();
  }

  Future<void> updateRight(double width) async {
    final clamped = width.clamp(200.0, 420.0);
    state = SidebarWidths(left: state.left, right: clamped);
    _save();
  }

  Future<void> _save() async {
    try {
      final file = await _getSettingsFile();
      await file.writeAsString(jsonEncode({
        'left': state.left,
        'right': state.right,
      }));
    } catch (_) {}
  }
}

final sidebarWidthsProvider =
    StateNotifierProvider<SidebarWidthsNotifier, SidebarWidths>((ref) {
  return SidebarWidthsNotifier();
});
