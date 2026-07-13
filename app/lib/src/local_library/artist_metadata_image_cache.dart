import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as path;
import 'package:provider_contract/provider_contract.dart';

typedef ArtistImageAddressResolver = Future<List<InternetAddress>> Function(
  String host,
);
typedef ArtistImageHttpClientFactory = HttpClient Function(
  Uri uri,
  InternetAddress address,
);

final class ArtistMetadataImageCache {
  ArtistMetadataImageCache({
    required this.directory,
    ArtistImageAddressResolver? addressResolver,
    ArtistImageHttpClientFactory? clientFactory,
    this.maxBytes = 8 * 1024 * 1024,
  })  : _addressResolver = addressResolver ?? InternetAddress.lookup,
        _clientFactory = clientFactory ?? _pinnedClient;

  static const _connectionTimeout = Duration(seconds: 8);
  static const _responseTimeout = Duration(seconds: 12);
  static const _totalTimeout = Duration(seconds: 25);
  static const _maxRedirects = 4;

  final Directory directory;
  final int maxBytes;
  final ArtistImageAddressResolver _addressResolver;
  final ArtistImageHttpClientFactory _clientFactory;
  bool _closed = false;

  Future<String?> cache(Uri? uri, ProviderArtistRef artist, String kind) async {
    if (uri == null || _closed || maxBytes <= 0) return null;
    final stopwatch = Stopwatch()..start();
    try {
      var current = uri;
      for (var redirectCount = 0;; redirectCount++) {
        final address = await _validatedAddress(current, stopwatch);
        final client = _clientFactory(current, address);
        HttpClientRequest? request;
        try {
          request = await client
              .getUrl(current)
              .timeout(_operationTimeout(stopwatch, _connectionTimeout));
          request.followRedirects = false;
          final response = await request
              .close()
              .timeout(_operationTimeout(stopwatch, _responseTimeout));

          if (_isRedirect(response.statusCode)) {
            if (redirectCount >= _maxRedirects) return null;
            final location = response.headers.value(HttpHeaders.locationHeader);
            if (location == null || location.trim().isEmpty) return null;
            current = current.resolve(location);
            continue;
          }

          if (response.statusCode < HttpStatus.ok ||
              response.statusCode >= HttpStatus.multipleChoices ||
              response.headers.contentType?.primaryType.toLowerCase() !=
                  'image' ||
              response.contentLength > maxBytes) {
            return null;
          }
          return await _store(
            response,
            current,
            artist,
            kind,
            stopwatch,
            request,
            client,
          );
        } finally {
          client.close(force: true);
        }
      }
    } on Object {
      return null;
    }
  }

  Future<InternetAddress> _validatedAddress(
    Uri uri,
    Stopwatch stopwatch,
  ) async {
    if (uri.scheme.toLowerCase() != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty) {
      throw const FormatException('Image URL must be an HTTPS origin URL');
    }
    final host = uri.host.toLowerCase().replaceFirst(RegExp(r'\.$'), '');
    if (host == 'localhost' || host.endsWith('.localhost')) {
      throw const FormatException('Local hosts are not valid image origins');
    }
    final literal = InternetAddress.tryParse(host);
    final addresses = literal == null
        ? await _addressResolver(host).timeout(
            _operationTimeout(stopwatch, _connectionTimeout),
          )
        : [literal];
    if (addresses.isEmpty || addresses.any((address) => !_isPublic(address))) {
      throw const SocketException('Image origin did not resolve publicly');
    }
    return addresses.first;
  }

