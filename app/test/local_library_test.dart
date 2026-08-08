import 'dart:io';
import 'dart:typed_data';

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

  test('scanner persists embedded and resolved album artist across rescans',
      () async {
    final album = Directory(path.join(temp.path, 'Album'))..createSync();
    final first = File(path.join(album.path, 'one.mp3'))
      ..writeAsBytesSync(_id3Fixture(
        title: 'One',
        trackArtist: 'Guest Artist',
        albumArtist: 'Album Artist',
        album: 'Shared Album',
      ));
    File(path.join(album.path, 'two.mp3')).writeAsBytesSync(_id3Fixture(
      title: 'Two',
      trackArtist: 'Track Artist',
      albumArtist: 'Album Artist',
      album: 'Shared Album',
    ));
    final root = LocalLibraryRoot(
      id: 'root-artists',
      path: temp.path,
      displayName: 'Test',
    );
    final scanner = LocalLibraryScanner(
      repository: repository,
      artworkDirectory: Directory(path.join(temp.path, 'covers')),
    );

    await scanner.scan(root, onProgress: (_) {});

    var tracks = await repository.listTracks();
    expect(tracks, hasLength(2));
    expect(
      tracks.map((track) => track.embeddedAlbumArtist),
      everyElement('Album Artist'),
    );
    expect(
      tracks.map((track) => track.albumArtist),
      everyElement('Album Artist'),
    );
    expect(
      tracks.map((track) => track.albumArtistSource),
      everyElement(LocalAlbumArtistSource.embeddedTag),
    );
    expect(
      tracks.firstWhere((track) => track.title == 'One').artists,
      ['Guest Artist'],
    );

    final overridden = tracks.first.copyWith(
      albumArtist: 'Custom Library Artist',
      albumArtistSource: LocalAlbumArtistSource.userOverride,
    );
    await repository.upsertTracks([overridden]);
    await first.writeAsBytes([0], mode: FileMode.append, flush: true);
    await scanner.scan(root, onProgress: (_) {});

    tracks = await repository.listTracks();
    expect(
      tracks.map((track) => track.albumArtist),
      everyElement('Custom Library Artist'),
    );
    expect(
      tracks.firstWhere((track) => track.id == overridden.id).albumArtistSource,
      LocalAlbumArtistSource.userOverride,
    );
    expect(
      tracks.firstWhere((track) => track.id != overridden.id).albumArtistSource,
      LocalAlbumArtistSource.albumConsensus,
    );
  });

  test('scanner preserves cached scraped lyrics when a changed file has none',
      () async {
    final file = File(path.join(temp.path, 'lyrics-cache.ape'))
      ..writeAsBytesSync(List<int>.generate(128, (index) => index));
    final root = LocalLibraryRoot(
      id: 'root-lyrics-cache',
      path: temp.path,
      displayName: 'Lyrics cache',
    );
    final scanner = LocalLibraryScanner(
      repository: repository,
      artworkDirectory: Directory(path.join(temp.path, 'covers')),
    );
    await scanner.scan(root, onProgress: (_) {});
    final indexed = (await repository.listTracks()).single;
    await repository.upsertTracks([
      indexed.copyWith(lyrics: '[00:00.00] Scraped lyrics'),
    ]);

    await file.writeAsBytes([255], mode: FileMode.append, flush: true);
    await file.setLastModified(DateTime.now().add(const Duration(seconds: 2)));
    await scanner.scan(root, onProgress: (_) {});

    expect((await repository.listTracks()).single.lyrics,
        '[00:00.00] Scraped lyrics');
  });

  test('scanner hydrates unchanged legacy tracks exactly once', () async {
    final tagged = File(path.join(temp.path, 'tagged.mp3'))
      ..writeAsBytesSync(_id3Fixture(
        title: 'Hydrated Title',
        trackArtist: 'Track Artist',
        albumArtist: 'Album Artist',
        album: 'Shared Album',
      ));
    final missing = File(path.join(temp.path, 'missing.ape'))
      ..writeAsBytesSync(List<int>.generate(128, (index) => index));
    final root = LocalLibraryRoot(
      id: 'root-hydration',
      path: temp.path,
      displayName: 'Hydration',
    );
    await repository.upsertRoot(root);
    await repository.upsertTracks([
      _legacyTrack('legacy-tagged', root.id, tagged),
      _legacyTrack('legacy-missing', root.id, missing),
    ]);
    final scanner = LocalLibraryScanner(
      repository: repository,
      artworkDirectory: Directory(path.join(temp.path, 'covers')),
    );

    await scanner.scan(root, onProgress: (_) {});

    var tracks = await repository.listTracks();
    final hydrated =
        tracks.firstWhere((track) => track.filePath == tagged.path);
    final withoutTag =
        tracks.firstWhere((track) => track.filePath == missing.path);
    expect(hydrated.title, 'Hydrated Title');
    expect(hydrated.embeddedAlbumArtist, 'Album Artist');
    expect(hydrated.albumArtist, 'Album Artist');
    expect(
      hydrated.albumArtistSource,
      LocalAlbumArtistSource.embeddedTag,
    );
    expect(
      withoutTag.albumArtistSource,
      LocalAlbumArtistSource.trackArtistFallback,
    );

    await repository.upsertTracks([
      withoutTag.copyWith(title: 'Skip After Hydration'),
    ]);
    await scanner.scan(root, onProgress: (_) {});

    tracks = await repository.listTracks();
    expect(
      tracks.firstWhere((track) => track.filePath == missing.path).title,
      'Skip After Hydration',
      reason: 'A resolved missing tag must not be parsed again while unchanged',
    );
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

List<int> _id3Fixture({
  required String title,
  required String trackArtist,
  required String albumArtist,
  required String album,
}) {
  final frames = <int>[
    ..._id3TextFrame('TIT2', title),
    ..._id3TextFrame('TPE1', trackArtist),
    ..._id3TextFrame('TPE2', albumArtist),
    ..._id3TextFrame('TALB', album),
  ];
  return [
    ...'ID3'.codeUnits,
    3,
    0,
    0,
    ..._syncSafe(frames.length),
    ...frames,
  ];
}

List<int> _id3TextFrame(String id, String value) {
  final payload = <int>[0, ...value.codeUnits];
  final size = ByteData(4)..setUint32(0, payload.length);
  return [
    ...id.codeUnits,
    ...size.buffer.asUint8List(),
    0,
    0,
    ...payload,
  ];
}

List<int> _syncSafe(int value) => [
      (value >> 21) & 0x7f,
      (value >> 14) & 0x7f,
      (value >> 7) & 0x7f,
      value & 0x7f,
    ];

LocalLibraryTrack _legacyTrack(String id, String rootId, File file) {
  final stat = file.statSync();
  return LocalLibraryTrack(
    id: id,
    rootId: rootId,
    filePath: file.path,
    relativePath: path.basename(file.path),
    fileSize: stat.size,
    modifiedAt: stat.modified,
    fingerprint: 'legacy-$id',
    title: 'Legacy Title',
    artists: const ['Legacy Artist'],
    duration: Duration.zero,
    format: path.extension(file.path).substring(1).toUpperCase(),
    albumArtistSource: LocalAlbumArtistSource.unresolved,
  );
}
