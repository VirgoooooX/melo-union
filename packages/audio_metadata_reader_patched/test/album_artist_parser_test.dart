import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:test/test.dart';

void main() {
  test('Vorbis fixture keeps repeated ALBUMARTIST values in order', () {
    final temp = Directory.systemTemp.createTempSync('melo_ogg_artist_test_');
    final file = File('${temp.path}/artists.ogg');
    addTearDown(() => temp.deleteSync(recursive: true));
    file.writeAsBytesSync(_oggFixture([
      'ARTIST=Track Artist',
      'ALBUMARTIST=Album Artist',
      'ALBUM ARTIST=Album Credit',
    ]));

    final metadata = readAllMetadata(file, getImage: false) as VorbisMetadata;

    expect(metadata.artist, ['Track Artist']);
    expect(metadata.albumArtist, ['Album Artist', 'Album Credit']);
  });

  test('MP4 keeps repeated artist atoms in order', () {
    final temp = Directory.systemTemp.createTempSync('melo_mp4_artist_test_');
    final file = File('${temp.path}/artists.m4a');
    addTearDown(() => temp.deleteSync(recursive: true));

    file.writeAsBytesSync(_mp4Fixture(
      trackArtists: [
        'Track Artist',
        ' Guest Artist ',
        '',
        'Track Artist',
      ],
      albumArtists: ['Album Artist', 'Album Credit'],
    ));

    final metadata = readAllMetadata(file, getImage: false) as Mp4Metadata;
    expect(metadata.artist, 'Track Artist');
    expect(metadata.artists, ['Track Artist', 'Guest Artist']);
    expect(metadata.albumArtist, 'Album Artist');
    expect(metadata.albumArtists, ['Album Artist', 'Album Credit']);
  });

  test('ID3v2.4 preserves NUL-separated TPE1 and TPE2 values', () {
    final temp = Directory.systemTemp.createTempSync('melo_id3_artist_test_');
    final file = File('${temp.path}/artists.mp3');
    addTearDown(() => temp.deleteSync(recursive: true));
    file.writeAsBytesSync(_id3v24Fixture(
      trackArtists: ['Track Artist', 'Guest Artist'],
      albumArtists: ['Album Artist', 'Album Credit'],
    ));

    final metadata = readAllMetadata(file, getImage: false) as Mp3Metadata;

    expect(metadata.leadPerformers, ['Track Artist', 'Guest Artist']);
    expect(metadata.bandsOrOrchestras, ['Album Artist', 'Album Credit']);
    expect(metadata.leadPerformer, 'Track Artist');
    expect(metadata.bandOrOrchestra, 'Album Artist');
  });

  test('APE fixture preserves NUL-separated artist values in order', () {
    final temp = Directory.systemTemp.createTempSync('melo_ape_artist_test_');
    final file = File('${temp.path}/artists.ape');
    addTearDown(() => temp.deleteSync(recursive: true));
    file.writeAsBytesSync(_apeFixture({
      'ARTIST': 'Track Artist\u0000 Guest Artist \u0000\u0000Track Artist',
      'ALBUMARTIST': 'Album Artist\u0000Album Credit',
    }));

    final metadata = readAllMetadata(file, getImage: false) as ApeMetadata;

    expect(metadata.artist, 'Track Artist');
    expect(metadata.artists, ['Track Artist', 'Guest Artist']);
    expect(metadata.albumArtist, 'Album Artist');
    expect(metadata.albumArtists, ['Album Artist', 'Album Credit']);
  });

  test('OGG fixture with trailing APEv2 tag is parsed as VorbisMetadata', () {
    final temp = Directory.systemTemp.createTempSync('melo_ogg_ape_test_');
    final file = File('${temp.path}/artists_with_ape.ogg');
    addTearDown(() => temp.deleteSync(recursive: true));

    final oggBytes = _oggFixture([
      'ARTIST=Track Artist',
      'ALBUMARTIST=Album Artist',
    ]);
    final apeBytes = _apeFixture({
      'ARTIST': 'Ape Track Artist',
    });

    file.writeAsBytesSync([...oggBytes, ...apeBytes]);

    final rawMetadata = readAllMetadata(file, getImage: false);
    expect(rawMetadata, isA<VorbisMetadata>());
    expect((rawMetadata as VorbisMetadata).artist, ['Track Artist']);

    final highLevelMetadata = readMetadata(file, getImage: false);
    expect(highLevelMetadata.artist, 'Track Artist');
  });

  test('APE fixture prefers standard ALBUMARTIST over non-standard Album Artist', () {
    final temp = Directory.systemTemp.createTempSync('melo_ape_standard_test_');
    final file = File('${temp.path}/artists.ape');
    addTearDown(() => temp.deleteSync(recursive: true));
    file.writeAsBytesSync(_apeFixture({
      'Album Artist': 'Garbled Album Artist',
      'ALBUMARTIST': 'Correct Album Artist',
    }));

    final metadata = readAllMetadata(file, getImage: false) as ApeMetadata;

    expect(metadata.albumArtist, 'Correct Album Artist');
    expect(metadata.albumArtists, ['Correct Album Artist']);
  });
}

