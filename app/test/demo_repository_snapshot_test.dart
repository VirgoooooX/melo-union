import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/bootstrap/demo_repository.dart';
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
        volume: 0.35,
        favoritesOverrides: overrides,
      ),
    );

    expect(repository.playlistList.single.id, 'playlist_saved');
    expect(repository.downloadCoordinator.isAvailableLocally(ref), isTrue);
    expect(repository.playbackQuality, AudioQuality.lossless);
    expect(repository.volume, closeTo(0.35, 0.001));
    expect(repository.favoritesOverrideRegistry.hiddenTracks, contains(ref));

    final exported = repository.toSnapshot();

    expect(exported.playlists.single.name, 'Saved Locally');
    expect(exported.downloadTasks.single.status, DownloadStatus.completed);
    expect(exported.localMediaItems.single.filePath, downloaded.filePath);
    expect(exported.playbackQuality, AudioQuality.lossless);
    expect(exported.volume, closeTo(0.35, 0.001));
    expect(exported.favoritesOverrides.hiddenTracks, contains(ref));
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
