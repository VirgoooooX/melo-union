// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

class MeloFileCachedNetworkImageProvider
    extends ImageProvider<MeloFileCachedNetworkImageProvider> {
  const MeloFileCachedNetworkImageProvider(
    this.url, {
    this.headers,
    this.scale = 1.0,
  });

  final String url;
  final Map<String, String>? headers;
  final double scale;

  static final HttpClient _httpClient = HttpClient()
    ..autoUncompress = false
    ..connectionTimeout = const Duration(seconds: 8);
  static final Map<String, Future<Uint8List>> _pendingLoads = {};
  static Directory? _cacheDirectory;
  static int _writeCount = 0;

  @override
  Future<MeloFileCachedNetworkImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<MeloFileCachedNetworkImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadBuffer(
    MeloFileCachedNetworkImageProvider key,
    DecoderBufferCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(
        key,
        chunkEvents,
        decode: (buffer) => decode(buffer),
      ),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<MeloFileCachedNetworkImageProvider>(
          'Image key',
          key,
        ),
      ],
    );
  }

  @override
  ImageStreamCompleter loadImage(
    MeloFileCachedNetworkImageProvider key,
    ImageDecoderCallback decode,
  ) {
    final chunkEvents = StreamController<ImageChunkEvent>();
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, chunkEvents, decode: decode),
      chunkEvents: chunkEvents.stream,
      scale: key.scale,
      debugLabel: key.url,
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<ImageProvider>('Image provider', this),
        DiagnosticsProperty<MeloFileCachedNetworkImageProvider>(
          'Image key',
          key,
        ),
      ],
    );
  }

  Future<ui.Codec> _loadAsync(
    MeloFileCachedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents, {
    required Future<ui.Codec> Function(ui.ImmutableBuffer buffer) decode,
  }) async {
    try {
      final bytes = await _loadBytes(key, chunkEvents);
      if (bytes.isEmpty) {
        throw StateError(
            'Melo artwork cache returned an empty file: ${key.url}');
      }
      return decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (_) {
      scheduleMicrotask(() {
        PaintingBinding.instance.imageCache.evict(key);
      });
      rethrow;
    } finally {
      unawaited(
        chunkEvents.close().catchError((Object error, StackTrace stack) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'melo artwork cache',
              context: ErrorDescription(
                'while closing chunkEvents stream in artwork cache',
              ),
            ),
          );
        }),
      );
    }
  }

  static Future<Uint8List> _loadBytes(
    MeloFileCachedNetworkImageProvider key,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    final file = await _cacheFileFor(key.url);
    try {
      if (await file.exists()) {
        final length = await file.length();
        if (length > 0) {
          await file.setLastModified(DateTime.now());
          return file.readAsBytes();
        }
      }
    } on FileSystemException {
      // Fall through to the network path.
    }

    final pendingKey = '${key.url}|${_headersSignature(key.headers)}';
    final pending = _pendingLoads[pendingKey];
    if (pending != null) return pending;

    final future = _downloadAndCache(key, file, chunkEvents);
    _pendingLoads[pendingKey] = future;
    try {
      return await future;
    } finally {
      _pendingLoads.remove(pendingKey);
    }
  }

  static Future<Uint8List> _downloadAndCache(
    MeloFileCachedNetworkImageProvider key,
    File file,
    StreamController<ImageChunkEvent> chunkEvents,
  ) async {
    final resolved = Uri.base.resolve(key.url);
    final request = await _httpClient.getUrl(resolved);
    key.headers?.forEach(request.headers.add);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<List<int>>(<int>[]);
      throw NetworkImageLoadException(
        statusCode: response.statusCode,
        uri: resolved,
      );
    }

    final bytes = await consolidateHttpClientResponseBytes(
      response,
      onBytesReceived: (cumulative, total) {
        chunkEvents.add(
          ImageChunkEvent(
            cumulativeBytesLoaded: cumulative,
            expectedTotalBytes: total,
          ),
        );
      },
    );
    if (bytes.isEmpty) {
      throw StateError('Network image is an empty file: $resolved');
    }

    unawaited(_writeCacheFile(file, bytes));
    return bytes;
  }

  static Future<File> _cacheFileFor(String url) async {
    final dir = await _cacheDir();
    return File('${dir.path}${Platform.pathSeparator}${_cacheFileName(url)}');
  }

  static Future<Directory> _cacheDir() async {
    final existing = _cacheDirectory;
    if (existing != null) return existing;
    final dir = Directory(
      '${Directory.systemTemp.path}${Platform.pathSeparator}melo_union_artwork_cache',
    );
    await dir.create(recursive: true);
    _cacheDirectory = dir;
    return dir;
  }

  static Future<void> _writeCacheFile(File file, Uint8List bytes) async {
    try {
      await file.parent.create(recursive: true);
      final tmp = File(
        '${file.path}.tmp_${DateTime.now().microsecondsSinceEpoch}',
      );
      await tmp.writeAsBytes(bytes, flush: false);
      try {
        await tmp.rename(file.path);
      } on FileSystemException {
        await tmp.copy(file.path);
        await tmp.delete();
      }
      _writeCount++;
      if (_writeCount % 20 == 0) {
        unawaited(_pruneCache(file.parent));
      }
    } on FileSystemException {
      // Cache write failures should not break artwork rendering.
    }
  }

  static Future<void> _pruneCache(Directory dir) async {
    try {
      final entries = await dir
          .list()
          .where((entity) => entity is File && entity.path.endsWith('.img'))
          .cast<File>()
          .toList();
      if (entries.length <= 420) return;
      final stats = <({File file, DateTime modified})>[];
      for (final file in entries) {
        try {
          stats.add((file: file, modified: await file.lastModified()));
        } on FileSystemException {
          // Ignore files that disappear while pruning.
        }
      }
      stats.sort((a, b) => a.modified.compareTo(b.modified));
      for (final entry in stats.take(stats.length - 360)) {
        try {
          await entry.file.delete();
        } on FileSystemException {
          // Ignore best-effort cache cleanup failures.
        }
      }
    } on FileSystemException {
      // Best-effort cleanup only.
    }
  }

  static String _cacheFileName(String url) {
    final hash = _fnv1a(url);
    return '${hash.toRadixString(16).padLeft(8, '0')}_${url.length}.img';
  }

  static int _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  static String _headersSignature(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) return '';
    final entries = headers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => '${entry.key}:${entry.value}').join('|');
  }

  Iterable<Object> _headerPairs() {
    final entries = headers?.entries.toList() ?? const [];
    entries.sort((a, b) => a.key.compareTo(b.key));
    return entries.expand((entry) => [entry.key, entry.value]);
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is MeloFileCachedNetworkImageProvider &&
        other.url == url &&
        other.scale == scale &&
        mapEquals(other.headers, headers);
  }

  @override
  int get hashCode => Object.hash(url, scale, Object.hashAll(_headerPairs()));

  @override
  String toString() =>
      'MeloFileCachedNetworkImageProvider("$url", scale: ${scale.toStringAsFixed(1)})';
}