List<int> _oggFixture(List<String> comments) {
  final vendor = utf8.encode('MeloUnion');
  final payload = <int>[
    ...ascii.encode('OpusTags'),
    ..._uint32LittleEndian(vendor.length),
    ...vendor,
    ..._uint32LittleEndian(comments.length),
    for (final comment in comments) ...[
      ..._uint32LittleEndian(utf8.encode(comment).length),
      ...utf8.encode(comment),
    ],
  ];
  return [
    ..._oggPage(0, ascii.encode('MeloHead')),
    ..._oggPage(1, payload),
  ];
}

List<int> _oggPage(int sequence, List<int> payload) => [
      ...ascii.encode('OggS'),
      0,
      sequence == 0 ? 0x02 : 0x04,
      ...List<int>.filled(8, 0),
      ..._uint32LittleEndian(1),
      ..._uint32LittleEndian(sequence),
      ...List<int>.filled(4, 0),
      1,
      payload.length,
      ...payload,
    ];

List<int> _id3v24Fixture({
  required List<String> trackArtists,
  required List<String> albumArtists,
}) {
  final frames = [
    ..._id3v24TextFrame('TPE1', trackArtists),
    ..._id3v24TextFrame('TPE2', albumArtists),
  ];
  return [
    ...ascii.encode('ID3'),
    4,
    0,
    0,
    ..._syncSafe(frames.length),
    ...frames,
  ];
}

List<int> _id3v24TextFrame(String id, List<String> values) {
  final payload = [3, ...utf8.encode(values.join('\u0000'))];
  return [
    ...ascii.encode(id),
    ..._syncSafe(payload.length),
    0,
    0,
    ...payload,
  ];
}

List<int> _apeFixture(Map<String, String> values) {
  final items = <int>[];
  for (final entry in values.entries) {
    final value = utf8.encode(entry.value);
    items.addAll([
      ..._uint32LittleEndian(value.length),
      ..._uint32LittleEndian(0),
      ...ascii.encode(entry.key),
      0,
      ...value,
    ]);
  }
  return [
    1,
    2,
    3,
    ...items,
    ...ascii.encode('APETAGEX'),
    ..._uint32LittleEndian(2000),
    ..._uint32LittleEndian(items.length + 32),
    ..._uint32LittleEndian(values.length),
    ..._uint32LittleEndian(0),
    ...List<int>.filled(8, 0),
  ];
}

List<int> _uint32LittleEndian(int value) {
  final bytes = ByteData(4)..setUint32(0, value, Endian.little);
  return bytes.buffer.asUint8List();
}

List<int> _syncSafe(int value) => [
      (value >> 21) & 0x7f,
      (value >> 14) & 0x7f,
      (value >> 7) & 0x7f,
      value & 0x7f,
    ];

List<int> _mp4Fixture({
  required List<String> trackArtists,
  required List<String> albumArtists,
}) {
  final ilst = _box('ilst', [
    for (final trackArtist in trackArtists) ..._textAtom('©ART', trackArtist),
    for (final albumArtist in albumArtists) ..._textAtom('aART', albumArtist),
  ]);
  final meta = _box('meta', [0, 0, 0, 0, ...ilst]);
  final udta = _box('udta', meta);
  final moov = _box('moov', udta);
  return [
    ..._box('ftyp', ascii.encode('M4A ')),
    ...moov,
  ];
}

List<int> _textAtom(String type, String value) {
  final bytes = utf8.encode(value);
  final data = _box('data', [0, 0, 0, 1, 0, 0, 0, 0, ...bytes]);
  return _box(type, data);
}

List<int> _box(String type, List<int> payload) {
  final length = payload.length + 8;
  final lengthBytes = ByteData(4)..setUint32(0, length);
  return [
    ...lengthBytes.buffer.asUint8List(),
    ...latin1.encode(type),
    ...payload,
  ];
}
