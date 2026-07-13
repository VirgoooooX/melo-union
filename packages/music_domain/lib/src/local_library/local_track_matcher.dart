import 'package:provider_contract/provider_contract.dart';

import 'local_library_models.dart';

final class LocalTrackMatcher {
  const LocalTrackMatcher();

  LocalTrackMatch? match(
      SourceTrack remote, Iterable<LocalLibraryTrack> localTracks) {
    final available = localTracks.where((track) => track.isAvailable).toList();
    final remoteIsrc = _isrc(remote.isrc);
    if (remoteIsrc != null) {
      final matches =
          available.where((track) => _isrc(track.isrc) == remoteIsrc).toList();
      if (matches.length == 1) {
        return _result(remote, matches.single, 'isrc', 1);
      }
      if (matches.length > 1) {
        final selected = _uniqueByAlbum(remote.album, matches);
        if (selected != null) {
          return _result(remote, selected, 'isrc_album', .99);
        }
      }
      return null;
    }

    final title = normalizeLocalMetadata(remote.title);
    final artists = _artistIdentity(remote.artists);
    final candidates = available.where((track) {
      return normalizeLocalMetadata(track.title) == title &&
          _artistIdentity(track.artists) == artists &&
          (track.duration - remote.duration).abs() <=
              const Duration(seconds: 2);
    }).toList();
    if (candidates.length == 1) {
      return _result(remote, candidates.single, 'metadata', .9);
    }
    final selected = _uniqueByAlbum(remote.album, candidates);
    return selected == null
        ? null
        : _result(remote, selected, 'metadata_album', .92);
  }

  LocalLibraryTrack? _uniqueByAlbum(
      String? album, List<LocalLibraryTrack> values) {
    if (album == null || album.trim().isEmpty) return null;
    final normalized = normalizeLocalMetadata(album);
    final matches = values
        .where(
            (track) => normalizeLocalMetadata(track.album ?? '') == normalized)
        .toList();
    return matches.length == 1 ? matches.single : null;
  }

  LocalTrackMatch _result(SourceTrack remote, LocalLibraryTrack local,
          String method, double confidence) =>
      LocalTrackMatch(
        remote: remote.ref,
        localTrackId: local.id,
        method: method,
        confidence: confidence,
        updatedAt: DateTime.now().toUtc(),
      );
}

String? _isrc(String? value) {
  final normalized =
      value?.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String _artistIdentity(List<String> artists) {
  final normalized = artists
      .map(normalizeLocalMetadata)
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList()
    ..sort();
  return normalized.join('|');
}
