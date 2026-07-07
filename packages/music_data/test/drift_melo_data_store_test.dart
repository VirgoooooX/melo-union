import 'package:drift/native.dart';
import 'package:music_data/music_data_drift.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:test/test.dart';

void main() {
  late MeloDriftDatabase database;
  late DriftMeloDataStore store;

  setUp(() {
    database = MeloDriftDatabase(NativeDatabase.memory());
    store = DriftMeloDataStore(database: database);
  });

  tearDown(() async {
    await database.close();
  });

  final providerId = ProviderId('aurora_stream');
  final sourceRef = ProviderTrackRef(
    providerId: providerId,
    trackId: 'alpha_midnight',
    extraIds: const {'album_id': 'aurora_001'},
  );
  final alternateRef = ProviderTrackRef(
    providerId: ProviderId('beacon_archive'),
    trackId: 'beta_midnight',
  );

  SourceTrack sourceTrack() {
    return SourceTrack(
      ref: sourceRef,
      title: 'Midnight Signal',
      artists: const ['Luna Park'],
      album: 'Neon Hours',
      duration: const Duration(minutes: 3, seconds: 10),
      isFavorited: true,
      isDownloadable: true,
    );
  }

  test('writes and restores local MVP state through Drift tables', () async {
    final track = sourceTrack();
    final overrides = FavoritesOverrideRegistry()
      ..addMergeOverride(sourceRef, alternateRef)
      ..hideTrack(alternateRef);

    await store.write(
      MeloDataSnapshot(
        playlists: [
          LocalPlaylist(
            id: 'playlist_commute',
            name: 'Morning Commute',
            items: [
              LocalPlaylistItem(
                trackRef: sourceRef,
                cachedTitle: track.title,
                cachedArtists: track.artists,
                cachedProviderName: 'Aurora Stream',
                addedAt: DateTime.utc(2026, 6, 29, 8),
              ),
            ],
          ),
        ],
        downloadTasks: [
          DownloadTask(
            track: track,
            quality: AudioQuality.high,
            status: DownloadStatus.paused,
            progress: 0.5,
            ticket: DownloadTicket(
              mediaUri: Uri.parse('https://example.test/private-download'),
              headers: const {'Authorization': 'Bearer secret'},
              expiresAt: DateTime.utc(2026, 6, 29, 9),
              trackRef: sourceRef,
              quality: AudioQuality.high,
            ),
            createdAt: DateTime.utc(2026, 6, 29, 8, 30),
          ),
        ],
        localMediaItems: [
          LocalMediaItem(
            sourceRef: sourceRef,
            title: track.title,
            artists: track.artists,
            duration: track.duration,
            filePath: 'local://downloads/aurora_stream/alpha_midnight.mp3',
            fileSize: 4096,
            downloadedAt: DateTime.utc(2026, 6, 29, 9),
          ),
        ],
        playbackQuality: AudioQuality.lossless,
        volume: 0.42,
        favoritesOverrides: overrides,
      ),
    );

    final taskRows = await database.select(database.storedDownloadTasks).get();
    expect(taskRows.single.payloadJson, isNot(contains('private-download')));
    expect(taskRows.single.payloadJson, isNot(contains('Bearer secret')));

    final restored = await store.read();

    expect(restored.playlists.single.id, 'playlist_commute');
    expect(restored.playlists.single.items.single.trackRef, sourceRef);
    expect(restored.downloadTasks.single.status, DownloadStatus.paused);
    expect(restored.downloadTasks.single.ticket, isNull);
    expect(restored.playbackQuality, AudioQuality.lossless);
    expect(restored.volume, closeTo(0.42, 0.0001));
    expect(restored.localMediaItems.single.sourceRef, sourceRef);
    expect(restored.favoritesOverrides.shouldMerge(sourceRef, alternateRef),
        isTrue);
    expect(restored.favoritesOverrides.hiddenTracks, contains(alternateRef));
  });

  test('overwrites previous snapshot atomically and can clear all rows',
      () async {
    await store.write(
      MeloDataSnapshot(
        playlists: [LocalPlaylist(id: 'playlist_a', name: 'A')],
        downloadTasks: [
          DownloadTask(track: sourceTrack(), quality: AudioQuality.low),
        ],
      ),
    );
    await store.write(
      MeloDataSnapshot(
        playlists: [LocalPlaylist(id: 'playlist_b', name: 'B')],
        playbackQuality: AudioQuality.high,
      ),
    );

    var restored = await store.read();
    expect(restored.playlists.single.id, 'playlist_b');
    expect(restored.downloadTasks, isEmpty);
    expect(restored.playbackQuality, AudioQuality.high);
    expect(restored.volume, 1.0);

    await store.clear();

    restored = await store.read();
    expect(restored.playlists, isEmpty);
    expect(restored.downloadTasks, isEmpty);
    expect(restored.localMediaItems, isEmpty);
  });

  test('persists favorite provider cache, liked-at ledger, and unified cache',
      () async {
    final qqRef = ProviderTrackRef(
      providerId: ProviderId('qq_music'),
      trackId: 'mid_001',
      extraIds: const {'song_id': '1001', 'song_mid': 'mid_001'},
    );
    final qqTrack = SourceTrack(
      ref: qqRef,
      title: '晴天',
      artists: const ['周杰伦'],
      duration: const Duration(minutes: 4, seconds: 29),
      isFavorited: true,
      likedAtSource: LikedAtMetadata.sourceQqImport,
      likedAtPrecision: LikedAtMetadata.precisionUnknown,
    );
    final ledger = LikedAtLedger()
      ..record(
        qqRef,
        LikedAtMetadata(
          likedAt: DateTime.utc(2026, 7, 7, 12),
          source: LikedAtMetadata.sourceLocalEstimate,
          precision: LikedAtMetadata.precisionUnknown,
        ),
        updatedAt: DateTime.utc(2026, 7, 7, 12, 1),
      );

    await store.write(
      MeloDataSnapshot(
        favoriteProviderSnapshots: [
          FavoriteSnapshot(
            providerId: ProviderId('qq_music'),
            tracks: [qqTrack],
            fetchedAt: DateTime.utc(2026, 7, 7, 12, 2),
          ),
        ],
        favoriteLikedAtLedger: ledger,
        unifiedFavoritesCache: CachedUnifiedFavorites(
          builtAt: DateTime.utc(2026, 7, 7, 12, 3),
          tracks: [
            UnifiedFavoriteTrack(
              unifiedId: '0_qingtian',
              title: '晴天',
              artists: const ['周杰伦'],
              duration: const Duration(minutes: 4, seconds: 29),
              variants: [qqTrack],
            ),
          ],
        ),
        favoriteProviderStates: [
          FavoriteProviderStateSnapshot(
            providerId: ProviderId('qq_music'),
            lastSuccessAt: DateTime.utc(2026, 7, 7, 12, 2),
          ),
        ],
      ),
    );

    expect(await database.select(database.favoriteProviderTracks).get(),
        hasLength(1));
    expect(await database.select(database.favoriteLikedAtLedgerRows).get(),
        hasLength(1));
    expect(await database.select(database.unifiedFavoriteCacheRows).get(),
        hasLength(1));

    final restored = await store.read();

    expect(restored.favoriteProviderSnapshots.single.tracks.single.ref, qqRef);
    expect(restored.favoriteLikedAtLedger.likedAtFor(qqRef)?.source,
        LikedAtMetadata.sourceLocalEstimate);
    expect(restored.unifiedFavoritesCache?.tracks.single.title, '晴天');
    expect(restored.favoriteProviderStates.single.providerId.value, 'qq_music');
  });
}
