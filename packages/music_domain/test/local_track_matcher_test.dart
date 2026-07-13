import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:test/test.dart';

void main() {
  const matcher = LocalTrackMatcher();

  test('matches a unique ISRC before metadata', () {
    final result = matcher.match(_remote(isrc: 'US-ABC-12-34567'), [
      _local('local-1', isrc: 'USABC1234567', title: 'different'),
    ]);
    expect(result?.localTrackId, 'local-1');
    expect(result?.method, 'isrc');
  });

  test('matches exact title artist set and duration within two seconds', () {
    final result = matcher.match(_remote(), [
      _local('local-1', duration: const Duration(seconds: 181)),
    ]);
    expect(result?.localTrackId, 'local-1');
  });

  test('does not merge live and studio titles or ambiguous candidates', () {
    expect(matcher.match(_remote(title: 'Song (Live)'), [_local('local-1')]),
        isNull);
    expect(matcher.match(_remote(), [_local('a'), _local('b')]), isNull);
  });
}

SourceTrack _remote({String title = 'Song', String? isrc}) => SourceTrack(
      ref: ProviderTrackRef(providerId: ProviderId('netease'), trackId: '1'),
      title: title,
      artists: const ['Artist'],
      duration: const Duration(seconds: 180),
      isFavorited: true,
      album: 'Album',
      isrc: isrc,
    );

LocalLibraryTrack _local(String id,
        {String title = 'Song',
        String? isrc,
        Duration duration = const Duration(seconds: 180)}) =>
    LocalLibraryTrack(
      id: id,
      rootId: 'root',
      filePath: '$id.flac',
      relativePath: '$id.flac',
      fileSize: 1,
      modifiedAt: DateTime.utc(2026),
      fingerprint: id,
      title: title,
      artists: const ['Artist'],
      duration: duration,
      format: 'FLAC',
      album: 'Album',
      isrc: isrc,
    );
