import 'dart:async';

import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

typedef LocalLyricsProviderEntries = Iterable<ProviderRegistryEntry> Function();

/// Supplies lyrics for local tracks that do not contain lyrics in their audio
/// tags. Online results are accepted only after an exact metadata match and
/// are cached in the local-library index; original audio files are not edited.
final class LocalLyricsEnrichmentService {
  LocalLyricsEnrichmentService({
    required this.repository,
    required LocalLyricsProviderEntries providerEntries,
    this.providerTimeout = const Duration(seconds: 20),
  }) : _providerEntries = providerEntries;

  final LocalLibraryRepository repository;
  final LocalLyricsProviderEntries _providerEntries;
  final Duration providerTimeout;
  final Map<String, Future<String?>> _inFlight = {};

  Future<String?> getLyrics(ProviderTrackRef ref) {
    if (ref.providerId != localMusicProviderId) return Future.value();
    final current = _inFlight[ref.trackId];
    if (current != null) return current;

    late final Future<String?> request;
    request = _getLyrics(ref.trackId).whenComplete(() {
      if (identical(_inFlight[ref.trackId], request)) {
        _inFlight.remove(ref.trackId);
      }
    });
    _inFlight[ref.trackId] = request;
    return request;
  }

  Future<String?> _getLyrics(String trackId) async {
    final local = await repository.getTrack(trackId);
    if (local == null) return null;
    final embedded = _nonEmpty(local.lyrics);
    if (embedded != null) return embedded;

    for (final entry in _orderedProviders(_providerEntries())) {
      final resolved = await _tryProvider(entry.provider, local);
      if (resolved == null) continue;

      // A cache write failure should not hide lyrics that were fetched
      // successfully for the current playback session.
      try {
        await repository.upsertTracks([
          local.copyWith(lyrics: resolved.lyrics),
        ]);
        await repository.upsertLocalTrackMatch(LocalTrackMatch(
          remote: resolved.track.ref,
          localTrackId: local.id,
          method: resolved.isrcMatched ? 'lyrics_isrc' : 'lyrics_metadata',
          confidence: resolved.isrcMatched ? 1 : .9,
          updatedAt: DateTime.now().toUtc(),
        ));
      } on Object {
        // Returning the fetched value is more useful than failing playback UI.
      }
      return resolved.lyrics;
    }
    return null;
  }

  Future<_ResolvedLyrics?> _tryProvider(
    MusicProvider provider,
    LocalLibraryTrack local,
  ) async {
    try {
      return await (() async {
        final query = [local.title, ...local.artists].join(' ').trim();
        final candidates = await provider.search(query);
        final match = _bestMatch(local, candidates);
        if (match == null) return null;
        final lyrics = _nonEmpty(await provider.getLyrics(match.track.ref));
        if (lyrics == null) return null;
        return _ResolvedLyrics(
          track: match.track,
          lyrics: lyrics,
          isrcMatched: match.isrcMatched,
        );
      })()
          .timeout(providerTimeout);
    } on Object {
      return null;
    }
  }
}

final class _TrackMatch {
  const _TrackMatch({
    required this.track,
    required this.score,
    required this.isrcMatched,
  });

  final SourceTrack track;
  final int score;
  final bool isrcMatched;
}

final class _ResolvedLyrics {
  const _ResolvedLyrics({
    required this.track,
    required this.lyrics,
    required this.isrcMatched,
  });

  final SourceTrack track;
  final String lyrics;
  final bool isrcMatched;
}

_TrackMatch? _bestMatch(
  LocalLibraryTrack local,
  Iterable<SourceTrack> candidates,
) {
  final matches = candidates
      .map((candidate) => _scoreCandidate(local, candidate))
      .whereType<_TrackMatch>()
      .toList(growable: false)
    ..sort((left, right) => right.score.compareTo(left.score));
  if (matches.isEmpty) return null;
  if (matches.length > 1 && matches[0].score == matches[1].score) {
    return null;
  }
  return matches.first;
}

_TrackMatch? _scoreCandidate(
  LocalLibraryTrack local,
  SourceTrack remote,
) {
  if (normalizeLocalMetadata(local.title) !=
      normalizeLocalMetadata(remote.title)) {
    return null;
  }

  final localArtists = _artistIdentity(local.artists);
  final remoteArtists = _artistIdentity(remote.artists);
  if (localArtists.isEmpty || localArtists != remoteArtists) return null;

  final localIsrc = _normalizeIsrc(local.isrc);
  final remoteIsrc = _normalizeIsrc(remote.isrc);
  if (localIsrc != null && remoteIsrc != null && localIsrc != remoteIsrc) {
    return null;
  }
  final isrcMatched = localIsrc != null && localIsrc == remoteIsrc;

  final localDuration = local.duration.inMilliseconds;
  final remoteDuration = remote.duration.inMilliseconds;
  final hasDurations = localDuration > 0 && remoteDuration > 0;
  final durationDelta =
      hasDurations ? (localDuration - remoteDuration).abs() : 0;
  if (!isrcMatched && hasDurations && durationDelta > 2000) return null;

  var score = isrcMatched ? 100 : 20;
  if (hasDurations) score += 5 - (durationDelta ~/ 500).clamp(0, 4);
  final localAlbum = normalizeLocalMetadata(local.album ?? '');
  final remoteAlbum = normalizeLocalMetadata(remote.album ?? '');
  if (localAlbum.isNotEmpty && localAlbum == remoteAlbum) score += 4;

  return _TrackMatch(
    track: remote,
    score: score,
    isrcMatched: isrcMatched,
  );
}

List<ProviderRegistryEntry> _orderedProviders(
  Iterable<ProviderRegistryEntry> entries,
) {
  const preferred = ['netease_cloud_music', 'qq_music', 'kugou'];
  final eligible = {
    for (final entry in entries)
      if (entry.isEnabled &&
          entry.descriptor.id != localMusicProviderId &&
          entry.descriptor.supports(ProviderCapability.search) &&
          entry.descriptor.supports(ProviderCapability.lyrics))
        entry.descriptor.id.value: entry,
  };
  return [
    for (final id in preferred)
      if (eligible[id] case final entry?) entry,
  ];
}

String _artistIdentity(Iterable<String> artists) {
  final normalized = artists
      .map(normalizeLocalMetadata)
      .where((value) => value.isNotEmpty)
      .toSet()
      .toList(growable: false)
    ..sort();
  return normalized.join('|');
}

String? _normalizeIsrc(String? value) {
  final normalized =
      value?.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase().trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
