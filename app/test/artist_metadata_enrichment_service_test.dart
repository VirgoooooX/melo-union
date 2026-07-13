import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/local_library/artist_metadata_enrichment_service.dart';
import 'package:melo_union_app/src/local_library/artist_metadata_image_cache.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

void main() {
  late Directory temp;
  late _Repository repository;
  late ArtistMetadataEnrichmentService Function(List<_Provider>) serviceFor;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('artist_enrichment_test_');
    repository = _Repository();
    serviceFor = (providers) => ArtistMetadataEnrichmentService(
          repository: repository,
          providerEntries: providers.map((provider) =>
              ProviderRegistryEntry(provider: provider, isEnabled: true)),
          imageCache: ArtistMetadataImageCache(directory: temp),
          requestGap: Duration.zero,
        );
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('uses Netease first and does not query QQ after a confident match',
      () async {
    final netease = _Provider('netease_cloud_music', score: .95);
    final qq = _Provider('qq_music', score: .95);
    final service = serviceFor([netease, qq]);

    await service.enrichNow(_artist);

    expect(netease.searchCalls, 1);
    expect(qq.searchCalls, 0);
    expect(repository.metadata?.sourceProviderId?.value, 'netease_cloud_music');
  });

  test('falls back to QQ when Netease has no confident result', () async {
    final netease = _Provider('netease_cloud_music', score: .4);
    final qq = _Provider('qq_music', score: .9);
    final service = serviceFor([netease, qq]);

    await service.enrichNow(_artist);

    expect(netease.searchCalls, 1);
    expect(qq.searchCalls, 1);
    expect(repository.metadata?.sourceProviderId?.value, 'qq_music');
  });

  test('reports the updated artist key without requesting a full reload',
      () async {
    String? updatedArtistKey;
    final service = ArtistMetadataEnrichmentService(
      repository: repository,
      providerEntries: [
        ProviderRegistryEntry(
          provider: _Provider('netease_cloud_music', score: .95),
          isEnabled: true,
        ),
      ],
      imageCache: ArtistMetadataImageCache(directory: temp),
      requestGap: Duration.zero,
      onMetadataUpdated: (artistKey) => updatedArtistKey = artistKey,
    );

    await service.enrichNow(_artist);

    expect(updatedArtistKey, _artist.artistKey);
  });
}

const _artist = LocalLibraryArtist(
  artistKey: 'artist',
  displayName: 'Artist',
  trackCount: 1,
  albumCount: 1,
);

final class _Provider implements MusicProvider, ArtistMetadataProvider {
  _Provider(this.id, {required this.score});
  final String id;
  final double score;
  int searchCalls = 0;

  @override
  ProviderDescriptor get descriptor => ProviderDescriptor(
        id: ProviderId(id),
        displayName: id,
        capabilities: const {},
      );

  @override
  Future<List<ProviderArtistCandidate>> searchArtistMetadata(
      {required String artistName,
      required List<ArtistMatchTrack> samples,
      int limit = 5}) async {
    searchCalls++;
    return [
      ProviderArtistCandidate(
          artist: ProviderArtistRef(
              providerId: ProviderId(id), artistId: '$id-id', name: artistName),
          providerScore: score)
    ];
  }

  @override
  Future<ProviderArtistMetadata?> getArtistMetadata(String artistId) async =>
      ProviderArtistMetadata(
          artist: ProviderArtistRef(
              providerId: ProviderId(id), artistId: artistId, name: 'Artist'),
          description: '$id bio');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Repository implements LocalLibraryRepository {
  LocalArtistMetadata? metadata;

  @override
  Future<LocalArtistMetadata?> getArtistMetadata(String artistKey) async =>
      metadata;

  @override
  Future<void> upsertArtistMetadata(LocalArtistMetadata value) async =>
      metadata = value;

  @override
  Future<List<LocalLibraryTrack>> listArtistTracks(String artistKey) async => [
        LocalLibraryTrack(
          id: 'track',
          rootId: 'root',
          filePath: 'track.flac',
          relativePath: 'track.flac',
          fileSize: 1,
          modifiedAt: DateTime.utc(2026),
          fingerprint: 'fp',
          title: 'Song',
          artists: const ['Artist'],
          duration: const Duration(minutes: 3),
          format: 'FLAC',
        ),
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
