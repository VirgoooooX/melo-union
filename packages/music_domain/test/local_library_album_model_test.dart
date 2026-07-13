import 'package:music_domain/music_domain.dart';
import 'package:test/test.dart';

void main() {
  test('album identity excludes year and includes only an explicit edition',
      () {
    expect(localAlbumKey('Artist', 'Album'), 'artist|album|');
    expect(localAlbumKey('Artist', 'Album', 'Remaster-2024'),
        'artist|album|remaster-2024');
    expect(
      localAlbumKey(' Artist　／  Guest ', ' Album　Name '),
      localAlbumKey(r'artist / guest', 'Album Name'),
    );
  });

  test('album exposes canonical year while keeping the legacy year accessor',
      () {
    const album = LocalLibraryAlbum(
      albumKey: 'artist|album|',
      title: 'Album',
      albumArtist: 'Artist',
      canonicalYear: 2020,
      observedYears: [2019, 2020],
      hasYearConflict: true,
      albumArtistSource: LocalAlbumArtistSource.embeddedTag,
      trackCount: 10,
      duration: Duration(minutes: 40),
    );

    expect(album.canonicalYear, 2020);
    expect(album.year, 2020);
    expect(album.observedYears, [2019, 2020]);
    expect(album.hasYearConflict, isTrue);
    expect(album.albumArtistSource, LocalAlbumArtistSource.embeddedTag);
  });

  test('legacy year constructor input initializes canonical year', () {
    const album = LocalLibraryAlbum(
      albumKey: 'artist|album|',
      title: 'Album',
      albumArtist: 'Artist',
      year: 2006,
      trackCount: 10,
      duration: Duration(minutes: 40),
    );

    expect(album.canonicalYear, 2006);
    expect(album.year, 2006);
    expect(album.albumArtistSource, LocalAlbumArtistSource.unresolved);
  });
}
