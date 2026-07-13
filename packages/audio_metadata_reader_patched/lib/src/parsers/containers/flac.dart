import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/src/metadata/base.dart';
import 'package:audio_metadata_reader/src/parsers/tags/tag_parser.dart';
import 'package:audio_metadata_reader/src/parsers/tags/vorbis_comment.dart';
import 'package:audio_metadata_reader/src/utils/buffer.dart';
import 'package:audio_metadata_reader/src/utils/metadata_limits.dart';
import 'package:audio_metadata_reader/src/utils/metadata_parser_exception.dart';

import 'package:audio_metadata_reader/src/utils/bit_manipulator.dart';

/// FLAC metadata block types as defined by the FLAC specification.
enum BlockType {
  streamInfo,
  padding,
  application,
  seekTable,
  vorbisComment,
  cueSheet,
  picture,
  reserved,
  invalid,
}

/// Parsed FLAC metadata block header information.
typedef MetadataBlockHeader = ({bool isLastBlock, int type, int length});

///
/// Parser for a FLAC file
///
/// A FLAC file is made of blocks. 3 blocks are interesting for us:
/// - STREAMINFO: bitrate ; samplerate ; duration
/// - VORBIS_COMMENT: contains all the metadata
/// - PICTURE: to get the pictures. Can have multiple `PICTURE` blocks
///
/// All numbers are big-endian coded expecting the numbers from the
/// Vorbis comment
///
/// Documentation: https://xiph.org/flac/format.html
class FlacParser extends TagParser<VorbisMetadata> {
  /// Parsed Vorbis-style metadata values.
  final metadata = VorbisMetadata();

  /// Reader helper bound to the current file.
  late final Buffer buffer;
  int _metadataBytes = 0;

  /// Create a FLAC parser.
  FlacParser({super.fetchImage = false});

  @override
  VorbisMetadata parse(RandomAccessFile reader) {
    reader.setPositionSync(0);

    buffer = Buffer(randomAccessFile: reader);

    buffer.skip(4);

    bool isLastBlock = false;
    while (!isLastBlock) {
      final block = _parseMetadataBlock(reader);

      isLastBlock = block.isLastBlock;
    }

    reader.closeSync();

    return metadata;
  }

  MetadataBlockHeader _parseMetadataBlock(RandomAccessFile reader) {
    final bytes = buffer.read(4);
    final byteNumber = bytes[0];

    final MetadataBlockHeader block = (
      isLastBlock: byteNumber >> 7 == 1, // 0: not last block - 1: last block
      type: byteNumber & 0x7F, // keep the 7 next bits (0XXXXXXX)
      length: bytes[3] | bytes[2] << 8 | bytes[1] << 16,
    );
    _metadataBytes += 4 + block.length;
    if (_metadataBytes > maxMetadataBytes) {
      throw MetadataParserException(
        track: File(''),
        message: 'FLAC metadata exceeds the $maxMetadataBytes-byte limit',
      );
    }

    switch (block.type) {
      case 0:
        buffer.skip(10);

        final end = ByteData.sublistView(buffer.read(8)).getUint64(0);

        final sampleRate = getIntFromArbitraryBits(end, 0, 20);
        final bitPerSample = getIntFromArbitraryBits(end, 23, 5) + 1;
        final totalSamplesInSteam = getIntFromArbitraryBits(end, 28, 36);
        final duration = totalSamplesInSteam / sampleRate * 1000;

        metadata.duration = Duration(milliseconds: duration.toInt());
        metadata.sampleRate = sampleRate;
        metadata.bitrate = (bitPerSample * sampleRate).toInt();

        buffer.skip(16); // signature (128 ~/ 8)
        break;
      case 3:
        buffer.skip(block.length);
        break;
      case 4:
        if (block.length > maxMetadataFrameBytes) {
          buffer.skip(block.length);
          break;
        }
        final bytes = buffer.read(block.length);
        _parseVorbisComment(bytes);
        break;
      case 6:
        if (!fetchImage || block.length > maxMetadataFrameBytes) {
          buffer.skip(block.length);
        } else {
          final bytes = buffer.read(block.length);
          final picture = _parsePictureBlock(bytes);
          if (picture != null) metadata.pictures.add(picture);
        }
        break;
      default:
        buffer.skip(block.length);
        break;
    }

    return block;
  }

  Picture? _parsePictureBlock(Uint8List bytes) {
    var offset = 0;
    int readUint32() {
      if (offset + 4 > bytes.length) throw const FormatException();
      final value = getUint32(bytes.sublist(offset, offset + 4));
      offset += 4;
      return value;
    }

    Uint8List readBytes(int length) {
      if (length < 0 || offset + length > bytes.length) {
        throw const FormatException();
      }
      final value = bytes.sublist(offset, offset + length);
      offset += length;
      return value;
    }

    try {
      final pictureType = readUint32();
      final mime = String.fromCharCodes(readBytes(readUint32()));
      readBytes(readUint32());
      readBytes(16);
      final imageLength = readUint32();
      if (imageLength > maxEmbeddedArtworkBytes) return null;
      final data = readBytes(imageLength);
      return Picture(data, mime, getPictureTypeEnum(pictureType));
    } on FormatException {
      return null;
    }
  }

  /// To detect if this parser can be used to parse this file, the 4 first bytes
  /// must be equal to `fLaC`
  /// Returns `true` when [reader] looks like a FLAC file.
  static bool canUserParser(RandomAccessFile reader) {
    reader.setPositionSync(0);
    final vendorName = String.fromCharCodes(reader.readSync(4));
    return vendorName == "fLaC";
  }

  /// Parse Vorbis comments block and delegate each individual comment to the
  /// shared Vorbis comment codec used by OGG.
  void _parseVorbisComment(Uint8List bytes) {
    int offset = 0;

    final vendorLength = getUint32LE(bytes.sublist(0, 4));
    offset = offset + 4 + vendorLength;
    final userCommentListLength = getUint32LE(
      bytes.sublist(offset, offset + 4),
    ); // it's the number of comments / tags / metadata (the way you want to call it)
    offset += 4;

    for (var i = 0; i < userCommentListLength; i++) {
      final length = getUint32LE(bytes.sublist(offset, offset + 4));
      offset += 4;
      final comment = bytes.sublist(offset, offset + length);
      offset += length;
      parseVorbisComment(comment, metadata, fetchImage);
    }
  }
}
