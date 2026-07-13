import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/local_library/local_audio_metadata_adapter.dart';

const _maxArtworkBytes = 8 * 1024 * 1024;

void main() {
  test('MP3 maps TPE1 to track artist and TPE2 to album artist', () {
    final raw = Mp3Metadata()
      ..leadPerformer = 'Track Artist'
      ..leadPerformers
          .addAll(['Track Artist', 'Guest Artist', 'Track Artist', ''])
      ..bandOrOrchestra = 'Album Artist'
      ..bandsOrOrchestras
          .addAll(['Album Artist', ' Album Credit ', 'Album Artist', '']);

    final tags = localAudioTagsFromRaw(raw);

    expect(tags.trackArtists, ['Track Artist', 'Guest Artist']);
    expect(tags.albumArtist, 'Album Artist / Album Credit');
  });

  test('Vorbis preserves multiple track artists separately from album artist',
      () {
    final raw = VorbisMetadata()
      ..artist.addAll(['Track Artist', 'Guest Artist'])
      ..albumArtist.addAll([
        'Album Artist',
        ' Album Credit ',
        'Album Artist',
        '',
      ])
      ..performer.add('Session Musician');

    final tags = localAudioTagsFromRaw(raw);

    expect(tags.trackArtists, ['Track Artist', 'Guest Artist']);
    expect(tags.albumArtist, 'Album Artist / Album Credit');
    expect(tags.performers, ['Session Musician']);
    expect(tags.trackArtists, isNot(contains('Session Musician')));
  });

  test('MP4 and APE normalize all track and album artist values', () {
    final mp4 = Mp4Metadata(
      artist: 'MP4 Track',
      albumArtist: 'MP4 Album',
    )
      ..artists.addAll(['MP4 Track', 'MP4 Guest', 'MP4 Track', ''])
      ..albumArtists.addAll(['MP4 Album', 'MP4 Credit', 'MP4 Album', '']);
    final ape = ApeMetadata()
      ..artist = 'APE Track'
      ..artists.addAll(['APE Track', ' APE Guest ', '', 'APE Track'])
      ..albumArtist = 'APE Album'
      ..albumArtists.addAll(['APE Album', ' APE Credit ', '', 'APE Album']);

    expect(localAudioTagsFromRaw(mp4).trackArtists, ['MP4 Track', 'MP4 Guest']);
    expect(localAudioTagsFromRaw(mp4).albumArtist, 'MP4 Album / MP4 Credit');
    expect(localAudioTagsFromRaw(ape).trackArtists, ['APE Track', 'APE Guest']);
    expect(localAudioTagsFromRaw(ape).albumArtist, 'APE Album / APE Credit');
  });

  test('RIFF uses artist only as a track artist fallback', () {
    final raw = RiffMetadata(artist: 'RIFF Artist');

    final tags = localAudioTagsFromRaw(raw);

    expect(tags.trackArtists, ['RIFF Artist']);
    expect(tags.albumArtist, isNull);
  });

  test('adapter drops an oversized fake embedded image', () {
    // Given
    final raw = Mp3Metadata()
      ..songName = 'Still index me'
      ..pictures.add(Picture(
        Uint8List(_maxArtworkBytes + 1),
        'image/jpeg',
        PictureType.coverFront,
      ));

    // When
    final tags = localAudioTagsFromRaw(raw);

    // Then
    expect(tags.title, 'Still index me');
    expect(tags.pictureBytes, isNull);
    expect(tags.pictureMime, isNull);
  });

  test('adapter keeps a normal small embedded image', () {
    // Given
    final bytes = Uint8List.fromList([1, 2, 3]);
    final raw = Mp3Metadata()
      ..pictures.add(Picture(bytes, 'image/jpeg', PictureType.coverFront));

    // When
    final tags = localAudioTagsFromRaw(raw);

    // Then
    expect(tags.pictureBytes, same(bytes));
    expect(tags.pictureMime, 'image/jpeg');
  });
}
