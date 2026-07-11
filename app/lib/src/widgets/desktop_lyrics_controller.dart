import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;

import '../bootstrap/demo_repository.dart';
import 'lyrics_provider.dart';

final desktopLyricsVisibleProvider = StateProvider<bool>((ref) => false);
final desktopLyricsLockedProvider = StateProvider<bool>((ref) => false);
final desktopLyricsModeProvider = StateProvider<String>((ref) => 'double');
final desktopLyricsOpacityProvider = StateProvider<double>((ref) => 1.0);
final desktopLyricsShowCardProvider = StateProvider<bool>((ref) => true);
final desktopLyricsFontScaleProvider = StateProvider<double>((ref) => 1.0);

const _desktopLyricsChannel = MethodChannel('melo_union/desktop_lyrics');

class DesktopLyricsSettings {
  final bool locked;
  final String mode;
  final double opacity;
  final bool showCard;
  final double fontScale;

  DesktopLyricsSettings({
    required this.locked,
    required this.mode,
    required this.opacity,
    required this.showCard,
    required this.fontScale,
  });

  Map<String, dynamic> toJson() => {
        'locked': locked,
        'mode': mode,
        'opacity': opacity,
        'showCard': showCard,
        'fontScale': fontScale,
      };

  factory DesktopLyricsSettings.fromJson(Map<String, dynamic> json) =>
      DesktopLyricsSettings(
        locked: json['locked'] as bool? ?? false,
        mode: json['mode'] as String? ?? 'double',
        opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
        showCard: json['showCard'] as bool? ?? true,
        fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
      );
}

Future<File> _getSettingsFile() async {
  final root = Platform.environment['APPDATA'] ??
      Platform.environment['LOCALAPPDATA'] ??
      Directory.systemTemp.path;
  final dir = Directory(path.join(root, 'MeloUnion'));
  await dir.create(recursive: true);
  return File(path.join(dir.path, 'desktop_lyrics_settings.json'));
}

Future<void> saveDesktopLyricsSettings(DesktopLyricsSettings settings) async {
  try {
    final file = await _getSettingsFile();
    await file.writeAsString(jsonEncode(settings.toJson()));
  } catch (e) {
    debugPrint('Failed to save desktop lyrics settings: $e');
  }
}

Future<DesktopLyricsSettings> loadDesktopLyricsSettings() async {
  try {
    final file = await _getSettingsFile();
    if (await file.exists()) {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return DesktopLyricsSettings.fromJson(json);
    }
  } catch (e) {
    debugPrint('Failed to load desktop lyrics settings: $e');
  }
  return DesktopLyricsSettings(locked: false, mode: 'double', opacity: 1.0, showCard: true, fontScale: 1.0);
}

class DesktopLyricsBridge extends ConsumerStatefulWidget {
  const DesktopLyricsBridge({super.key});

  @override
  ConsumerState<DesktopLyricsBridge> createState() =>
      _DesktopLyricsBridgeState();
}

class _DesktopLyricsBridgeState extends ConsumerState<DesktopLyricsBridge> {
  StreamSubscription<Duration>? _positionSubscription;
  List<_DesktopLyricLine> _lines = const [];
  int _lastIndex = -1;
  bool _isSyncingFromNative = false;

  @override
  void initState() {
    super.initState();
    if (!Platform.isWindows) return;

    _desktopLyricsChannel.setMethodCallHandler((call) async {
      if (call.method == 'settingChanged' && mounted) {
        final args = call.arguments as Map;
        final locked = args['locked'] as bool;
        final opacity = (args['opacity'] as num).toDouble();
        final doubleLine = args['doubleLine'] as bool;
        final showCard = args['showCard'] as bool? ?? true;
        final fontScale = (args['fontScale'] as num?)?.toDouble() ?? 1.0;
        final mode = doubleLine ? 'double' : 'single';

        _isSyncingFromNative = true;
        try {
          ref.read(desktopLyricsLockedProvider.notifier).state = locked;
          ref.read(desktopLyricsModeProvider.notifier).state = mode;
          ref.read(desktopLyricsOpacityProvider.notifier).state = opacity;
          ref.read(desktopLyricsShowCardProvider.notifier).state = showCard;
          ref.read(desktopLyricsFontScaleProvider.notifier).state = fontScale;
        } finally {
          _isSyncingFromNative = false;
        }

        await saveDesktopLyricsSettings(DesktopLyricsSettings(
          locked: locked,
          mode: mode,
          opacity: opacity,
          showCard: showCard,
          fontScale: fontScale,
        ));
      }
    });

    // Load persisted settings and sync to C++
    Future(() async {
      final settings = await loadDesktopLyricsSettings();
      if (mounted) {
        _isSyncingFromNative = true;
        try {
          ref.read(desktopLyricsLockedProvider.notifier).state = settings.locked;
          ref.read(desktopLyricsModeProvider.notifier).state = settings.mode;
          ref.read(desktopLyricsOpacityProvider.notifier).state = settings.opacity;
          ref.read(desktopLyricsShowCardProvider.notifier).state = settings.showCard;
          ref.read(desktopLyricsFontScaleProvider.notifier).state = settings.fontScale;
        } finally {
          _isSyncingFromNative = false;
        }
        await _syncSettings();
      }
    });

    final repository = ref.read(demoRepositoryProvider);
    _positionSubscription = repository.positionStream.listen(_updatePosition);
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    if (Platform.isWindows) {
      _desktopLyricsChannel.setMethodCallHandler(null);
      unawaited(_desktopLyricsChannel.invokeMethod<void>('hide'));
    }
    super.dispose();
  }

