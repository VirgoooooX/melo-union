import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/local_library/artist_metadata_image_cache.dart';
import 'package:provider_contract/provider_contract.dart';

void main() {
  late Directory temp;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('artist_image_cache_test_');
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('rejects non-HTTPS and private targets before connecting', () async {
    // Given
    var opened = false;
    final cache = _cache(
      temp,
      responses: const [],
      onOpen: () => opened = true,
    );

    // When
    final results = <String?>[];
    for (final value in [
      'http://8.8.8.8/image.jpg',
      'https://127.0.0.1/image.jpg',
    ]) {
      results.add(await cache.cache(Uri.parse(value), _artist, 'avatar'));
    }

    // Then
    expect(results, everyElement(isNull));
    expect(opened, isFalse);
  });

  test('rejects a hostname when any resolved address is private', () async {
    // Given
    var opened = false;
    final cache = _cache(
      temp,
      responses: const [],
      addresses: [
        InternetAddress('8.8.8.8'),
        InternetAddress('10.0.0.1'),
      ],
      onOpen: () => opened = true,
    );

    // When
    final result = await cache.cache(
      Uri.parse('https://images.example.test/image.jpg'),
      _artist,
      'avatar',
    );

    // Then
    expect(result, isNull);
    expect(opened, isFalse);
  });

  test('revalidates a redirect target before opening it', () async {
    // Given
    var opens = 0;
    final cache = _cache(
      temp,
      responses: [
        _FakeResponse.redirect('https://192.168.1.2/private.jpg'),
      ],
      onOpen: () => opens++,
    );

    // When
    final result = await cache.cache(
      Uri.parse('https://images.example.test/image.jpg'),
      _artist,
      'avatar',
    );

    // Then
    expect(result, isNull);
    expect(opens, 1);
  });

  test('rejects an oversized chunked response and leaves no file', () async {
    // Given
    final cache = _cache(
      temp,
      responses: [
        _FakeResponse.image([
          List<int>.filled(6, 1),
          List<int>.filled(6, 2),
        ]),
      ],
      maxBytes: 10,
    );

    // When
    final result = await cache.cache(
      Uri.parse('https://images.example.test/image.jpg'),
      _artist,
      'avatar',
    );

    // Then
    expect(result, isNull);
    expect(
      await temp
          .list(recursive: true)
          .where((entity) => entity is File)
          .cast<File>()
          .toList(),
      isEmpty,
    );
  });

  test('rejects a non-image response', () async {
    // Given
    final cache = _cache(
      temp,
      responses: [_FakeResponse.text('not an image')],
    );

    // When
    final result = await cache.cache(
      Uri.parse('https://images.example.test/image.jpg'),
      _artist,
      'avatar',
    );

    // Then
    expect(result, isNull);
  });

  test('atomically caches a small image from a validated address', () async {
    // Given
    final bytes = [1, 2, 3, 4];
    final cache = _cache(
      temp,
      responses: [
        _FakeResponse.image([bytes], contentLength: bytes.length)
      ],
    );

    // When
    final result = await cache.cache(
      Uri.parse('https://cdn.example.test/image.png'),
      _artist,
      'avatar',
    );

    // Then
    expect(result, isNotNull);
    expect(await File(result!).readAsBytes(), bytes);
    expect(result, startsWith(temp.path));
    expect(result, endsWith('avatar.png'));
  });
}

ArtistMetadataImageCache _cache(
  Directory directory, {
  required List<_FakeResponse> responses,
  List<InternetAddress>? addresses,
  void Function()? onOpen,
  int maxBytes = 1024,
}) {
  final pending = [...responses];
  return ArtistMetadataImageCache(
    directory: directory,
    maxBytes: maxBytes,
    addressResolver: (_) async => addresses ?? [InternetAddress('8.8.8.8')],
    clientFactory: (uri, address) {
      onOpen?.call();
      return _FakeHttpClient(pending.removeAt(0));
    },
  );
}

final _artist = ProviderArtistRef(
  providerId: ProviderId('test_provider'),
  artistId: 'artist-id',
  name: 'Artist',
);

final class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.response);

  final _FakeResponse response;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeRequest(response);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeRequest implements HttpClientRequest {
  _FakeRequest(this.response);

  final HttpClientResponse response;

  @override
  bool followRedirects = true;

  @override
  Future<HttpClientResponse> close() async => response;

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeResponse extends Stream<List<int>>
    implements HttpClientResponse {
  _FakeResponse({
    required this.statusCode,
    required List<List<int>> chunks,
    required ContentType? contentType,
    required this.contentLength,
    String? location,
  })  : _chunks = chunks,
        headers = _FakeHeaders(contentType: contentType, location: location);

  factory _FakeResponse.image(
    List<List<int>> chunks, {
    int contentLength = -1,
  }) =>
      _FakeResponse(
        statusCode: HttpStatus.ok,
        chunks: chunks,
        contentType: ContentType('image', 'jpeg'),
        contentLength: contentLength,
      );

  factory _FakeResponse.text(String value) => _FakeResponse(
        statusCode: HttpStatus.ok,
        chunks: [value.codeUnits],
        contentType: ContentType.text,
        contentLength: value.length,
      );

  factory _FakeResponse.redirect(String location) => _FakeResponse(
        statusCode: HttpStatus.found,
        chunks: const [],
        contentType: null,
        contentLength: 0,
        location: location,
      );

  final List<List<int>> _chunks;

  @override
  final int statusCode;

  @override
  final int contentLength;

  @override
  final HttpHeaders headers;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int>)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      Stream<List<int>>.fromIterable(_chunks).listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _FakeHeaders implements HttpHeaders {
  _FakeHeaders({required this.contentType, required String? location})
      : _location = location;

  final String? _location;

  @override
  final ContentType? contentType;

  @override
  String? value(String name) =>
      name.toLowerCase() == HttpHeaders.locationHeader ? _location : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
