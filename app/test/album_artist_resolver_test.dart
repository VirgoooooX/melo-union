import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/local_library/album_artist_resolver.dart';
import 'package:music_domain/music_domain.dart';

void main() {
  test('embedded album artist majority wins for the whole candidate album', () {
    final resolved = resolveAlbumArtists([
      _track('1', artist: 'Guest', embeddedAlbumArtist: '周杰伦'),
      _track('2', artist: '周杰伦', embeddedAlbumArtist: ' 周杰伦 '),
      _track('3', artist: '费玉清'),
    ]);

    expect(resolved.map((track) => track.albumArtist), everyElement('周杰伦'));
    expect(
      resolved.map((track) => track.albumArtistSource),
      everyElement(LocalAlbumArtistSource.embeddedTag),
    );
  });

  test('dominant first track artist needs 70 percent and at least two tracks',
      () {
    final dominant = resolveAlbumArtists([
      for (var index = 0; index < 7; index++) _track('$index', artist: '周杰伦'),
      for (var index = 7; index < 10; index++) _track('$index', artist: '合作歌手'),
    ]);
    final split = resolveAlbumArtists([
      _track('a', artist: '甲'),
      _track('b', artist: '乙'),
      _track('c', artist: '乙'),
    ]);

    expect(dominant.map((track) => track.albumArtist), everyElement('周杰伦'));
    expect(
      dominant.map((track) => track.albumArtistSource),
      everyElement(LocalAlbumArtistSource.directoryConsensus),
    );
    expect(split.map((track) => track.albumArtist), everyElement('群星'));
  });

  test('single track falls back to its first artist', () {
    final resolved = resolveAlbumArtists([_track('1', artist: '独立歌手')]);

    expect(resolved.single.albumArtist, '独立歌手');
    expect(
      resolved.single.albumArtistSource,
      LocalAlbumArtistSource.trackArtistFallback,
    );
  });

  test('single override is adopted without falsifying inherited provenance',
      () {
    final override = _track('1', artist: '甲').copyWith(
      albumArtist: '我的归类',
      albumArtistSource: LocalAlbumArtistSource.userOverride,
    );
    final resolved = resolveAlbumArtists([
      override,
      _track('2', artist: '乙', embeddedAlbumArtist: '标签歌手'),
    ]);

    expect(resolved.first.albumArtist, '我的归类');
    expect(
      resolved.first.albumArtistSource,
      LocalAlbumArtistSource.userOverride,
    );
    expect(resolved.last.albumArtist, '我的归类');
    expect(
      resolved.last.albumArtistSource,
      LocalAlbumArtistSource.albumConsensus,
    );
  });

  test('conflicting overrides survive while ordinary tracks resolve locally',
      () {
    final firstOverride = _track('1', artist: '甲').copyWith(
      albumArtist: ' 我的归类 A ',
      albumArtistSource: LocalAlbumArtistSource.userOverride,
    );
    final secondOverride = _track('2', artist: '乙').copyWith(
      albumArtist: '我的归类 B',
      albumArtistSource: LocalAlbumArtistSource.userOverride,
    );

    final resolved = resolveAlbumArtists([
      firstOverride,
      secondOverride,
      _track('3', artist: '普通歌手', embeddedAlbumArtist: '标签归类'),
      _track('4', artist: '回退歌手'),
    ]);

    expect(resolved[0].albumArtist, ' 我的归类 A ');
    expect(resolved[0].albumArtistSource, LocalAlbumArtistSource.userOverride);
    expect(resolved[1].albumArtist, '我的归类 B');
    expect(resolved[1].albumArtistSource, LocalAlbumArtistSource.userOverride);
    expect(resolved[2].albumArtist, '标签归类');
    expect(resolved[2].albumArtistSource, LocalAlbumArtistSource.embeddedTag);
    expect(resolved[3].albumArtist, '回退歌手');
    expect(
      resolved[3].albumArtistSource,
      LocalAlbumArtistSource.trackArtistFallback,
    );
  });
}

LocalLibraryTrack _track(
  String id, {
  required String artist,
  String? embeddedAlbumArtist,
}) =>
    LocalLibraryTrack(
      id: id,
      rootId: 'root',
      filePath: 'C:/Music/Album/$id.flac',
      relativePath: 'Album/$id.flac',
      fileSize: 1,
      modifiedAt: DateTime.utc(2026),
      fingerprint: id,
      title: id,
      artists: [artist],
      duration: Duration.zero,
      format: 'FLAC',
      album: '专辑',
      embeddedAlbumArtist: embeddedAlbumArtist,
    );
