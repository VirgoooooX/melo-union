import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/local_library/local_lyrics_enrichment_service.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

void main() {
  late _Repository repository;

  setUp(() {
    repository = _Repository(_localTrack());
  });

  test('returns indexed lyrics without querying online providers', () async {
    repository.track = _localTrack(lyrics: '  [00:00.00] Local lyrics  ');
    final provider = _Provider(
      id: 'netease_cloud_music',
      results: [_remoteTrack()],
      lyrics: '[00:00.00] Online lyrics',
    );
    final service = _service(repository, [provider]);

    expect(await service.getLyrics(repository.track.ref),
        '[00:00.00] Local lyrics');
    expect(provider.searchCalls, 0);
    expect(provider.lyricCalls, 0);
  });

  test('scrapes an exact match and caches lyrics with its remote match',
      () async {
    final provider = _Provider(
      id: 'netease_cloud_music',
      results: [_remoteTrack()],
      lyrics: '  [00:00.00] Scraped lyrics  ',
    );
    final service = _service(repository, [provider]);

    final lyrics = await service.getLyrics(repository.track.ref);

    expect(lyrics, '[00:00.00] Scraped lyrics');
    expect(repository.track.lyrics, '[00:00.00] Scraped lyrics');
    expect(repository.match?.remote, _remoteTrack().ref);
    expect(repository.match?.method, 'lyrics_metadata');
    expect(provider.searchCalls, 1);
    expect(provider.lyricCalls, 1);
  });

  test('rejects a different recording and falls back to the next provider',
      () async {
    final netease = _Provider(
      id: 'netease_cloud_music',
      results: [
        _remoteTrack(duration: const Duration(minutes: 4)),
      ],
      lyrics: '[00:00.00] Wrong lyrics',
    );
    final qq = _Provider(
      id: 'qq_music',
      results: [_remoteTrack(providerId: 'qq_music')],
      lyrics: '[00:00.00] QQ lyrics',
    );
    final service = _service(repository, [qq, netease]);

    expect(
        await service.getLyrics(repository.track.ref), '[00:00.00] QQ lyrics');
    expect(netease.searchCalls, 1);
    expect(netease.lyricCalls, 0);
    expect(qq.searchCalls, 1);
    expect(qq.lyricCalls, 1);
  });

  test('coalesces concurrent scrape requests for the same local track',
      () async {
    final provider = _Provider(
      id: 'netease_cloud_music',
      results: [_remoteTrack()],
      lyrics: '[00:00.00] Scraped lyrics',
      delay: const Duration(milliseconds: 20),
    );
    final service = _service(repository, [provider]);

    final results = await Future.wait([
      service.getLyrics(repository.track.ref),
      service.getLyrics(repository.track.ref),
    ]);

    expect(results, everyElement('[00:00.00] Scraped lyrics'));
    expect(provider.searchCalls, 1);
    expect(provider.lyricCalls, 1);
  });
}

LocalLyricsEnrichmentService _service(
  _Repository repository,
  List<_Provider> providers,
) =>
    LocalLyricsEnrichmentService(
      repository: repository,
      providerEntries: () => [
        for (final provider in providers)
          ProviderRegistryEntry(provider: provider, isEnabled: true),
      ],
      providerTimeout: const Duration(seconds: 1),
    );

LocalLibraryTrack _localTrack({String? lyrics}) => LocalLibraryTrack(
      id: 'local-track',
      rootId: 'root',
      filePath: 'song.flac',
      relativePath: 'song.flac',
      fileSize: 100,
      modifiedAt: DateTime.utc(2026),
      fingerprint: 'fingerprint',
      title: 'Song',
      artists: const ['Artist'],
      album: 'Album',
      duration: const Duration(minutes: 3),
      format: 'FLAC',
      lyrics: lyrics,
    );

SourceTrack _remoteTrack({
  String providerId = 'netease_cloud_music',
  Duration duration = const Duration(minutes: 3, seconds: 1),
}) =>
    SourceTrack(
      ref: ProviderTrackRef(
        providerId: ProviderId(providerId),
        trackId: '$providerId-track',
      ),
      title: 'Song',
      artists: const ['Artist'],
      album: 'Album',
      duration: duration,
      isFavorited: false,
    );

final class _Provider implements MusicProvider {
  _Provider({
    required this.id,
    required this.results,
    required this.lyrics,
    this.delay = Duration.zero,
  });

  final String id;
  final List<SourceTrack> results;
  final String? lyrics;
  final Duration delay;
  int searchCalls = 0;
  int lyricCalls = 0;

  @override
  ProviderDescriptor get descriptor => ProviderDescriptor(
        id: ProviderId(id),
        displayName: id,
        capabilities: const {
          ProviderCapability.search,
          ProviderCapability.lyrics,
        },
      );

  @override
  Future<List<SourceTrack>> search(String query) async {
    searchCalls++;
    await Future<void>.delayed(delay);
    return results;
  }

  @override
  Future<String?> getLyrics(ProviderTrackRef track) async {
    lyricCalls++;
    return lyrics;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Repository implements LocalLibraryRepository {
  _Repository(this.track);

  LocalLibraryTrack track;
  LocalTrackMatch? match;

  @override
  Future<LocalLibraryTrack?> getTrack(String id) async =>
      id == track.id ? track : null;

  @override
  Future<void> upsertTracks(List<LocalLibraryTrack> tracks) async {
    if (tracks.isNotEmpty) track = tracks.single;
  }

  @override
  Future<void> upsertLocalTrackMatch(LocalTrackMatch value) async {
    match = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
