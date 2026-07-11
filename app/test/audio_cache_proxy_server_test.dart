import 'dart:io';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/bootstrap/audio_cache_proxy_server.dart';

void main() {
  late Directory directory;
  late HttpServer origin;
  late List<int> audioBytes;
  late List<HttpRequest> originRequests;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('melo_proxy_test_');
    audioBytes = List<int>.generate(4096, (index) => index % 251);
    originRequests = [];
    origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin.listen((request) async {
      originRequests.add(request);
      expect(request.headers.value('x-provider-token'), 'secret');
      final range = request.headers.value(HttpHeaders.rangeHeader);
      request.response.headers.contentType = ContentType('audio', 'mpeg');
      request.response.headers.set(HttpHeaders.acceptRangesHeader, 'bytes');
      if (request.method == 'HEAD') {
        request.response.contentLength = audioBytes.length;
      } else if (range == 'bytes=100-199') {
        request.response.statusCode = HttpStatus.partialContent;
        request.response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes 100-199/${audioBytes.length}',
        );
        request.response.add(audioBytes.sublist(100, 200));
      } else {
        request.response.contentLength = audioBytes.length;
        request.response.add(audioBytes);
      }
      await request.response.close();
    });
  });

  tearDown(() async {
    await origin.close(force: true);
    await directory.delete(recursive: true);
  });

  test('proxies one full response and promotes the completed cache file',
      () async {
    final completed = Completer<File>();
    final cacheFile =
        File('${directory.path}${Platform.pathSeparator}song.mp3');
    final proxy = await AudioCacheProxyServer.start(
      remoteUri: Uri.parse(
        'http://${origin.address.address}:${origin.port}/song.mp3',
      ),
      headers: const {'x-provider-token': 'secret'},
      cacheFile: cacheFile,
      onComplete: (file) async => completed.complete(file),
    );
    addTearDown(proxy.close);

    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final response = await (await client.getUrl(proxy.playbackUri)).close();
    final received = await response.fold<List<int>>(
      <int>[],
      (all, chunk) => all..addAll(chunk),
    );

    expect(received, audioBytes);
    await completed.future;
    expect(await cacheFile.readAsBytes(), audioBytes);
    expect(originRequests, hasLength(1));
    expect(await File('${cacheFile.path}.part').exists(), isFalse);
  });

  test('supports HEAD without creating a cache file', () async {
    final cacheFile =
        File('${directory.path}${Platform.pathSeparator}song.mp3');
    final proxy = await AudioCacheProxyServer.start(
      remoteUri: Uri.parse(
        'http://${origin.address.address}:${origin.port}/song.mp3',
      ),
      headers: const {'x-provider-token': 'secret'},
      cacheFile: cacheFile,
      onComplete: (_) async => fail('HEAD must not complete a cache'),
    );
    addTearDown(proxy.close);

    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client.openUrl('HEAD', proxy.playbackUri);
    final response = await request.close();
    await response.drain<void>();

    expect(response.contentLength, audioBytes.length);
    expect(await cacheFile.exists(), isFalse);
  });

  test('forwards a non-zero range without treating it as a complete cache',
      () async {
    final cacheFile =
        File('${directory.path}${Platform.pathSeparator}song.mp3');
    var completions = 0;
    final proxy = await AudioCacheProxyServer.start(
      remoteUri: Uri.parse(
        'http://${origin.address.address}:${origin.port}/song.mp3',
      ),
      headers: const {'x-provider-token': 'secret'},
      cacheFile: cacheFile,
      onComplete: (_) async => completions++,
    );
    addTearDown(proxy.close);

    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final request = await client.getUrl(proxy.playbackUri);
    request.headers.set(HttpHeaders.rangeHeader, 'bytes=100-199');
    final response = await request.close();
    final received = await response.fold<List<int>>(
      <int>[],
      (all, chunk) => all..addAll(chunk),
    );

    expect(response.statusCode, HttpStatus.partialContent);
    expect(received, audioBytes.sublist(100, 200));
    expect(completions, 0);
    expect(await cacheFile.exists(), isFalse);
  });

  test('rejects unknown loopback paths without contacting the origin',
      () async {
    final proxy = await AudioCacheProxyServer.start(
      remoteUri: Uri.parse(
        'http://${origin.address.address}:${origin.port}/song.mp3',
      ),
      headers: const {'x-provider-token': 'secret'},
      cacheFile: File('${directory.path}${Platform.pathSeparator}song.mp3'),
      onComplete: (_) async {},
    );
    addTearDown(proxy.close);

    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final unknown = proxy.playbackUri.replace(path: '/unknown');
    final response = await (await client.getUrl(unknown)).close();
    await response.drain<void>();

    expect(response.statusCode, HttpStatus.notFound);
    expect(originRequests, isEmpty);
  });
}
