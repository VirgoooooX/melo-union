import 'dart:convert';
import 'dart:io';

import 'package:music_data/music_data_io.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:test/test.dart';

void main() {
  const codec = MeloJsonCodec();
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
  final track = SourceTrack(
    ref: sourceRef,
    title: 'Midnight Signal',
    artists: const ['Luna Park'],
    album: 'Neon Hours',
    duration: const Duration(minutes: 3, seconds: 10),
    isFavorited: true,
    isDownloadable: true,
  );

  test('snapshot round trips without persisting transient tickets', () {
    final overrides = FavoritesOverrideRegistry()
      ..addMergeOverride(sourceRef, alternateRef)
      ..addSplitOverride(
          sourceRef,
          ProviderTrackRef(
            providerId: providerId,
            trackId: 'alpha_live',
          ))
      ..hideTrack(alternateRef);

    final snapshot = MeloDataSnapshot(
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
          progress: 0.4,
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
          fileSize: 1024,
          downloadedAt: DateTime.utc(2026, 6, 29, 9),
        ),
      ],
      playbackQuality: AudioQuality.lossless,
      volume: 0.7,
      downloadDirectory: r'C:\Music\MeloUnion',
      favoritesOverrides: overrides,
    );

    final encoded = codec.encodeSnapshot(snapshot);
    final encodedText = jsonEncode(encoded);

    expect(encodedText, isNot(contains('private-download')));
    expect(encodedText, isNot(contains('Bearer secret')));

    final decoded = codec.decodeSnapshot(encoded);

    expect(decoded.playlists.single.name, 'Morning Commute');
    expect(decoded.playlists.single.items.single.trackRef, sourceRef);
    expect(decoded.downloadTasks.single.ticket, isNull);
    expect(decoded.downloadTasks.single.status, DownloadStatus.paused);
    expect(decoded.playbackQuality, AudioQuality.lossless);
    expect(decoded.volume, closeTo(0.7, 0.001));
    expect(decoded.downloadDirectory, r'C:\Music\MeloUnion');
    expect(decoded.localMediaItems.single.filePath, contains('alpha_midnight'));
    expect(decoded.favoritesOverrides.shouldMerge(sourceRef, alternateRef),
        isTrue);
    expect(decoded.favoritesOverrides.hiddenTracks, contains(alternateRef));
  });

  test('JSON store reads and writes snapshots from disk', () async {
    final dir = await Directory.systemTemp.createTemp('melo_data_test_');
    addTearDown(() => dir.delete(recursive: true));
    final store = JsonMeloDataStore(file: File('${dir.path}/state.json'));

    expect(await store.read(), isNull);

    await store.write(MeloDataSnapshot(
      playlists: [LocalPlaylist(id: 'playlist_1', name: 'Saved')],
      downloadTasks: [DownloadTask(track: track, quality: AudioQuality.low)],
      playbackQuality: AudioQuality.high,
      volume: 0.3,
    ));

    final restored = await store.read();

    expect(restored, isNotNull);
    expect(restored!.playlists.single.id, 'playlist_1');
    expect(restored.downloadTasks.single.track.ref, sourceRef);
    expect(restored.playbackQuality, AudioQuality.high);
    expect(restored.volume, closeTo(0.3, 0.001));
  });
}