  Future<String?> _store(
    HttpClientResponse response,
    Uri uri,
    ProviderArtistRef artist,
    String kind,
    Stopwatch stopwatch,
    HttpClientRequest request,
    HttpClient client,
  ) async {
    final targetDirectory = Directory(path.join(
      directory.path,
      _safeSegment(artist.providerId.value),
      _safeSegment(artist.artistId),
    ));
    await targetDirectory
        .create(recursive: true)
        .timeout(_remaining(stopwatch));
    final sourceExtension = path.extension(uri.path).toLowerCase();
    final extension = RegExp(r'^\.[a-z0-9]{1,4}$').hasMatch(sourceExtension)
        ? sourceExtension
        : '.jpg';
    final target = File(path.join(
      targetDirectory.path,
      '${_safeSegment(kind)}$extension',
    ));
    final temporary = File(
      '${target.path}.tmp.$pid.${Random.secure().nextInt(0x7fffffff)}',
    );
    IOSink? sink;
    try {
      sink = temporary.openWrite(mode: FileMode.writeOnly);
      var received = 0;
      final chunks = StreamIterator(response);
      try {
        while (await chunks.moveNext().timeout(
          _remaining(stopwatch),
          onTimeout: () {
            request.abort(TimeoutException('Image download timed out'));
            client.close(force: true);
            throw TimeoutException('Image download timed out');
          },
        )) {
          final chunk = chunks.current;
          received += chunk.length;
          if (received > maxBytes) {
            request.abort(const HttpException('Image exceeds size limit'));
            throw const HttpException('Image exceeds size limit');
          }
          sink.add(chunk);
        }
        await sink.flush().timeout(_remaining(stopwatch));
      } finally {
        await chunks.cancel();
      }
      await sink.close().timeout(_remaining(stopwatch));
      sink = null;
      if (received == 0 ||
          (response.contentLength >= 0 && response.contentLength != received)) {
        return null;
      }
      await temporary.rename(target.path).timeout(_remaining(stopwatch));
      return target.path;
    } finally {
      await sink?.close();
      if (await temporary.exists()) await temporary.delete();
    }
  }

  Duration _operationTimeout(Stopwatch stopwatch, Duration limit) {
    final remaining = _remaining(stopwatch);
    return remaining < limit ? remaining : limit;
  }

  Duration _remaining(Stopwatch stopwatch) {
    final remaining = _totalTimeout - stopwatch.elapsed;
    if (remaining <= Duration.zero) {
      throw TimeoutException('Image download timed out');
    }
    return remaining;
  }

  Future<void> clear() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  void close() => _closed = true;
}

HttpClient _pinnedClient(Uri expectedUri, InternetAddress address) {
  final client = HttpClient()
    ..autoUncompress = false
    ..connectionTimeout = const Duration(seconds: 8)
    ..findProxy = (_) => 'DIRECT';
  client.connectionFactory = (uri, proxyHost, proxyPort) async {
    if (proxyHost != null ||
        proxyPort != null ||
        uri.scheme != expectedUri.scheme ||
        uri.host != expectedUri.host ||
        uri.port != expectedUri.port) {
      throw const SocketException('Unexpected image connection target');
    }
    final connection = await Socket.startConnect(address, uri.port);
    final secureSocket = connection.socket.then(
      (socket) => SecureSocket.secure(socket, host: expectedUri.host),
    );
    return ConnectionTask.fromSocket(secureSocket, connection.cancel);
  };
  return client;
}

bool _isRedirect(int statusCode) =>
    statusCode == HttpStatus.movedPermanently ||
    statusCode == HttpStatus.found ||
    statusCode == HttpStatus.seeOther ||
    statusCode == HttpStatus.temporaryRedirect ||
    statusCode == HttpStatus.permanentRedirect;

bool _isPublic(InternetAddress address) {
  final bytes = address.rawAddress;
  if (bytes.length == 4) return _isPublicV4(bytes);
  if (bytes.length != 16) return false;
  final isMappedV4 = bytes.take(10).every((byte) => byte == 0) &&
      bytes[10] == 0xff &&
      bytes[11] == 0xff;
  if (isMappedV4) return _isPublicV4(bytes.sublist(12));
  final isGlobalUnicast = bytes[0] >= 0x20 && bytes[0] <= 0x3f;
  final isDocumentation = bytes[0] == 0x20 &&
      bytes[1] == 0x01 &&
      bytes[2] == 0x0d &&
      bytes[3] == 0xb8;
  return isGlobalUnicast && !isDocumentation;
}

bool _isPublicV4(List<int> bytes) {
  final a = bytes[0];
  final b = bytes[1];
  final c = bytes[2];
  return a != 0 &&
      a != 10 &&
      a != 127 &&
      !(a == 100 && b >= 64 && b <= 127) &&
      !(a == 169 && b == 254) &&
      !(a == 172 && b >= 16 && b <= 31) &&
      !(a == 192 && (b == 0 || b == 168)) &&
      !(a == 198 && (b == 18 || b == 19 || (b == 51 && c == 100))) &&
      !(a == 203 && b == 0 && c == 113) &&
      a < 224;
}

String _safeSegment(String value) {
  final safe = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  return safe.isEmpty || safe == '.' || safe == '..' ? '_' : safe;
}
