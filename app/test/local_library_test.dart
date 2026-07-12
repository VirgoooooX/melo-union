import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/local_library/local_library_scanner.dart';
import 'package:melo_union_app/src/local_library/local_music_provider.dart';
import 'package:music_data/music_data_drift.dart';
import 'package:music_domain/music_domain.dart';
import 'package:path/path.dart' as path;
import 'package:provider_contract/provider_contract.dart';

void main() {
  late Directory temp;
  late MeloDriftDatabase database;
  late DriftLocalLibraryRepository repository;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('melo_local_library_test_');
    database = MeloDriftDatabase(NativeDatabase.memory());
    repository = DriftLocalLibraryRepository(database);
  });

  tearDown(() async {
    await database.close();
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        await temp.delete(recursive: true);
        break;
      } on FileSystemException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  });

  test('scanner recognizes supported files including APE without moving them',
      () async {
    final nested = Directory(path.join(temp.path, 'nested'))..createSync();
    final ape = File(path.join(nested.path, 'Local Song.ape'))
      ..writeAsBytesSync(List<int>.generate(256, (index) => index & 0xff));
    File(path.join(nested.path, 'notes.txt')).writeAsStringSync('ignore');
    final root = LocalLibraryRoot(
      id: 'root-1',
      path: temp.path,
      displayName: 'Test',
    );
    final scanner = LocalLibraryScanner(
      repository: repository,
      artworkDirectory: Directory(path.join(temp.path, 'covers')),
    );

    await scanner.scan(root, onProgress: (_) {});

    final tracks = await repository.listTracks();
    expect(tracks, hasLength(1));
    expect(tracks.single.format, 'APE');
    expect(tracks.single.title, 'Local Song');
    expect(ape.existsSync(), isTrue);
  });

  test('local provider exposes favorites, lyrics and file playback ticket',
      () async {
    final file = File(path.join(temp.path, 'song.flac'))
      ..writeAsBytesSync([1, 2, 3]);
    final track = LocalLibraryTrack(
      id: 'track-1',
      rootId: 'root-1',
      filePath: file.path,
      relativePath: 'song.flac',
      fileSize: 3,
      modifiedAt: file.lastModifiedSync(),
      fingerprint: '3-test',
      title: 'Local Track',
      artists: const ['Local Artist'],
      duration: const Duration(seconds: 30),
      format: 'FLAC',
      lyrics: 'local lyrics',
      isAvailable: true,
    );
    await repository.upsertRoot(LocalLibraryRoot(
      id: 'root-1',
      path: temp.path,
      displayName: 'Test',
    ));
    await repository.upsertTracks([track]);
    final provider = LocalMusicProvider(repository);

    await provider.setFavorite(track: track.ref, liked: true);
    final favorites = await provider.pullFavorites();
    final ticket = await provider.createPlaybackTicket(
      track: track.ref,
      quality: AudioQuality.standard,
    );

    expect(favorites.tracks.single.title, 'Local Track');
    expect(await provider.getLyrics(track.ref), 'local lyrics');
    expect(ticket.mediaUri.isScheme('file'), isTrue);
  });

  test(
      'toSourceTrack decouples isPlayable from isAvailable so unavailable '
      'tracks remain clickable', () {
    final track = LocalLibraryTrack(
      id: 'track-uv',
      rootId: 'root-1',
      filePath: r'C:\Music\gone.flac',
      relativePath: 'gone.flac',
      fileSize: 3,
      modifiedAt: DateTime.utc(2026, 7, 12),
      fingerprint: 'uv',
      title: 'Removed Track',
      artists: const ['Local Artist'],
      duration: const Duration(seconds: 30),
      format: 'FLAC',
      isAvailable: false, // 文件已被改名/移动
    );
    // 解耦后：列表可见即视为可点播，不可用性下沉到 ticket 解析阶段复查。
    expect(track.toSourceTrack().isPlayable, isTrue);
  });

  test('createPlaybackTicket rejects a missing file with a readable message',
      () async {
    final track = LocalLibraryTrack(
      id: 'track-missing',
      rootId: 'root-1',
      filePath: path.join(temp.path, 'does-not-exist.flac'),
      relativePath: 'does-not-exist.flac',
      fileSize: 3,
      modifiedAt: DateTime.utc(2026, 7, 12),
      fingerprint: 'missing',
      title: 'Missing',
      artists: const ['Local Artist'],
      duration: const Duration(seconds: 30),
      format: 'FLAC',
      isAvailable: true, // 仍标记可用——模拟扫描后文件被改名/删除
    );
    await repository.upsertRoot(LocalLibraryRoot(
      id: 'root-1',
      path: temp.path,
      displayName: 'Test',
    ));
    await repository.upsertTracks([track]);
    final provider = LocalMusicProvider(repository);

    Object? caught;
    try {
      await provider.createPlaybackTicket(
        track: track.ref,
        quality: AudioQuality.standard,
      );
    } catch (e) {
      caught = e;
    }
    expect(caught, isA<ProviderTrackNotFoundException>(),
        reason: '文件不存在时应抛可读异常而非静默返回空 ticket');
    expect((caught as ProviderException).message, contains('本地文件不存在'));
  });
}
