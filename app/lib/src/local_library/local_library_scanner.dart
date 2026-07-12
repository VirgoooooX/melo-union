import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:music_domain/music_domain.dart';
import 'package:path/path.dart' as path;

const _supportedExtensions = {
  '.mp3',
  '.flac',
  '.m4a',
  '.aac',
  '.wav',
  '.ogg',
  '.opus',
  '.ape',
};

final class LocalLibraryScanProgress {
  const LocalLibraryScanProgress({
    required this.rootId,
    required this.discovered,
    required this.processed,
    required this.imported,
    this.currentPath,
  });

  final String rootId;
  final int discovered;
  final int processed;
  final int imported;
  final String? currentPath;
}

final class LocalLibraryScanner {
  LocalLibraryScanner(
      {required this.repository, required this.artworkDirectory});

  final LocalLibraryRepository repository;
  final Directory artworkDirectory;
  bool _cancelled = false;

  void cancel() => _cancelled = true;

  Future<void> scan(
    LocalLibraryRoot root, {
    required ValueChanged<LocalLibraryScanProgress> onProgress,
  }) async {
    _cancelled = false;
    await repository.upsertRoot(root.copyWith(
      scanState: LocalLibraryScanState.scanning,
      clearError: true,
    ));
    try {
      final paths = await Isolate.run(() => _enumerateAudioFiles(root.path));
      final availablePaths = paths.toSet();
      final indexedTracks = await repository.listTracks(limit: 1000000);
      final tracksByPath = {
        for (final track in indexedTracks) track.filePath: track,
      };
      final tracksByFingerprint = <String, List<LocalLibraryTrack>>{};
      for (final track in indexedTracks) {
        tracksByFingerprint.putIfAbsent(track.fingerprint, () => []).add(track);
      }
      var processed = 0;
      var imported = 0;
      var lastProgressAt = DateTime.fromMillisecondsSinceEpoch(0);
      final pending = <LocalLibraryTrack>[];

      for (final filePath in paths) {
        if (_cancelled) break;
        final stat = await File(filePath).stat();
        final existing = tracksByPath[filePath];
        if (existing != null &&
            existing.fileSize == stat.size &&
            existing.modifiedAt.isAtSameMomentAs(stat.modified)) {
          processed++;
          continue;
        }

        final parsed = await Isolate.run(() => _readLocalMetadata(filePath));
        final fingerprint = parsed.fingerprint;
        LocalLibraryTrack? matched;
        if (existing == null) {
          final matches = tracksByFingerprint[fingerprint] ?? const [];
          if (matches.length == 1 &&
              !availablePaths.contains(matches.single.filePath)) {
            matched = matches.single;
          }
        }
        final id = existing?.id ?? matched?.id ?? _newId();
        final artworkPath = await _persistArtwork(
            id, parsed.pictureBytes, parsed.pictureExtension);
        pending.add(LocalLibraryTrack(
          id: id,
          rootId: root.id,
          filePath: filePath,
          relativePath: path.relative(filePath, from: root.path),
          fileSize: stat.size,
          modifiedAt: stat.modified,
          fingerprint: fingerprint,
          title: parsed.title?.trim().isNotEmpty == true
              ? parsed.title!.trim()
              : path.basenameWithoutExtension(filePath),
          artists: parsed.artist?.trim().isNotEmpty == true
              ? [parsed.artist!.trim()]
              : const ['未知歌手'],
          album: parsed.album?.trim().isEmpty == true
              ? null
              : parsed.album?.trim(),
          duration: parsed.duration,
          format: path.extension(filePath).substring(1).toUpperCase(),
          genre: parsed.genre,
          year: parsed.year,
          trackNumber: parsed.trackNumber,
          discNumber: parsed.discNumber,
          lyrics: parsed.lyrics,
          artworkPath:
              artworkPath ?? existing?.artworkPath ?? matched?.artworkPath,
          isAvailable: true,
          isFavorited: existing?.isFavorited ?? matched?.isFavorited ?? false,
          likedAt: existing?.likedAt ?? matched?.likedAt,
        ));
        imported++;
        processed++;
        if (pending.length >= 200) {
          await repository.upsertTracks(List.of(pending));
          pending.clear();
        }
        final now = DateTime.now();
        if (now.difference(lastProgressAt) >=
            const Duration(milliseconds: 120)) {
          onProgress(LocalLibraryScanProgress(
            rootId: root.id,
            discovered: paths.length,
            processed: processed,
            imported: imported,
            currentPath: filePath,
          ));
          lastProgressAt = now;
        }
      }
      await repository.upsertTracks(pending);
      if (!_cancelled) {
        await repository.markUnavailableExcept(root.id, availablePaths);
      }
      await repository.upsertRoot(root.copyWith(
        scanState: _cancelled
            ? LocalLibraryScanState.idle
            : LocalLibraryScanState.completed,
        lastScannedAt: _cancelled ? root.lastScannedAt : DateTime.now().toUtc(),
        clearError: true,
      ));
      onProgress(LocalLibraryScanProgress(
        rootId: root.id,
        discovered: paths.length,
        processed: processed,
        imported: imported,
      ));
    } catch (error) {
      if (error is FileSystemException) {
        await repository.markUnavailableExcept(root.id, const {});
      }
      await repository.upsertRoot(root.copyWith(
        scanState: LocalLibraryScanState.failed,
        lastError: error.toString(),
      ));
      rethrow;
    }
  }

