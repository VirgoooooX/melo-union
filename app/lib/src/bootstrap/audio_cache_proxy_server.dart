import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

typedef AudioCacheProxyComplete = Future<void> Function(File file);

/// A loopback-only proxy used on Windows so MeloUnion, rather than the native
/// media player, owns the bytes that make up an audio cache entry.
final class AudioCacheProxyServer {
  AudioCacheProxyServer._({
    required HttpServer server,
    required this.remoteUri,
    required this.headers,
    required this.cacheFile,
    required this.onComplete,
    required String token,
  })  : _server = server,
        _token = token;

  final HttpServer _server;
  final Uri remoteUri;
  final Map<String, String> headers;
  final File cacheFile;
  final AudioCacheProxyComplete onComplete;
  final String _token;
  final Set<HttpClient> _clients = {};
  StreamSubscription<HttpRequest>? _subscription;
  bool _closed = false;
  bool _writing = false;

  Uri get playbackUri => Uri(
        scheme: 'http',
        host: InternetAddress.loopbackIPv4.address,
        port: _server.port,
        pathSegments: [_token],
      );

  static Future<AudioCacheProxyServer> start({
    required Uri remoteUri,
    required Map<String, String> headers,
    required File cacheFile,
    required AudioCacheProxyComplete onComplete,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final tokenBytes = List<int>.generate(
      24,
      (_) => Random.secure().nextInt(256),
    );
    final proxy = AudioCacheProxyServer._(
      server: server,
      remoteUri: remoteUri,
      headers: Map.unmodifiable(headers),
      cacheFile: cacheFile,
      onComplete: onComplete,
      token: base64Url.encode(tokenBytes).replaceAll('=', ''),
    );
    proxy._subscription = server.listen(proxy._handleRequest);
    return proxy;
  }

  Future<void> _handleRequest(HttpRequest inbound) async {
    final segments = inbound.uri.pathSegments;
    if (_closed || segments.length != 1 || segments.first != _token) {
      inbound.response.statusCode = HttpStatus.notFound;
      await inbound.response.close();
      return;
    }
    if (inbound.method != 'GET' && inbound.method != 'HEAD') {
      inbound.response.statusCode = HttpStatus.methodNotAllowed;
      await inbound.response.close();
      return;
    }

    final client = HttpClient()..autoUncompress = false;
    _clients.add(client);
    IOSink? cacheSink;
    File? partFile;
    var bytesWritten = 0;
    var cacheCandidate = false;
    try {
      final outbound = await client.openUrl(inbound.method, remoteUri);
      _copyRequestHeaders(inbound.headers, outbound.headers);
      for (final entry in headers.entries) {
        outbound.headers.set(entry.key, entry.value);
      }
      final upstream = await outbound.close();
      final response = inbound.response;
      response.statusCode = upstream.statusCode;
      _copyResponseHeaders(upstream.headers, response.headers);

      final expectedLength = _totalLength(upstream);
      cacheCandidate = inbound.method == 'GET' &&
          !_writing &&
          (upstream.statusCode == HttpStatus.ok ||
              upstream.statusCode == HttpStatus.partialContent) &&
          expectedLength != null &&
          expectedLength > 0 &&
          _requestsCompleteBody(
            inbound.headers.value(HttpHeaders.rangeHeader),
            expectedLength,
          );
      if (cacheCandidate) {
        _writing = true;
        partFile = File('${cacheFile.path}.part');
        if (await partFile.exists()) await partFile.delete();
        await partFile.parent.create(recursive: true);
        cacheSink = partFile.openWrite();
      }

      if (inbound.method == 'HEAD') {
        await response.close();
        return;
      }

      await for (final chunk in upstream) {
        response.add(chunk);
        if (cacheSink != null) {
          cacheSink.add(chunk);
          bytesWritten += chunk.length;
        }
      }
      await cacheSink?.flush();
      await cacheSink?.close();
      cacheSink = null;
      await response.close();

      if (cacheCandidate &&
          partFile != null &&
          bytesWritten == expectedLength &&
          !_closed) {
        if (await cacheFile.exists()) await cacheFile.delete();
        final completed = await partFile.rename(cacheFile.path);
        await onComplete(completed);
        partFile = null;
      }
    } catch (_) {
      try {
        inbound.response.statusCode = HttpStatus.badGateway;
        await inbound.response.close();
      } catch (_) {
        // The native player may already have cancelled the request.
      }
    } finally {
      await cacheSink?.close();
      if (partFile != null) {
        try {
          if (await partFile.exists()) await partFile.delete();
        } on FileSystemException {
          // Best-effort cleanup; startup reconciliation removes leftovers.
        }
      }
      if (cacheCandidate) _writing = false;
      _clients.remove(client);
      client.close(force: true);
    }
  }

  void _copyRequestHeaders(HttpHeaders source, HttpHeaders target) {
    source.forEach((name, values) {
      final lower = name.toLowerCase();
      if (lower == HttpHeaders.hostHeader ||
          lower == HttpHeaders.connectionHeader ||
          lower == HttpHeaders.contentLengthHeader) {
        return;
      }
      target.set(name, values);
    });
  }

  void _copyResponseHeaders(HttpHeaders source, HttpHeaders target) {
    source.forEach((name, values) {
      final lower = name.toLowerCase();
      if (lower == HttpHeaders.connectionHeader ||
          lower == HttpHeaders.transferEncodingHeader) {
        return;
      }
      target.set(name, values);
    });
  }

  bool _requestsCompleteBody(String? range, int totalLength) {
    if (range == null || range.trim().isEmpty) return true;
    final normalized = range.trim().toLowerCase();
    if (normalized == 'bytes=0-') return true;
    final match = RegExp(r'^bytes=0-(\d+)$').firstMatch(normalized);
    return int.tryParse(match?.group(1) ?? '') == totalLength - 1;
  }

  int? _totalLength(HttpClientResponse response) {
    final contentRange =
        response.headers.value(HttpHeaders.contentRangeHeader)?.trim();
    if (contentRange != null) {
      final match = RegExp(r'^bytes\s+\d+-\d+/(\d+)$', caseSensitive: false)
          .firstMatch(contentRange);
      final total = int.tryParse(match?.group(1) ?? '');
      if (total != null && total > 0) return total;
    }
    final length = response.contentLength;
    return length > 0 ? length : null;
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription?.cancel();
    await _server.close(force: true);
    for (final client in [..._clients]) {
      client.close(force: true);
    }
    _clients.clear();
    final part = File('${cacheFile.path}.part');
    try {
      if (await part.exists()) await part.delete();
    } on FileSystemException {
      // Startup reconciliation is the final cleanup fallback.
    }
  }
}
