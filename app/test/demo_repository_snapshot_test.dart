import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:melo_union_app/src/bootstrap/demo_repository.dart';
import 'package:melo_union_app/src/bootstrap/demo_repository_extensions.dart';
import 'package:melo_union_app/src/fakes/fake_music_provider.dart';
import 'package:music_data/music_data.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DemoRepository can hydrate and export local MVP snapshot state', () {
    final ref = ProviderTrackRef(
      providerId: ProviderId('aurora_stream'),
      trackId: 'alpha_midnight',
      extraIds: const {'album_id': 'aurora_001'},
    );
    final downloaded = LocalMediaItem(
      sourceRef: ref,
      title: 'Midnight Signal',
      artists: const ['Luna Park'],
      duration: const Duration(minutes: 3, seconds: 10),
      filePath: 'local://downloads/aurora_stream/alpha_midnight.mp3',
      fileSize: 4096,
      downloadedAt: DateTime.utc(2026, 6, 29),
    );
    final overrides = FavoritesOverrideRegistry()..hideTrack(ref);

    final repository = DemoRepository.seeded(
      snapshot: MeloDataSnapshot(
        playlists: [
          LocalPlaylist(
            id: 'playlist_saved',
            name: 'Saved Locally',
            items: [
              LocalPlaylistItem(
                trackRef: ref,
                cachedTitle: 'Midnight Signal',
                cachedArtists: const ['Luna Park'],
                cachedProviderName: 'Aurora Stream',
                addedAt: DateTime.utc(2026, 6, 29, 8),
              ),
            ],
          ),
        ],
        downloadTasks: [
          DownloadTask(
            track: SourceTrack(
              ref: ref,
              title: 'Midnight Signal',
              artists: const ['Luna Park'],
              duration: const Duration(minutes: 3, seconds: 10),
              isFavorited: true,
              isDownloadable: true,
            ),
            quality: AudioQuality.standard,
            status: DownloadStatus.completed,
            progress: 1,
            savedFilePath: downloaded.filePath,
          ),
        ],
        localMediaItems: [downloaded],
        playbackQuality: AudioQuality.lossless,
        downloadQuality: AudioQuality.high,
        volume: 0.35,
        favoritesOverrides: overrides,
      ),
    );

    expect(repository.playlistList.single.id, 'playlist_saved');
    expect(repository.downloadCoordinator.isAvailableLocally(ref), isTrue);
    expect(repository.playbackQuality, AudioQuality.lossless);
    expect(repository.downloadQuality, AudioQuality.high);
    expect(repository.volume, closeTo(0.35, 0.001));
    expect(repository.favoritesOverrideRegistry.hiddenTracks, contains(ref));

    final exported = repository.toSnapshot();

    expect(exported.playlists.single.name, 'Saved Locally');
    expect(exported.downloadTasks.single.status, DownloadStatus.completed);
    expect(exported.localMediaItems.single.filePath, downloaded.filePath);
    expect(exported.playbackQuality, AudioQuality.lossless);
    expect(exported.downloadQuality, AudioQuality.high);
    expect(exported.volume, closeTo(0.35, 0.001));
    expect(exported.favoritesOverrides.hiddenTracks, contains(ref));
  });

  test('DemoRepository hydrates last favorites data from unified cache', () {
    final providerId = ProviderId('aurora_stream');
    final ref = ProviderTrackRef(
      providerId: providerId,
      trackId: 'mid_001',
      extraIds: const {'song_id': '1001', 'song_mid': 'mid_001'},
    );
    final track = SourceTrack(
      ref: ref,
      title: '晴天',
      artists: const ['周杰伦'],
      duration: const Duration(minutes: 4, seconds: 29),
      isFavorited: true,
      likedAt: DateTime.utc(2026, 7, 7, 12),
      likedAtSource: LikedAtMetadata.sourceLocalEstimate,
      likedAtPrecision: LikedAtMetadata.precisionUnknown,
    );

    final repository = DemoRepository.seeded(
      snapshot: MeloDataSnapshot(
        unifiedFavoritesCache: CachedUnifiedFavorites(
          builtAt: DateTime.utc(2026, 7, 7, 12, 1),
          tracks: [
            UnifiedFavoriteTrack(
              unifiedId: '0_qingtian',
              title: '晴天',
              artists: const ['周杰伦'],
              duration: const Duration(minutes: 4, seconds: 29),
              variants: [track],
            ),
          ],
        ),
      ),
      additionalProviders: [
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: providerId,
            displayName: 'Aurora Stream',
            capabilities: const {
              ProviderCapability.authenticate,
              ProviderCapability.readFavorites,
            },
          ),
          profile: null,
          seedTracks: [track],
        ),
      ],
    );

    expect(repository.lastFavoritesData?.single.title, '晴天');
    expect(repository.sourceTrackByRef(ref)?.title, '晴天');
  });

  test('DemoRepository restores and exports playback queue preferences',
      () async {
    final providerId = ProviderId('aurora_stream');
    final first = SourceTrack(
      ref: ProviderTrackRef(providerId: providerId, trackId: 'song_1'),
      title: 'First Song',
      artists: const ['Melo Artist'],
      duration: const Duration(minutes: 3),
      isFavorited: false,
      isPlayable: true,
    );
    final second = SourceTrack(
      ref: ProviderTrackRef(providerId: providerId, trackId: 'song_2'),
      title: 'Second Song',
      artists: const ['Melo Artist'],
      duration: const Duration(minutes: 4),
      isFavorited: false,
      isPlayable: true,
    );
    final repository = DemoRepository.seeded(
      snapshot: MeloDataSnapshot(
        playbackPreferences: const PlaybackPreferencesSnapshot(
          rememberQueue: true,
          restorePlaybackState: true,
        ),
        playbackQueue: PlaybackQueueSnapshot(
          entries: [
            PlaybackQueueEntrySnapshot(
              entryId: 'queue-entry-1',
              track: first,
              queuedAt: DateTime.utc(2026, 7, 7, 12),
            ),
            PlaybackQueueEntrySnapshot(
              entryId: 'queue-entry-2',
              track: second,
              queuedAt: DateTime.utc(2026, 7, 7, 12, 1),
            ),
          ],
          currentIndex: 1,
          position: const Duration(seconds: 42),
          shuffleEnabled: true,
          repeatMode: PlaybackRepeatMode.one.name,
          updatedAt: DateTime.utc(2026, 7, 7, 12, 2),
        ),
      ),
      additionalProviders: [
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: providerId,
            displayName: 'Aurora Stream',
            capabilities: const {ProviderCapability.resolvePlayback},
          ),
          profile: null,
          seedTracks: [first, second],
        ),
      ],
    );

    expect(repository.rememberQueue, isTrue);
    expect(repository.restorePlaybackState, isTrue);
    expect(repository.queue.entries.map((entry) => entry.track.title),
        ['First Song', 'Second Song']);
    expect(repository.queue.current?.track.title, 'Second Song');
    expect(repository.shuffleEnabled, isTrue);
    expect(repository.repeatMode, PlaybackRepeatMode.one);

    final exported = repository.toSnapshot();

    expect(exported.playbackPreferences.rememberQueue, isTrue);
    expect(exported.playbackPreferences.restorePlaybackState, isTrue);
    expect(exported.playbackQueue?.currentIndex, 1);
    expect(exported.playbackQueue?.position, const Duration(seconds: 42));
    expect(exported.playbackQueue?.shuffleEnabled, isTrue);
    expect(exported.playbackQueue?.repeatMode, 'one');

    await repository.setRememberQueue(false);

    final disabled = repository.toSnapshot();
    expect(disabled.playbackPreferences.rememberQueue, isFalse);
    expect(disabled.playbackPreferences.restorePlaybackState, isFalse);
    expect(disabled.playbackQueue, isNull);
  });

  test('play-next policy moves entries and keeps the current song stable',
      () async {
    final providerId = ProviderId('aurora_stream');
    SourceTrack track(String id) => SourceTrack(
          ref: ProviderTrackRef(providerId: providerId, trackId: id),
          title: id,
          artists: const ['Melo Artist'],
          duration: const Duration(minutes: 3),
          isFavorited: false,
        );
    final tracks = ['a', 'b', 'c'].map(track).toList();
    final repository = DemoRepository.seeded(
      snapshot: MeloDataSnapshot(
        playbackPreferences:
            const PlaybackPreferencesSnapshot(rememberQueue: true),
        playbackQueue: PlaybackQueueSnapshot(
          entries: [
            for (var i = 0; i < tracks.length; i++)
              PlaybackQueueEntrySnapshot(
                entryId: 'entry-$i',
                track: tracks[i],
                queuedAt: DateTime.utc(2026, 7, 11, 10, i),
              ),
          ],
          currentIndex: 1,
        ),
      ),
    );

    expect(repository.playNextStatusForEntry('entry-1'),
        PlayNextButtonStatus.disabledCurrent);
    expect(repository.playNextStatusForEntry('entry-2'),
        PlayNextButtonStatus.disabledAlreadyNext);
    expect(repository.playNextStatusForTrack(tracks.first, queueSurface: false),
        PlayNextButtonStatus.enabled);

    await repository.moveQueueEntryNext('entry-0');

    expect(repository.queue.entries.map((entry) => entry.track.title),
        ['b', 'a', 'c']);
    expect(repository.queue.current?.track.title, 'b');
    expect(repository.queue.next?.track.title, 'a');
  });

  test('play-next visibility and rapid mutations follow the shared policy',
      () async {
    final providerId = ProviderId('aurora_stream');
    SourceTrack track(String id, {bool playable = true}) => SourceTrack(
          ref: ProviderTrackRef(providerId: providerId, trackId: id),
          title: id,
          artists: const ['Melo Artist'],
          duration: const Duration(minutes: 3),
          isFavorited: false,
          isPlayable: playable,
        );
    final a = track('a');
    final b = track('b');
    final c = track('c');
    final d = track('d');
    final unavailable = track('x', playable: false);
    final repository = DemoRepository.seeded(
      snapshot: MeloDataSnapshot(
        playbackPreferences:
            const PlaybackPreferencesSnapshot(rememberQueue: true),
        playbackQueue: PlaybackQueueSnapshot(
          entries: [
            for (final item in [a, b, c, d])
              PlaybackQueueEntrySnapshot(
                entryId: 'entry-${item.title}',
                track: item,
                queuedAt: DateTime.utc(2026, 7, 11),
              ),
          ],
          currentIndex: 0,
        ),
      ),
    );

    expect(repository.playNextStatusForTrack(a, queueSurface: false),
        PlayNextButtonStatus.disabledCurrent);
    expect(repository.playNextStatusForTrack(b, queueSurface: false),
        PlayNextButtonStatus.disabledAlreadyNext);
    expect(repository.playNextStatusForTrack(unavailable, queueSurface: false),
        PlayNextButtonStatus.disabledUnplayable);

    await Future.wait([
      repository.moveQueueEntryNext('entry-c'),
      repository.moveQueueEntryNext('entry-d'),
    ]);

    expect(repository.queue.current?.track.title, 'a');
    expect(repository.queue.next?.track.title, 'd');

    final oneTrack = DemoRepository.seeded(
      snapshot: MeloDataSnapshot(
        playbackPreferences:
            const PlaybackPreferencesSnapshot(rememberQueue: true),
        playbackQueue: PlaybackQueueSnapshot(
          entries: [
            PlaybackQueueEntrySnapshot(
              entryId: 'only',
              track: a,
              queuedAt: DateTime.utc(2026, 7, 11),
            ),
          ],
          currentIndex: 0,
        ),
      ),
    );
    expect(oneTrack.playNextStatusForTrack(c, queueSurface: false),
        PlayNextButtonStatus.hidden);
    expect(oneTrack.playNextStatusForEntry('only'),
        PlayNextButtonStatus.disabledCurrent);
  });

  test('a stale playback load cannot overwrite the latest track request',
      () async {
    final providerId = ProviderId('rapid_source');
    SourceTrack track(String id) => SourceTrack(
          ref: ProviderTrackRef(providerId: providerId, trackId: id),
          title: id,
          artists: const ['Rapid Artist'],
          duration: const Duration(minutes: 3),
          isFavorited: false,
        );
    final first = track('first');
    final second = track('second');
    final repository = DemoRepository.seeded(
      additionalProviders: [
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: providerId,
            displayName: 'Rapid Source',
            capabilities: const {ProviderCapability.resolvePlayback},
          ),
          profile: null,
          seedTracks: [first, second],
        ),
      ],
    );

    await Future.wait([
      repository.playTrack(first),
      repository.playTrack(second),
    ]);

    expect(repository.queue.current?.track.ref, second.ref);
    expect(repository.playbackIssue?.trackRef, isNot(first.ref));
  });

  test('Windows startup migrates downloaded media to its readable file name',
      () async {
    if (!Platform.isWindows) return;
    final directory = await Directory.systemTemp.createTemp('melo-download-');
    addTearDown(() => directory.delete(recursive: true));
    final original = File('${directory.path}\\legacy-download.flac');
    await original.writeAsBytes([0x66, 0x4c, 0x61, 0x43]);
    final ref = ProviderTrackRef(
      providerId: ProviderId('local_source'),
      trackId: 'track-1',
    );
    final repository = DemoRepository.seeded(
      snapshot: MeloDataSnapshot(
        localMediaItems: [
          LocalMediaItem(
            sourceRef: ref,
            title: '中文歌曲',
            artists: const ['歌手'],
            duration: const Duration(minutes: 3),
            filePath: original.path,
            fileSize: await original.length(),
            downloadedAt: DateTime.utc(2026, 7, 11),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final migrated = repository.downloadCoordinator.localItems.single;
    expect(
      migrated.filePath,
      '${directory.path}\\歌手 - 中文歌曲.flac',
    );
    expect(await File(migrated.filePath).exists(), isTrue);
    expect(await original.exists(), isFalse);
  });

  test(
      'DemoRepository falls back when preferred playback source cannot resolve',
      () async {
    final firstProviderId = ProviderId('first_source');
    final fallbackProviderId = ProviderId('fallback_source');
    final first = SourceTrack(
      ref: ProviderTrackRef(providerId: firstProviderId, trackId: 'same_song'),
      title: 'Same Song',
      artists: const ['Melo Artist'],
      duration: const Duration(minutes: 3),
      isFavorited: false,
      isPlayable: true,
    );
    final fallback = SourceTrack(
      ref: ProviderTrackRef(
          providerId: fallbackProviderId, trackId: 'same_song'),
      title: 'Same Song',
      artists: const ['Melo Artist'],
      duration: const Duration(minutes: 3),
      isFavorited: false,
      isPlayable: true,
    );
    final repository = DemoRepository.seeded(
      additionalProviders: [
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: firstProviderId,
            displayName: 'First Source',
            capabilities: const {},
          ),
          profile: null,
          seedTracks: [first],
        ),
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: fallbackProviderId,
            displayName: 'Fallback Source',
            capabilities: const {ProviderCapability.resolvePlayback},
          ),
          profile: null,
          seedTracks: [fallback],
        ),
      ],
    );

    await repository.playTracksFrom([first, fallback], first.ref);

    expect(repository.queue.current?.track.ref, fallback.ref);
    expect(
        repository.playbackCoordinator.currentTicket?.trackRef, fallback.ref);
  });

  test('Unified favorite row playback does not enqueue the visible list',
      () async {
    final providerId = ProviderId('aurora_stream');
    final first = SourceTrack(
      ref: ProviderTrackRef(providerId: providerId, trackId: 'song_1'),
      title: 'First Song',
      artists: const ['Melo Artist'],
      duration: const Duration(minutes: 3),
      isFavorited: true,
      isPlayable: true,
    );
    final second = SourceTrack(
      ref: ProviderTrackRef(providerId: providerId, trackId: 'song_2'),
      title: 'Second Song',
      artists: const ['Melo Artist'],
      duration: const Duration(minutes: 4),
      isFavorited: true,
      isPlayable: true,
    );
    final firstUnified = UnifiedFavoriteTrack(
      unifiedId: 'first',
      title: first.title,
      artists: first.artists,
      duration: first.duration,
      variants: [first],
    );
    final secondUnified = UnifiedFavoriteTrack(
      unifiedId: 'second',
      title: second.title,
      artists: second.artists,
      duration: second.duration,
      variants: [second],
    );
    final repository = DemoRepository.seeded(
      additionalProviders: [
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: providerId,
            displayName: 'Aurora Stream',
            capabilities: const {ProviderCapability.resolvePlayback},
          ),
          profile: null,
          seedTracks: [first, second],
        ),
      ],
    );

    await repository.playUnifiedTracksFrom(
      [firstUnified, secondUnified],
      secondUnified,
    );

    expect(repository.queue.entries, hasLength(1));
    expect(repository.queue.current?.track.ref, second.ref);
  });

  test('unified favorites prefer local playback without changing favorites',
      () {
    final remote = SourceTrack(
      ref: ProviderTrackRef(
        providerId: ProviderId('netease_cloud_music'),
        trackId: 'remote-song',
      ),
      title: 'Same Song',
      artists: const ['Same Artist'],
      duration: const Duration(minutes: 3),
      isFavorited: true,
    );
    final local = SourceTrack(
      ref: ProviderTrackRef(
        providerId: localMusicProviderId,
        trackId: 'local-song',
      ),
      title: remote.title,
      artists: remote.artists,
      duration: remote.duration,
      isFavorited: false,
    );
    final unified = UnifiedFavoriteTrack(
      unifiedId: 'same-song',
      title: remote.title,
      artists: remote.artists,
      duration: remote.duration,
      variants: [remote],
      localPlaybackVariant: local,
    );
    final repository = DemoRepository.seeded();

    expect(repository.selectUnifiedPlaybackSource(unified)?.ref, local.ref);
    expect(
      repository
          .selectUnifiedPlaybackSource(
            unified,
            providerId: 'netease_cloud_music',
          )
          ?.ref,
      remote.ref,
    );
    expect(unified.variants, [remote]);
    expect(unified.bestLikedAt, isNull);
  });

  test('DemoRepository repeat one uses native loop without reloading playback',
      () async {
    final repository = DemoRepository.seeded();

    expect(repository.repeatMode, PlaybackRepeatMode.off);
    expect(repository.audioPlayer.loopMode, LoopMode.off);

    repository.cycleRepeatMode();
    await Future<void>.delayed(Duration.zero);
    expect(repository.repeatMode, PlaybackRepeatMode.all);
    expect(repository.audioPlayer.loopMode, LoopMode.off);

    repository.cycleRepeatMode();
    await Future<void>.delayed(Duration.zero);
    expect(repository.repeatMode, PlaybackRepeatMode.one);
    expect(repository.audioPlayer.loopMode, LoopMode.one);

    repository.cycleRepeatMode();
    await Future<void>.delayed(Duration.zero);
    expect(repository.repeatMode, PlaybackRepeatMode.off);
    expect(repository.audioPlayer.loopMode, LoopMode.off);
  });

  test('DemoRepository reports playback issue and can retry current track',
      () async {
    final providerId = ProviderId('aurora_stream');
    final track = SourceTrack(
      ref: ProviderTrackRef(providerId: providerId, trackId: 'alpha_midnight'),
      title: 'Midnight Signal',
      artists: const ['Luna Park'],
      duration: const Duration(minutes: 3, seconds: 10),
      isFavorited: false,
      isPlayable: true,
    );
    final repository = DemoRepository.seeded(
      additionalProviders: [
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: providerId,
            displayName: 'Aurora Stream',
            capabilities: const {ProviderCapability.resolvePlayback},
          ),
          profile: null,
          seedTracks: [track],
        ),
      ],
    );

    await repository.playTrack(track);

    expect(repository.hasPlaybackIssue, isTrue);
    expect(repository.playbackIssue?.trackRef, track.ref);
    expect(repository.playbackIssue?.title, '播放启动失败');

    repository.dismissPlaybackIssue();
    expect(repository.hasPlaybackIssue, isFalse);

    await repository.retryCurrentPlayback();

    expect(repository.hasPlaybackIssue, isTrue);
    expect(repository.playbackIssue?.trackRef, track.ref);

    repository.dispose();
  });
}