  Future<String?> _persistArtwork(
    String id,
    Uint8List? bytes,
    String? extension,
  ) async {
    if (bytes == null || bytes.isEmpty) return null;
    await artworkDirectory.create(recursive: true);
    final file =
        File(path.join(artworkDirectory.path, '$id.${extension ?? 'img'}'));
    await file.writeAsBytes(bytes, flush: false);
    return file.path;
  }
}

List<String> _enumerateAudioFiles(String rootPath) {
  final root = Directory(rootPath);
  if (!root.existsSync()) throw FileSystemException('曲库目录不可访问', rootPath);
  final result = <String>[];
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) continue;
    if (_supportedExtensions
        .contains(path.extension(entity.path).toLowerCase())) {
      result.add(path.normalize(entity.absolute.path));
    }
  }
  result.sort();
  return result;
}

final class _ParsedLocalMetadata {
  const _ParsedLocalMetadata({
    required this.fingerprint,
    required this.duration,
    this.title,
    this.artist,
    this.album,
    this.genre,
    this.year,
    this.trackNumber,
    this.discNumber,
    this.lyrics,
    this.pictureBytes,
    this.pictureExtension,
  });

  final String fingerprint;
  final Duration duration;
  final String? title;
  final String? artist;
  final String? album;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final String? lyrics;
  final Uint8List? pictureBytes;
  final String? pictureExtension;
}

_ParsedLocalMetadata _readLocalMetadata(String filePath) {
  final file = File(filePath);
  AudioMetadata? metadata;
  try {
    metadata = readMetadata(file, getImage: true);
  } catch (_) {
    // A damaged tag must not prevent the file itself from being indexed.
  }
  final picture =
      metadata?.pictures.isNotEmpty == true ? metadata!.pictures.first : null;
  return _ParsedLocalMetadata(
    fingerprint: _quickFingerprint(file),
    duration: metadata?.duration ?? Duration.zero,
    title: metadata?.title,
    artist: metadata?.artist,
    album: metadata?.album,
    genre: metadata?.genres.isNotEmpty == true ? metadata!.genres.first : null,
    year: metadata?.year?.year,
    trackNumber: metadata?.trackNumber,
    discNumber: metadata?.discNumber,
    lyrics: metadata?.lyrics,
    pictureBytes: picture?.bytes,
    pictureExtension:
        picture == null ? null : _extensionForMime(picture.mimetype),
  );
}

String _quickFingerprint(File file) {
  final length = file.lengthSync();
  final handle = file.openSync();
  var hash = 0x811c9dc5;
  try {
    for (final offset in {
      0,
      max(0, length ~/ 2 - 32768),
      max(0, length - 65536)
    }) {
      handle.setPositionSync(offset);
      final bytes = handle.readSync(min(65536, length - offset));
      for (final byte in bytes) {
        hash ^= byte;
        hash = (hash * 0x01000193) & 0xffffffff;
      }
    }
  } finally {
    handle.closeSync();
  }
  return '${length.toRadixString(16)}-${hash.toRadixString(16).padLeft(8, '0')}';
}

String? _extensionForMime(String mime) {
  final normalized = mime.toLowerCase();
  if (normalized.contains('png')) return 'png';
  if (normalized.contains('webp')) return 'webp';
  if (normalized.contains('gif')) return 'gif';
  return 'jpg';
}

String _newId() {
  final random = Random.secure();
  return '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-'
      '${random.nextInt(1 << 32).toRadixString(36)}';
}
