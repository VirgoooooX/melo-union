import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../bootstrap/demo_repository.dart';
import 'lyrics_provider.dart';

final desktopLyricsVisibleProvider = StateProvider<bool>((ref) => false);
final desktopLyricsLockedProvider = StateProvider<bool>((ref) => false);

const _desktopLyricsChannel = MethodChannel('melo_union/desktop_lyrics');

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

  @override
  void initState() {
    super.initState();
    if (!Platform.isWindows) return;
    _desktopLyricsChannel.setMethodCallHandler((call) async {
      if (call.method == 'lockChanged' && mounted) {
        ref.read(desktopLyricsLockedProvider.notifier).state =
            call.arguments == true;
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
    });
    ref.listen<bool>(desktopLyricsLockedProvider, (_, next) {
      unawaited(
        _desktopLyricsChannel.invokeMethod<void>('setLocked', {'locked': next}),
      );
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
