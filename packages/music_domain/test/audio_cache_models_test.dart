import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:test/test.dart';

void main() {
  test('audio quality comparison is ordered from low through lossless', () {
    expect(AudioQuality.lossless.meetsOrExceeds(AudioQuality.high), isTrue);
    expect(AudioQuality.high.meetsOrExceeds(AudioQuality.high), isTrue);
    expect(AudioQuality.standard.meetsOrExceeds(AudioQuality.high), isFalse);
  });

  test('download coordinator resolves by stable identity and actual quality',
      () {
    final ref = ProviderTrackRef(
      providerId: ProviderId('alpha_music'),
      trackId: 'track_1',
      extraIds: const {'playlist': 'a'},
    );
    final coordinator = DownloadCoordinator(
      registry: StaticProviderRegistry(const []),
      seedLocalItems: [
        LocalMediaItem(
          sourceRef: ref,
          title: 'Track',
          artists: const ['Artist'],
          duration: const Duration(minutes: 3),
          filePath: '/music/track.flac',
          fileSize: 1,
          downloadedAt: DateTime.utc(2026),
          quality: AudioQuality.lossless,
        ),
      ],
    );

    final lookupRef = ProviderTrackRef(
      providerId: ref.providerId,
      trackId: ref.trackId,
      extraIds: const {'searchTitle': 'Track'},
    );
    expect(
      coordinator
          .findLocalItem(
            lookupRef,
            requestedQuality: AudioQuality.high,
            allowLowerQuality: false,
          )
          ?.quality,
      AudioQuality.lossless,
    );
  });

  test('playback coordinator prefers a qualifying local source before provider',
      () async {
    final track = SourceTrack(
      ref: ProviderTrackRef(
        providerId: ProviderId('offline_source'),
        trackId: 'track_1',
      ),
      title: 'Track',
      artists: const ['Artist'],
      duration: const Duration(minutes: 3),
      isFavorited: false,
    );
    var resolverCalls = 0;
    final coordinator = PlaybackCoordinator(
      registry: StaticProviderRegistry(const []),
      localPlaybackResolver: (track, quality,
          {required allowLowerQuality}) async {
        resolverCalls++;
        return PlaybackTicket(
          mediaUri: Uri.file('/music/track.flac'),
          headers: const {},
          expiresAt: DateTime.utc(9999),
          trackRef: track.ref,
          quality: AudioQuality.lossless,
        );
      },
    );

    coordinator.setQueue([track]);
    await coordinator.selectTrack(track.ref);

    expect(resolverCalls, 1);
    expect(coordinator.currentTicket?.mediaUri.scheme, 'file');
    expect(coordinator.currentTicket?.quality, AudioQuality.lossless);
  });

  test(
      'playback coordinator falls back to local after provider resolution fails',
      () async {
    final track = SourceTrack(
      ref: ProviderTrackRef(
        providerId: ProviderId('offline_source'),
        trackId: 'track_1',
      ),
      title: 'Track',
      artists: const ['Artist'],
      duration: const Duration(minutes: 3),
      isFavorited: false,
    );
    final coordinator = PlaybackCoordinator(
      registry: StaticProviderRegistry(const []),
      localPlaybackResolver: (track, quality,
          {required allowLowerQuality}) async {
        if (!allowLowerQuality) return null;
        return PlaybackTicket(
          mediaUri: Uri.file('/music/track.mp3'),
          headers: const {},
          expiresAt: DateTime.utc(9999),
          trackRef: track.ref,
          quality: AudioQuality.low,
        );
      },
    );

    coordinator.setQueue([track]);
    await coordinator.selectTrack(track.ref);

    expect(coordinator.currentTicket?.mediaUri.scheme, 'file');
    expect(coordinator.currentTicket?.quality, AudioQuality.low);
  });
}
