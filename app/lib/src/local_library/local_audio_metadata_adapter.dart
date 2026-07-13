import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';

/// Project-level, format-neutral view over the dependency's raw tag models.
///
/// Using [readAllMetadata] is important here: the dependency's high-level
/// mapping historically conflated track artist and album artist in MP3 and
/// Vorbis files.
final class LocalAudioTags {
  const LocalAudioTags({
    this.title,
    this.trackArtists = const [],
    this.albumArtist,
    this.album,
    this.duration = Duration.zero,
    this.genres = const [],
    this.performers = const [],
    this.bitRate,
    this.sampleRate,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.isrc,
    this.lyrics,
    this.pictureBytes,
    this.pictureMime,
  });

  final String? title;
  final List<String> trackArtists;
  final String? albumArtist;
  final String? album;
  final Duration duration;
  final List<String> genres;
  final List<String> performers;
  final int? bitRate;
  final int? sampleRate;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final String? isrc;
  final String? lyrics;
  final Uint8List? pictureBytes;
  final String? pictureMime;
}

LocalAudioTags readLocalAudioTags(File file, {bool getImage = true}) {
  final raw = readAllMetadata(file, getImage: getImage);
  return localAudioTagsFromRaw(raw);
}

LocalAudioTags localAudioTagsFromRaw(Object raw) {
  return switch (raw) {
    Mp3Metadata metadata => _fromMp3(metadata),
    VorbisMetadata metadata => _fromVorbis(metadata),
    Mp4Metadata metadata => _fromMp4(metadata),
    ApeMetadata metadata => _fromApe(metadata),
    RiffMetadata metadata => _fromRiff(metadata),
    _ => throw ArgumentError.value(raw, 'raw', 'Unsupported audio metadata'),
  };
}

LocalAudioTags _fromMp3(Mp3Metadata metadata) => LocalAudioTags(
      title: metadata.songName,
      trackArtists: metadata.leadPerformers.isNotEmpty
          ? _strings(metadata.leadPerformers)
          : _strings([metadata.leadPerformer ?? metadata.originalArtist]),
      albumArtist: metadata.bandsOrOrchestras.isNotEmpty
          ? _joinedCredit(metadata.bandsOrOrchestras)
          : _joinedCredit([metadata.bandOrOrchestra]),
      album: metadata.album,
      duration: metadata.duration ?? Duration.zero,
      genres: List<String>.unmodifiable(metadata.genres),
      performers: _strings(
        metadata.customMetadata['GUEST ARTIST']?.split('/'),
      ),
      bitRate: metadata.bitrate,
      sampleRate: metadata.samplerate,
      year: metadata.originalReleaseYear ?? metadata.year,
      trackNumber: metadata.trackNumber,
      discNumber: metadata.discNumber,
      isrc: metadata.isrc,
      lyrics: metadata.lyric,
      pictureBytes: _boundedPicture(metadata.pictures.firstOrNull)?.bytes,
      pictureMime: _boundedPicture(metadata.pictures.firstOrNull)?.mimetype,
    );

LocalAudioTags _fromVorbis(VorbisMetadata metadata) => LocalAudioTags(
      title: _first(metadata.title),
      trackArtists: _strings(metadata.artist),
      albumArtist: _joinedCredit(metadata.albumArtist),
      album: _first(metadata.album),
      duration: metadata.duration ?? Duration.zero,
      genres: List<String>.unmodifiable(metadata.genres),
      performers: _strings(metadata.performer),
      bitRate: metadata.bitrate,
      sampleRate: metadata.sampleRate,
      year: _first(metadata.date)?.year,
      trackNumber: _first(metadata.trackNumber),
      discNumber: metadata.discNumber,
      isrc: _first(metadata.isrc),
      lyrics: metadata.lyric,
      pictureBytes: _boundedPicture(metadata.pictures.firstOrNull)?.bytes,
      pictureMime: _boundedPicture(metadata.pictures.firstOrNull)?.mimetype,
    );

LocalAudioTags _fromMp4(Mp4Metadata metadata) => LocalAudioTags(
      title: metadata.title,
      trackArtists: metadata.artists.isNotEmpty
          ? _strings(metadata.artists)
          : _strings([metadata.artist]),
      albumArtist: metadata.albumArtists.isNotEmpty
          ? _joinedCredit(metadata.albumArtists)
          : _joinedCredit([metadata.albumArtist]),
      album: metadata.album,
      duration: metadata.duration ?? Duration.zero,
      genres: _strings([metadata.genre]),
      bitRate: metadata.bitrate,
      sampleRate: metadata.sampleRate,
      year: metadata.year?.year,
      trackNumber: metadata.trackNumber,
      discNumber: metadata.discNumber,
      lyrics: metadata.lyrics,
      pictureBytes: _boundedPicture(metadata.picture)?.bytes,
      pictureMime: _boundedPicture(metadata.picture)?.mimetype,
    );

LocalAudioTags _fromApe(ApeMetadata metadata) => LocalAudioTags(
      title: metadata.title,
      trackArtists: metadata.artists.isNotEmpty
          ? _strings(metadata.artists)
          : _strings([metadata.artist]),
      albumArtist: metadata.albumArtists.isNotEmpty
          ? _joinedCredit(metadata.albumArtists)
          : _joinedCredit([metadata.albumArtist]),
      album: metadata.album,
      duration: metadata.duration ?? Duration.zero,
      genres: List<String>.unmodifiable(metadata.genres),
      performers: _strings(metadata.performer),
      bitRate: metadata.bitrate,
      sampleRate: metadata.sampleRate,
      year: metadata.date?.year,
      trackNumber: metadata.trackNumber,
      discNumber: metadata.discNumber,
      lyrics: metadata.lyric,
      pictureBytes: _boundedPicture(metadata.pictures.firstOrNull)?.bytes,
      pictureMime: _boundedPicture(metadata.pictures.firstOrNull)?.mimetype,
    );

LocalAudioTags _fromRiff(RiffMetadata metadata) => LocalAudioTags(
      title: metadata.title,
      trackArtists: _strings([metadata.artist]),
      album: metadata.album,
      duration: metadata.duration ?? Duration.zero,
      genres: _strings([metadata.genre]),
      bitRate: metadata.bitrate,
      sampleRate: metadata.samplerate,
      year: metadata.year?.year,
      trackNumber: metadata.trackNumber,
      pictureBytes: _boundedPicture(metadata.pictures.firstOrNull)?.bytes,
      pictureMime: _boundedPicture(metadata.pictures.firstOrNull)?.mimetype,
    );

T? _first<T>(List<T> values) => values.isEmpty ? null : values.first;

List<String> _strings(Iterable<String?>? values) {
  final seen = <String>{};
  return List.unmodifiable(
    (values ?? const <String>[])
        .map((value) => value?.trim())
        .whereType<String>()
        .where((value) => value.isNotEmpty && seen.add(value)),
  );
}

String? _joinedCredit(Iterable<String?> values) {
  final credits = _strings(values);
  return credits.isEmpty ? null : credits.join(' / ');
}

Picture? _boundedPicture(Picture? picture) =>
    picture != null && picture.bytes.length <= maxEmbeddedArtworkBytes
        ? picture
        : null;
