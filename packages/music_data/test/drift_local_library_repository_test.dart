import 'package:drift/native.dart';
import 'package:music_data/music_data_drift.dart';
import 'package:music_domain/music_domain.dart';
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
      isFavorited: true,
      likedAt: DateTime.utc(2026, 7, 12),
    );

    await store.write(MeloDataSnapshot(
      localLibraryRoots: [root],
      localLibraryTracks: [track],
    ));
    final snapshot = await store.read();

    expect(snapshot.localLibraryRoots.single.path, r'D:\Audio');
    expect(snapshot.localLibraryTracks.single.isFavorited, isTrue);
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
}