  void _updatePosition(Duration position) {
    if (!mounted || _lines.isEmpty) return;
    final index = _activeLyricIndex(_lines, position);
    if (index == _lastIndex) return;
    _lastIndex = index;
    unawaited(_sendLines(index));
  }

  Future<void> _sendLines(int index) async {
    if (!Platform.isWindows || _lines.isEmpty) return;
    await _desktopLyricsChannel.invokeMethod<void>('update', {
      'current': _lines[index].text,
      'next': index + 1 < _lines.length ? _lines[index + 1].text : '',
    });
  }

  Future<void> _syncSettings() async {
    if (!Platform.isWindows) return;
    final locked = ref.read(desktopLyricsLockedProvider);
    final mode = ref.read(desktopLyricsModeProvider);
    final opacity = ref.read(desktopLyricsOpacityProvider);
    final showCard = ref.read(desktopLyricsShowCardProvider);
    final fontScale = ref.read(desktopLyricsFontScaleProvider);

    await _desktopLyricsChannel.invokeMethod<void>('setSettings', {
      'locked': locked,
      'opacity': opacity,
      'doubleLine': mode == 'double',
      'showCard': showCard,
      'fontScale': fontScale,
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) return const SizedBox.shrink();

    final visible = ref.watch(desktopLyricsVisibleProvider);
    final repository = ref.read(demoRepositoryProvider);
    final track = ref.watch(
      demoRepositoryProvider.select((value) => value.queue.current?.track),
    );
    final lyrics = track == null ? null : ref.watch(lyricsProvider(track.ref));

    ref.listen<bool>(desktopLyricsVisibleProvider, (_, next) {
      unawaited(
          _desktopLyricsChannel.invokeMethod<void>(next ? 'show' : 'hide'));
      if (next) {
        unawaited(_syncSettings());
      }
    });

    ref.listen<bool>(desktopLyricsLockedProvider, (_, next) {
      if (!_isSyncingFromNative) {
        unawaited(_syncSettings());
        _persistCurrentSettings();
      }
    });

    ref.listen<String>(desktopLyricsModeProvider, (_, next) {
      if (!_isSyncingFromNative) {
        unawaited(_syncSettings());
        _persistCurrentSettings();
      }
    });

    ref.listen<double>(desktopLyricsOpacityProvider, (_, next) {
      if (!_isSyncingFromNative) {
        unawaited(_syncSettings());
        _persistCurrentSettings();
      }
    });

    ref.listen<bool>(desktopLyricsShowCardProvider, (_, next) {
      if (!_isSyncingFromNative) {
        unawaited(_syncSettings());
        _persistCurrentSettings();
      }
    });

    ref.listen<double>(desktopLyricsFontScaleProvider, (_, next) {
      if (!_isSyncingFromNative) {
        unawaited(_syncSettings());
        _persistCurrentSettings();
      }
    });

    if (!visible) return const SizedBox.shrink();
    if (track == null) {
      _lines = const [];
      _lastIndex = -1;
      unawaited(_desktopLyricsChannel.invokeMethod<void>('update', {
        'current': '播放歌曲后显示桌面歌词',
        'next': '',
      }));
      return const SizedBox.shrink();
    }

    lyrics?.whenData((value) {
      _lines = _parseDesktopLyrics(value ?? '');
      _lastIndex = -1;
      if (_lines.isEmpty) {
        unawaited(_desktopLyricsChannel.invokeMethod<void>('update', {
          'current': '暂无歌词',
          'next': '',
        }));
      } else {
        _updatePosition(repository.audioPlayer.position);
      }
    });

    return const SizedBox.shrink();
  }

  void _persistCurrentSettings() {
    final locked = ref.read(desktopLyricsLockedProvider);
    final mode = ref.read(desktopLyricsModeProvider);
    final opacity = ref.read(desktopLyricsOpacityProvider);
    final showCard = ref.read(desktopLyricsShowCardProvider);
    final fontScale = ref.read(desktopLyricsFontScaleProvider);
    unawaited(saveDesktopLyricsSettings(DesktopLyricsSettings(
      locked: locked,
      mode: mode,
      opacity: opacity,
      showCard: showCard,
      fontScale: fontScale,
    )));
  }
}

class _DesktopLyricLine {
  const _DesktopLyricLine(this.time, this.text);

  final Duration time;
  final String text;
}

List<_DesktopLyricLine> _parseDesktopLyrics(String lyrics) {
  final result = <_DesktopLyricLine>[];
  final timestamp = RegExp(r'\[(\d{1,2}):(\d{2})(?:[.:](\d{1,3}))?\]');
  for (final rawLine in lyrics.split('\n')) {
    final matches = timestamp.allMatches(rawLine).toList();
    final text = rawLine.replaceAll(timestamp, '').trim();
    if (matches.isEmpty || text.isEmpty) continue;
    for (final match in matches) {
      final fraction = (match.group(3) ?? '0').padRight(3, '0').substring(0, 3);
      result.add(_DesktopLyricLine(
        Duration(
          minutes: int.parse(match.group(1)!),
          seconds: int.parse(match.group(2)!),
          milliseconds: int.parse(fraction),
        ),
        text,
      ));
    }
  }
  result.sort((a, b) => a.time.compareTo(b.time));
  return result;
}

int _activeLyricIndex(List<_DesktopLyricLine> lines, Duration position) {
  var active = 0;
  for (var i = 0; i < lines.length; i++) {
    if (lines[i].time > position) break;
    active = i;
  }
  return active;
}
