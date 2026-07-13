import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:test/test.dart';

void main() {
  test('ID3 keeps earlier text when a later APIC declares an oversized payload',
      () {
    // Given
    final temp = Directory.systemTemp.createTempSync('audio_limits_id3_');
    final file = File('${temp.path}/oversized-art.mp3');
    addTearDown(() => temp.deleteSync(recursive: true));
    final titlePayload = <int>[0, ...latin1.encode('Safe title')];
    final titleFrame = [
      ..._id3FrameHeader('TIT2', titlePayload.length),
      ...titlePayload,
    ];
    const declaredArtworkSize = 64 * 1024 * 1024;
    final apicHeader = _id3FrameHeader('APIC', declaredArtworkSize);
    file.writeAsBytesSync([
      ...ascii.encode('ID3'),
      3,
      0,
      0,
      ..._syncSafe(titleFrame.length + apicHeader.length + declaredArtworkSize),
      ...titleFrame,
      ...apicHeader,
      0,
    ]);

    // When
    final metadata = readAllMetadata(file, getImage: true) as Mp3Metadata;

    // Then
    expect(metadata.songName, 'Safe title');
    expect(metadata.pictures, isEmpty);
  });

  test('ID3 rejects a huge truncated frame before reading its payload', () {
    // Given
    final temp = Directory.systemTemp.createTempSync('audio_limits_truncated_');
    final file = File('${temp.path}/truncated.mp3');
    addTearDown(() => temp.deleteSync(recursive: true));
    const declaredFrameSize = 64 * 1024 * 1024;
    final frameHeader = _id3FrameHeader('TIT2', declaredFrameSize);
    file.writeAsBytesSync([
      ...ascii.encode('ID3'),
      3,
      0,
      0,
      ..._syncSafe(frameHeader.length + declaredFrameSize),
      ...frameHeader,
      0,
    ]);

    // When
    Object? error;
    try {
      readAllMetadata(file, getImage: true);
    } catch (caught) {
      error = caught;
    }

    // Then
    expect(error, isA<MetadataParserException>());
    expect(error.toString(), contains('remaining tag bytes'));
  });

  test('ID3 keeps a normal small embedded cover', () {
    // Given
    final temp = Directory.systemTemp.createTempSync('audio_limits_small_');
    final file = File('${temp.path}/small-art.mp3');
    addTearDown(() => temp.deleteSync(recursive: true));
    file.writeAsBytesSync(_id3WithArtwork(
      artworkSize: 128,
      title: 'Small cover',
    ));

    // When
    final metadata = readAllMetadata(file, getImage: true) as Mp3Metadata;

    // Then
    expect(metadata.songName, 'Small cover');
    expect(metadata.pictures, hasLength(1));
    expect(metadata.pictures.single.bytes, isNotEmpty);
  });
}

List<int> _id3WithArtwork({
  required int artworkSize,
  required String title,
}) {
  final titlePayload = <int>[0, ...latin1.encode(title)];
  final titleFrame = [
    ..._id3FrameHeader('TIT2', titlePayload.length),
    ...titlePayload,
  ];
  final apicPrefix = <int>[
    0,
    ...ascii.encode('image/jpeg'),
    0,
    3,
    0,
  ];
  final apicSize = apicPrefix.length + artworkSize;
  final apicHeader = _id3FrameHeader('APIC', apicSize);
  final tagSize = apicHeader.length + apicSize + titleFrame.length;
  return [
    ...ascii.encode('ID3'),
    3,
    0,
    0,
    ..._syncSafe(tagSize),
    ...apicHeader,
    ...apicPrefix,
    ...List<int>.filled(artworkSize, 1),
    ...titleFrame,
  ];
}

List<int> _id3FrameHeader(String id, int size) {
  final bytes = ByteData(4)..setUint32(0, size);
  return [...ascii.encode(id), ...bytes.buffer.asUint8List(), 0, 0];
}

List<int> _syncSafe(int value) => [
      (value >> 21) & 0x7f,
      (value >> 14) & 0x7f,
      (value >> 7) & 0x7f,
      value & 0x7f,
    ];
