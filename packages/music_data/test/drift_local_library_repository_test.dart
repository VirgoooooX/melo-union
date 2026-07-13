import 'dart:io';

import 'package:drift/native.dart';
import 'package:music_data/music_data_drift.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  late MeloDriftDatabase database;
  late DriftLocalLibraryRepository repository;

  setUp(() {
    database = MeloDriftDatabase(NativeDatabase.memory());
    repository = DriftLocalLibraryRepository(database);
  });

  tearDown(() => database.close());

  test('persists roots, indexed tracks and local favorites', () async {
    final root = LocalLibraryRoot(
      id: 'root-1',
      path: r'C:\Music',
      displayName: 'Music',
    );
    final track = LocalLibraryTrack(
      id: 'track-1',
      rootId: root.id,
      filePath: r'C:\Music\Song.ape',
      relativePath: 'Song.ape',
      fileSize: 128,
      modifiedAt: DateTime.utc(2026, 7, 12),
      fingerprint: '80-abcd',
      title: 'Song',
      artists: const ['Artist'],
      duration: const Duration(minutes: 3),
      format: 'APE',
      isAvailable: true,
    );

    await repository.upsertRoot(root);
    await repository.upsertTracks([track]);
    await repository.setFavorite(track.id, true, likedAt: DateTime.utc(2026));

    final restored = (await repository.listTracks()).single;
    expect(restored.format, 'APE');
    expect(restored.isFavorited, isTrue);
    expect(restored.ref.providerId, localMusicProviderId);
  });

  test('defaults to artist, year, album, disc and track ordering', () async {
    final root = LocalLibraryRoot(
      id: 'root-order',
      path: r'C:\Music',
      displayName: 'Music',
    );
    LocalLibraryTrack track({
      required String id,
      required String artist,
      required String album,
      required int year,
      required int disc,
      required int number,
    }) =>
        LocalLibraryTrack(
          id: id,
          rootId: root.id,
          filePath: 'C:\\Music\\$id.flac',
          relativePath: '$id.flac',
          fileSize: 100,
          modifiedAt: DateTime.utc(2026, 7, 12),
          fingerprint: id,
          title: id,
          artists: [artist],
          album: album,
          year: year,
          discNumber: disc,
          trackNumber: number,
          duration: const Duration(minutes: 3),
          format: 'FLAC',
        );

    await repository.upsertRoot(root);
    await repository.upsertTracks([
      track(
          id: 'a-new-1',
          artist: 'A',
          album: 'Alpha',
          year: 2020,
          disc: 1,
          number: 1),
      track(
          id: 'b-old-1',
          artist: 'B',
          album: 'First',
          year: 1990,
          disc: 1,
          number: 1),
      track(
          id: 'a-old-2',
          artist: 'A',
          album: 'Zebra',
          year: 2000,
          disc: 1,
          number: 2),
      track(
          id: 'a-old-d2',
          artist: 'A',
          album: 'Zebra',
          year: 2000,
          disc: 2,
          number: 1),
      track(
          id: 'a-old-1',
          artist: 'A',
          album: 'Zebra',
          year: 2000,
          disc: 1,
          number: 1),
    ]);

    final restored = await repository.listTracks();
    expect(
      restored.map((track) => track.id),
      [
        'a-old-1',
        'a-old-2',
        'a-old-d2',
        'a-new-1',
        'b-old-1',
      ],
    );
  });

  test('snapshot store backs up and restores local library data', () async {
    final store = DriftMeloDataStore(database: database);
    final root = LocalLibraryRoot(
      id: 'root-1',
      path: r'D:\Audio',
      displayName: 'Audio',
    );
    final track = LocalLibraryTrack(
      id: 'track-1',
      rootId: root.id,
      filePath: r'D:\Audio\Track.flac',
      relativePath: 'Track.flac',
      fileSize: 512,
      modifiedAt: DateTime.utc(2026, 7, 12),
      fingerprint: '200-ef01',
      title: 'Track',
      artists: const ['Artist'],
      duration: const Duration(minutes: 4),
      format: 'FLAC',
      albumArtist: 'Artist',
      genres: const ['Rock'],
      isrc: 'USABC1234567',
      addedAt: DateTime.utc(2025),
      isFavorited: true,
      likedAt: DateTime.utc(2026, 7, 12),
    );

    await store.write(MeloDataSnapshot(
      localLibraryRoots: [root],
      localLibraryTracks: [track],
      localArtistMetadata: const [
        LocalArtistMetadata(
          artistKey: 'artist',
          displayName: 'Artist',
          status: ArtistMetadataStatus.matched,
          remoteArtistId: '42',
          avatarUrl: 'https://example.test/avatar.jpg',
          avatarCachePath: r'C:\cache\avatar.jpg',
        ),
      ],
      localTrackMatches: [
        LocalTrackMatch(
          remote: ProviderTrackRef(
            providerId: ProviderId('netease'),
            trackId: 'remote-1',
          ),
          localTrackId: track.id,
          method: 'isrc',
          confidence: 1,
          updatedAt: DateTime.utc(2026),
        ),
      ],
    ));
    final snapshot = await store.read();

    expect(snapshot.localLibraryRoots.single.path, r'D:\Audio');
    expect(snapshot.localLibraryTracks.single.isFavorited, isTrue);
    expect(snapshot.localLibraryTracks.single.genres, ['Rock']);
    expect(snapshot.localArtistMetadata.single.remoteArtistId, '42');
    expect(snapshot.localArtistMetadata.single.avatarCachePath, isNull,
        reason: 'machine-local image cache paths must not enter backups');
    expect(snapshot.localTrackMatches.single.localTrackId, track.id);
  });

  test(
      'markUnavailableExcept matches paths case-insensitively (Windows resilience)',
      () async {
    final root = LocalLibraryRoot(
      id: 'root-1',
      path: r'C:\Music',
      displayName: 'Music',
    );
    // 模拟磁盘中两行：一个路径大小写与重扫结果一致，一个不一致（C:\... vs c:\...）。
    final tracks = [
      LocalLibraryTrack(
        id: 'match-exact',
        rootId: root.id,
        filePath: r'C:\Music\A.mp3',
        relativePath: 'A.mp3',
        fileSize: 10,
        modifiedAt: DateTime.utc(2026, 7, 12),
        fingerprint: 'a',
        title: 'Exact',
        artists: const ['Artist'],
        duration: Duration.zero,
        format: 'MP3',
        isAvailable: true,
      ),
      LocalLibraryTrack(
        id: 'match-case-differs',
        rootId: root.id,
        filePath: r'C:\Music\Sub\B.mp3',
        relativePath: r'Sub\B.mp3',
        fileSize: 10,
        modifiedAt: DateTime.utc(2026, 7, 12),
        fingerprint: 'b',
        title: 'CaseDiffers',
        artists: const ['Artist'],
        duration: Duration.zero,
        format: 'MP3',
        isAvailable: true,
      ),
    ];
    await repository.upsertRoot(root);
    await repository.upsertTracks(tracks);

    // 重扫时 availablePaths 用小写盘符表示（c:\ 而库中存的是 C:\）。
    await repository.markUnavailableExcept(root.id, {
      r'C:\Music\A.mp3'.toLowerCase(),
      r'C:\Music\Sub\B.mp3'.toLowerCase(),
    });

    final restored = await repository.listTracks();
    expect(restored.length, 2);
    expect(
      restored.where((t) => t.id == 'match-exact').single.isAvailable,
      isTrue,
      reason: '大小写一致的路径仍应可用',
    );
    expect(
      restored.where((t) => t.id == 'match-case-differs').single.isAvailable,
      isTrue,
      reason: '仅盘符/大小写不同的路径不应被误判为不可用',
    );
  });

  test('removeRoot deletes root, tracks and orphans their favorites', () async {
    final root = LocalLibraryRoot(
      id: 'root-del',
      path: r'C:\Music',
      displayName: 'Music',
    );
    final track = LocalLibraryTrack(
      id: 'track-del',
      rootId: root.id,
      filePath: r'C:\Music\Song.flac',
      relativePath: 'Song.flac',
      fileSize: 128,
      modifiedAt: DateTime.utc(2026, 7, 12),
      fingerprint: '80-abcd',
      title: 'Song',
      artists: const ['Artist'],
      duration: const Duration(minutes: 3),
      format: 'FLAC',
      isAvailable: true,
    );
    await repository.upsertRoot(root);
    await repository.upsertTracks([track]);
    await repository.setFavorite(track.id, true, likedAt: DateTime.utc(2026));

    // 此前手写 SQL 误用表名 local_library_*（实际是 stored_local_library_*）
    // 会让 removeRoot 整个事务抛 "no such table"，目录于是删不掉。
    await repository.removeRoot(root.id);

    expect(await repository.listRoots(), isEmpty);
    expect(await repository.listTracks(), isEmpty);
  });

  test('persists extended metadata and aggregates artists and albums',
      () async {
    final addedAt = DateTime.utc(2025, 1, 2);
    await repository.upsertTracks([
      LocalLibraryTrack(
        id: 'extended',
        rootId: 'root',
        filePath: r'C:\Music\Extended.flac',
        relativePath: 'Extended.flac',
        fileSize: 10,
        modifiedAt: DateTime.utc(2026),
        fingerprint: 'extended',
        title: 'Extended',
        artists: const ['Artist', 'Guest'],
        embeddedAlbumArtist: 'Tagged Artist',
        albumArtist: 'Artist',
        albumArtistSource: LocalAlbumArtistSource.albumConsensus,
        albumEditionKey: 'deluxe',
        album: 'Album',
        genres: const ['Rock', 'Pop'],
        isrc: 'USABC1234567',
        addedAt: addedAt,
        bitRate: 1000,
        sampleRate: 48000,
        bitDepth: 24,
        duration: const Duration(minutes: 4),
        format: 'FLAC',
      ),
    ]);

    final restored = (await repository.listTracks()).single;
    expect(restored.genres, ['Rock', 'Pop']);
    expect(restored.trackArtists, ['Artist', 'Guest']);
    expect(restored.embeddedAlbumArtist, 'Tagged Artist');
    expect(restored.albumArtist, 'Artist');
    expect(restored.albumArtistSource, LocalAlbumArtistSource.albumConsensus);
    expect(restored.albumEditionKey, 'deluxe');
    expect(restored.addedAt.toUtc(), addedAt);
    expect(restored.bitDepth, 24);
    expect((await repository.getStats()).artistCount, 1);
    expect(
        (await repository.listArtists()).map((a) => a.displayName), ['Artist']);
    expect((await repository.listAlbums()).single.title, 'Album');
  });

  test('merges album years and derives canonical year from the mode', () async {
    LocalLibraryTrack track({
      required String id,
      required String album,
      required int? year,
      String albumArtist = 'Artist',
      LocalAlbumArtistSource source = LocalAlbumArtistSource.albumConsensus,
    }) =>
        LocalLibraryTrack(
          id: id,
          rootId: 'root',
          filePath: 'C:\\Music\\$id.flac',
          relativePath: '$id.flac',
          fileSize: 10,
          modifiedAt: DateTime.utc(2026),
          fingerprint: id,
          title: id,
          artists: const ['Artist'],
          albumArtist: albumArtist,
          albumArtistSource: source,
          album: album,
          year: year,
          duration: const Duration(minutes: 3),
          format: 'FLAC',
        );

    await repository.upsertTracks([
      for (var index = 0; index < 4; index++)
        track(id: 'vertical-2021-$index', album: '纵横四海', year: 2021),
      for (var index = 0; index < 6; index++)
        track(id: 'vertical-2022-$index', album: '纵横四海', year: 2022),
      track(id: 'sparrow-2019', album: '麻雀', year: 2019),
      for (var index = 0; index < 9; index++)
        track(id: 'sparrow-2020-$index', album: '麻雀', year: 2020),
      track(id: 'fantasy-unknown', album: '依然范特西', year: null),
      for (var index = 0; index < 9; index++)
        track(id: 'fantasy-2006-$index', album: '依然范特西', year: 2006),
      track(id: 'tie-2022', album: 'Tie', year: 2022),
      track(id: 'tie-2021', album: 'Tie', year: 2021),
    ]);

    final albums = {
      for (final album in await repository.listAlbums(limit: 100))
        album.title: album,
    };
    expect(albums, hasLength(4));
    expect(albums['纵横四海']?.canonicalYear, 2022);
    expect(albums['纵横四海']?.observedYears, [2021, 2022]);
    expect(albums['纵横四海']?.hasYearConflict, isTrue);
    expect(albums['麻雀']?.canonicalYear, 2020);
    expect(albums['麻雀']?.observedYears, [2019, 2020]);
    expect(albums['依然范特西']?.canonicalYear, 2006);
    expect(albums['依然范特西']?.observedYears, [2006]);
    expect(albums['依然范特西']?.hasYearConflict, isTrue,
        reason: 'a missing year among otherwise dated tracks is a conflict');
    expect(albums['Tie']?.canonicalYear, 2021,
        reason: 'equal year counts choose the earlier year');
    expect(albums['纵横四海']?.albumArtistSource,
        LocalAlbumArtistSource.albumConsensus);

    final tracks = await repository.listAlbumTracks(
      albums['纵横四海']!.albumKey,
    );
    expect(tracks, hasLength(10));
    expect(
        await repository.getStats(),
        isA<LocalLibraryStats>()
            .having((value) => value.albumCount, 'albums', 4));
  });

  test('browses by album artist while preserving and searching track artists',
      () async {
    final collaboration = LocalLibraryTrack(
      id: 'collaboration',
      rootId: 'root',
      filePath: r'C:\Music\Collaboration.flac',
      relativePath: 'Collaboration.flac',
      fileSize: 10,
      modifiedAt: DateTime.utc(2026),
      fingerprint: 'collaboration',
      title: '千里之外',
      artists: const ['周杰伦', '费玉清'],
      albumArtist: '周杰伦',
      albumArtistSource: LocalAlbumArtistSource.embeddedTag,
      album: '依然范特西',
      year: 2006,
      duration: const Duration(minutes: 4),
      format: 'FLAC',
    );
    await repository.upsertTracks([collaboration]);

    final artists = await repository.listArtists();
    expect(artists.map((artist) => artist.displayName), ['周杰伦']);
    expect(artists.single.trackCount, 1);
    expect(artists.single.albumCount, 1);
    expect(
        (await repository.listArtistTracks(artists.single.artistKey))
            .single
            .trackArtists,
        ['周杰伦', '费玉清']);
    expect(await repository.listArtistAlbums(artists.single.artistKey),
        hasLength(1));
    expect(
        (await repository.listArtists(query: '费玉清')).single.displayName, '周杰伦');
    expect((await repository.listAlbums(query: '费玉清')).single.title, '依然范特西');
    expect((await repository.listTracks(query: '周杰伦')), hasLength(1));
  });

  test('edition key and explicit edition titles remain separate albums',
      () async {
    LocalLibraryTrack track(String id, String title, String? edition) =>
        LocalLibraryTrack(
          id: id,
          rootId: 'root',
          filePath: 'C:\\Music\\$id.flac',
          relativePath: '$id.flac',
          fileSize: 10,
          modifiedAt: DateTime.utc(2026),
          fingerprint: id,
          title: id,
          artists: const ['Artist'],
          albumArtist: 'Artist',
          albumArtistSource: LocalAlbumArtistSource.userOverride,
          album: title,
          albumEditionKey: edition,
          year: 2020,
          duration: const Duration(minutes: 3),
          format: 'FLAC',
        );

    await repository.upsertTracks([
      track('standard', 'Album', null),
      track('edition', 'Album', 'remaster-2024'),
      track('deluxe-title', 'Album Deluxe', null),
    ]);

    final albums = await repository.listAlbums();
    expect(albums, hasLength(3));
    expect(albums.map((album) => album.albumKey).toSet(), hasLength(3));
  });

  test('normalizes album whitespace and common separator variants', () async {
    LocalLibraryTrack track({
      required String id,
      required String albumArtist,
      required String album,
    }) =>
        LocalLibraryTrack(
          id: id,
          rootId: 'root',
          filePath: 'C:\\Music\\$id.flac',
          relativePath: '$id.flac',
          fileSize: 10,
          modifiedAt: DateTime.utc(2026),
          fingerprint: id,
          title: id,
          artists: [albumArtist],
          albumArtist: albumArtist,
          albumArtistSource: LocalAlbumArtistSource.embeddedTag,
          album: album,
          duration: const Duration(minutes: 3),
          format: 'FLAC',
        );

    await repository.upsertTracks([
      track(id: 'space-1', albumArtist: 'The Artist', album: 'Album Name'),
      track(id: 'space-2', albumArtist: 'The  Artist', album: 'Album  Name'),
      track(id: 'space-3', albumArtist: 'The　Artist', album: 'Album　Name'),
      track(id: 'space-4', albumArtist: 'The Artist', album: 'Album/Name'),
      track(id: 'space-5', albumArtist: 'The Artist', album: 'Album／Name'),
      track(
        id: 'slash-1',
        albumArtist: 'Artist/Guest',
        album: 'Slash Album',
      ),
      track(
        id: 'slash-2',
        albumArtist: r'Artist\Guest',
        album: 'Slash Album',
      ),
      track(
        id: 'slash-3',
        albumArtist: 'Artist／Guest',
        album: 'Slash Album',
      ),
    ]);

    final albums = await repository.listAlbums();
    expect(albums, hasLength(2));
    expect(albums.map((album) => album.trackCount), containsAll([5, 3]));
    expect((await repository.listArtists()).map((artist) => artist.artistKey),
        containsAll(['the artist', 'artist/guest']));
    expect(await repository.listArtistTracks('the　artist'), hasLength(5));
    expect(await repository.listArtistTracks(r'artist\guest'), hasLength(3));
  });

  test('normalizes arbitrarily long album artist whitespace runs', () async {
    // Given: two tracks whose public artist identities are equivalent.
    final longWhitespace = List.filled(65, ' ').join();
    LocalLibraryTrack track(String id, String albumArtist) => LocalLibraryTrack(
          id: id,
          rootId: 'root',
          filePath: 'C:\\Music\\$id.flac',
          relativePath: '$id.flac',
          fileSize: 10,
          modifiedAt: DateTime.utc(2026),
          fingerprint: id,
          title: id,
          artists: [albumArtist],
          albumArtist: albumArtist,
          albumArtistSource: LocalAlbumArtistSource.embeddedTag,
          album: 'Album',
          duration: const Duration(minutes: 3),
          format: 'FLAC',
        );
    await repository.upsertTracks([
      track('single-space', 'The Artist'),
      track('long-space', 'The${longWhitespace}Artist'),
      track('edge-whitespace', '\tThe${longWhitespace}Artist\f'),
    ]);

    // When: SQL groups the rows using its production artist identity.
    final artists = await repository.listArtists();
    final albums = await repository.listAlbums();

    // Then: SQL identity matches localArtistKey for an unbounded whitespace run.
    expect(localArtistKey('The${longWhitespace}Artist'), 'the artist');
    expect(localArtistKey('\tThe${longWhitespace}Artist\f'), 'the artist');
    expect(artists, hasLength(1));
    expect(artists.single.trackCount, 3);
    expect(albums, hasLength(1));
    expect(albums.single.trackCount, 3);
  });

  test('album offset pages have a unique stable tiebreaker for every sort',
      () async {
    // Given: 205 albums tied on every displayed sort field.
    await repository.upsertTracks([
      for (var index = 204; index >= 0; index--)
        LocalLibraryTrack(
          id: 'track-$index',
          rootId: 'root',
          filePath: 'C:\\Music\\track-$index.flac',
          relativePath: 'track-$index.flac',
          fileSize: 10,
          modifiedAt: DateTime.utc(2026),
          fingerprint: 'track-$index',
          title: 'Track',
          artists: const ['Artist'],
          albumArtist: 'Artist',
          albumArtistSource: LocalAlbumArtistSource.embeddedTag,
          album: 'Album',
          albumEditionKey: index.toString().padLeft(3, '0'),
          year: 2026,
          addedAt: DateTime.utc(2026),
          duration: const Duration(minutes: 3),
          format: 'FLAC',
        ),
    ]);

    for (final sort in LocalAlbumSortOrder.values) {
      // When: the tied result set is read through three real OFFSET pages.
      final pages = <LocalLibraryAlbum>[
        ...await repository.listAlbums(sort: sort, limit: 100),
        ...await repository.listAlbums(sort: sort, limit: 100, offset: 100),
        ...await repository.listAlbums(sort: sort, limit: 100, offset: 200),
      ];

      // Then: every key occurs exactly once in deterministic key order.
      expect(pages, hasLength(205), reason: sort.name);
      expect(pages.map((album) => album.albumKey).toSet(), hasLength(205),
          reason: sort.name);
      expect(
        pages.map((album) => album.albumKey),
        orderedEquals(
          [...pages.map((album) => album.albumKey)]..sort(),
        ),
        reason: sort.name,
      );
    }
  });

  test('persists artist metadata and remote-local matches', () async {
    const metadata = LocalArtistMetadata(
      artistKey: 'artist',
      displayName: 'Artist',
      status: ArtistMetadataStatus.matched,
      remoteArtistId: '42',
    );
    final remote =
        ProviderTrackRef(providerId: ProviderId('netease'), trackId: '7');
    final match = LocalTrackMatch(
        remote: remote,
        localTrackId: 'local',
        method: 'isrc',
        confidence: 1,
        updatedAt: DateTime.utc(2026));
    await repository.upsertArtistMetadata(metadata);
    await repository.upsertLocalTrackMatch(match);
    expect(
        (await repository.getArtistMetadata('artist'))?.remoteArtistId, '42');
    expect((await repository.findLocalMatch(remote))?.localTrackId, 'local');
    await repository.removeLocalTrackMatch(remote);
    expect(await repository.findLocalMatch(remote), isNull);
  });

  test('repairs the incompatible legacy remote match cache', () async {
    await database.close();
    final directory =
        await Directory.systemTemp.createTemp('melo_match_repair_');
    addTearDown(() async {
      await database.close();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final file = File('${directory.path}/library.sqlite');

    database = MeloDriftDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').getSingle();
    await database.customStatement('DROP TABLE stored_local_track_matches');
    await database.customStatement('''
      CREATE TABLE stored_local_track_matches (
        local_track_id TEXT NOT NULL,
        remote_identity TEXT NOT NULL,
        payload_json TEXT NOT NULL,
        PRIMARY KEY (local_track_id, remote_identity)
      )
    ''');
    await database.customStatement('PRAGMA user_version = 4');
    await database.close();

    database = MeloDriftDatabase(NativeDatabase(file));
    repository = DriftLocalLibraryRepository(database);
    final remote =
        ProviderTrackRef(providerId: ProviderId('netease'), trackId: '7');
    await repository.upsertLocalTrackMatch(LocalTrackMatch(
      remote: remote,
      localTrackId: 'local',
      method: 'metadata',
      confidence: 0.9,
      updatedAt: DateTime.utc(2026),
    ));

    expect((await repository.findLocalMatch(remote))?.localTrackId, 'local');
  });

  test('repairs a partial on-disk v5 album ownership schema idempotently',
      () async {
    await database.close();
    final directory =
        await Directory.systemTemp.createTemp('melo_album_owner_migration_');
    addTearDown(() async {
      await database.close();
      if (await directory.exists()) await directory.delete(recursive: true);
    });
    final file = File('${directory.path}/library.sqlite');
    final legacy = sqlite.sqlite3.open(file.path);
    legacy
      ..execute('''
        CREATE TABLE stored_local_library_tracks (
          id TEXT NOT NULL PRIMARY KEY,
          root_id TEXT NOT NULL,
          file_path TEXT NOT NULL UNIQUE,
          relative_path TEXT NOT NULL,
          file_size INTEGER NOT NULL,
          modified_at INTEGER NOT NULL,
          fingerprint TEXT NOT NULL,
          title TEXT NOT NULL,
          artists_json TEXT NOT NULL,
          duration_ms INTEGER NOT NULL,
          format TEXT NOT NULL,
          album TEXT,
          embedded_album_artist TEXT,
          album_artist TEXT,
          album_artist_source TEXT DEFAULT 'unresolved',
          year INTEGER,
          is_available INTEGER NOT NULL DEFAULT 1
        )
      ''')
      ..execute('''
        INSERT INTO stored_local_library_tracks (
          id, root_id, file_path, relative_path, file_size, modified_at,
          fingerprint, title, artists_json, duration_ms, format, album,
          album_artist, year, is_available
        ) VALUES (
          'legacy-track', 'root', 'C:\\Music\\Legacy.flac', 'Legacy.flac',
          128, 0, 'legacy', 'Legacy', '["Artist"]', 180000, 'FLAC',
          'Legacy Album', 'Tagged Artist', 2020, 1
        )
      ''')
      ..execute('''
        INSERT INTO stored_local_library_tracks (
          id, root_id, file_path, relative_path, file_size, modified_at,
          fingerprint, title, artists_json, duration_ms, format, album,
          album_artist, album_artist_source, year, is_available
        ) VALUES (
          'null-source', 'root', 'C:\\Music\\NullSource.flac',
          'NullSource.flac', 128, 0, 'null-source', 'Null Source',
          '["Artist"]', 180000, 'FLAC', 'Legacy Album', 'Second Artist',
          NULL, 2020, 1
        )
      ''')
      ..execute('''
        INSERT INTO stored_local_library_tracks (
          id, root_id, file_path, relative_path, file_size, modified_at,
          fingerprint, title, artists_json, duration_ms, format, album,
          embedded_album_artist, album_artist, album_artist_source, year,
          is_available
        ) VALUES (
          'user-override', 'root', 'C:\\Music\\UserOverride.flac',
          'UserOverride.flac', 128, 0, 'user-override', 'User Override',
          '["Artist"]', 180000, 'FLAC', 'Legacy Album', NULL,
          'Override Artist', 'userOverride', 2020, 1
        )
      ''')
      ..execute('PRAGMA user_version = 5')
      ..close();

    database = MeloDriftDatabase(NativeDatabase(file));
    repository = DriftLocalLibraryRepository(database);
    final restored = {
      for (final track in await repository.listTracks()) track.id: track,
    };

    expect(restored['legacy-track']!.albumArtist, 'Tagged Artist');
    expect(restored['legacy-track']!.embeddedAlbumArtist, 'Tagged Artist');
    expect(restored['legacy-track']!.albumArtistSource,
        LocalAlbumArtistSource.embeddedTag);
    expect(restored['legacy-track']!.albumEditionKey, isNull);
    expect(restored['null-source']!.embeddedAlbumArtist, 'Second Artist');
    expect(restored['null-source']!.albumArtistSource,
        LocalAlbumArtistSource.embeddedTag);
    expect(restored['user-override']!.albumArtist, 'Override Artist');
    expect(restored['user-override']!.embeddedAlbumArtist, isNull);
    expect(restored['user-override']!.albumArtistSource,
        LocalAlbumArtistSource.userOverride);
    final normalizedAlbums = await database
        .customSelect(
          'SELECT DISTINCT normalized_album FROM stored_local_library_tracks',
        )
        .get();
    expect(
      normalizedAlbums.map((row) => row.read<String>('normalized_album')),
      [normalizeLocalMetadata('Legacy Album')],
      reason: 'legacy rows must use the same album identity as new scans',
    );
    final normalizedLegacy = await database
        .customSelect(
          'SELECT normalized_title, normalized_artists '
          "FROM stored_local_library_tracks WHERE id = 'legacy-track'",
        )
        .getSingle();
    expect(normalizedLegacy.read<String>('normalized_title'),
        normalizeLocalMetadata('Legacy'));
    expect(normalizedLegacy.read<String>('normalized_artists'),
        normalizeLocalMetadata('Artist'));

    final columns = await database
        .customSelect('PRAGMA table_info(stored_local_library_tracks)')
        .get();
    expect(
      columns.map((row) => row.read<String>('name')),
      containsAll([
        'embedded_album_artist',
        'album_artist_source',
        'album_edition_key',
      ]),
    );
    expect(
      (await database.customSelect('PRAGMA user_version').getSingle())
          .read<int>('user_version'),
      MeloDriftDatabase.currentSchemaVersion,
    );

    await database.close();
    database = MeloDriftDatabase(NativeDatabase(file));
    repository = DriftLocalLibraryRepository(database);
    final reopened = {
      for (final track in await repository.listTracks()) track.id: track,
    };
    expect(reopened['legacy-track']!.embeddedAlbumArtist, 'Tagged Artist');
    expect(reopened['legacy-track']!.albumArtistSource,
        LocalAlbumArtistSource.embeddedTag);
    expect(reopened['null-source']!.embeddedAlbumArtist, 'Second Artist');
    expect(reopened['null-source']!.albumArtistSource,
        LocalAlbumArtistSource.embeddedTag);
    expect(reopened['user-override']!.albumArtist, 'Override Artist');
    expect(reopened['user-override']!.embeddedAlbumArtist, isNull);
    expect(reopened['user-override']!.albumArtistSource,
        LocalAlbumArtistSource.userOverride);
  });
}
