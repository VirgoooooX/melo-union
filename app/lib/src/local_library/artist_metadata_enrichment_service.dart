import 'dart:async';
import 'dart:io';

import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import 'artist_metadata_image_cache.dart';

final class ArtistMetadataEnrichmentService {
  ArtistMetadataEnrichmentService({
    required this.repository,
    required Iterable<ProviderRegistryEntry> providerEntries,
    required this.imageCache,
    this.requestGap = const Duration(milliseconds: 500),
    this.onMetadataUpdated,
    DateTime Function()? clock,
  })  : _providers = _orderedProviders(providerEntries),
        _clock = clock ?? (() => DateTime.now().toUtc());

  final LocalLibraryRepository repository;
  final ArtistMetadataImageCache imageCache;
  final List<_MetadataSource> _providers;
  final Duration requestGap;
  final DateTime Function() _clock;
  final FutureOr<void> Function(String artistKey)? onMetadataUpdated;
  final List<LocalLibraryArtist> _queue = [];
  final Set<String> _queuedKeys = {};
  bool _running = false;
  bool enabled = true;

  bool get isRunning => _running;

  void enqueue(Iterable<LocalLibraryArtist> artists, {bool force = false}) {
    if (!enabled && !force) return;
    for (final artist in artists) {
      if (_queuedKeys.add(artist.artistKey)) _queue.add(artist);
    }
    if (!_running) unawaited(_drain(force: force));
  }

  Future<void> enrichNow(LocalLibraryArtist artist) async {
    _queuedKeys.remove(artist.artistKey);
    await _enrich(artist, force: true);
  }

  Future<void> forceCollage(LocalLibraryArtist artist) =>
      repository.upsertArtistMetadata(LocalArtistMetadata(
        artistKey: artist.artistKey,
        displayName: artist.displayName,
        status: ArtistMetadataStatus.forcedCollage,
        userConfirmed: true,
        fetchedAt: _clock(),
      ));

  Future<void> clearMetadata(LocalLibraryArtist artist) =>
      repository.upsertArtistMetadata(LocalArtistMetadata(
        artistKey: artist.artistKey,
        displayName: artist.displayName,
        status: ArtistMetadataStatus.pending,
      ));

  Future<void> clearImageCache() => imageCache.clear();

  Future<void> _drain({required bool force}) async {
    _running = true;
    try {
      while (_queue.isNotEmpty && (enabled || force)) {
        final artist = _queue.removeAt(0);
        _queuedKeys.remove(artist.artistKey);
        await _enrich(artist, force: force);
      }
    } finally {
      _running = false;
    }
  }

  Future<void> _enrich(LocalLibraryArtist artist, {required bool force}) async {
    final existing = await repository.getArtistMetadata(artist.artistKey);
    if (!force && !_shouldRefresh(existing)) return;
    final tracks = await repository.listArtistTracks(artist.artistKey);
    final samples = tracks
        .where((track) => track.title.trim().isNotEmpty)
        .take(3)
        .map((track) => ArtistMatchTrack(
              title: track.title,
              album: track.album,
              duration: track.duration,
            ))
        .toList(growable: false);

    for (final source in _providers) {
      try {
        final candidates = await source.provider.searchArtistMetadata(
          artistName: artist.displayName,
          samples: samples,
        );
        await Future<void>.delayed(requestGap);
        final match = _highConfidence(artist.displayName, candidates);
        if (match == null) continue;
        final details =
            await source.provider.getArtistMetadata(match.artist.artistId);
        await Future<void>.delayed(requestGap);
        final resolved = details ??
            ProviderArtistMetadata(
              artist: match.artist,
              aliases: match.aliases,
              avatar: match.avatar,
              background: match.background,
              description: match.description,
            );
        final avatarPath =
            await imageCache.cache(resolved.avatar, resolved.artist, 'avatar');
        final backgroundPath = await imageCache.cache(
            resolved.background, resolved.artist, 'background');
        await repository.upsertArtistMetadata(LocalArtistMetadata(
          artistKey: artist.artistKey,
          displayName: artist.displayName,
          status: ArtistMetadataStatus.matched,
          sourceProviderId: resolved.artist.providerId,
          remoteArtistId: resolved.artist.artistId,
          remoteName: resolved.artist.name,
          avatarUrl: resolved.avatar?.toString(),
          avatarCachePath: avatarPath ?? existing?.avatarCachePath,
          backgroundUrl: resolved.background?.toString(),
          backgroundCachePath: backgroundPath ?? existing?.backgroundCachePath,
          description: resolved.description,
          confidence: match.providerScore,
          fetchedAt: _clock(),
        ));
        await onMetadataUpdated?.call(artist.artistKey);
        return;
      } on ProviderException catch (error) {
        if (error.toString().contains('429') ||
            error.toString().contains('503')) {
          await repository.upsertArtistMetadata(LocalArtistMetadata(
            artistKey: artist.artistKey,
            displayName: artist.displayName,
            status: ArtistMetadataStatus.failed,
            fetchedAt: _clock(),
            retryAfter: _clock().add(const Duration(hours: 1)),
          ));
          return;
        }
      } on SocketException {
        return;
      } catch (_) {
        // A provider failure falls through to the next configured source.
      }
    }
    await repository.upsertArtistMetadata(LocalArtistMetadata(
      artistKey: artist.artistKey,
      displayName: artist.displayName,
      status: ArtistMetadataStatus.noMatch,
      fetchedAt: _clock(),
      retryAfter: _clock().add(const Duration(days: 7)),
    ));
    await onMetadataUpdated?.call(artist.artistKey);
  }

  bool _shouldRefresh(LocalArtistMetadata? metadata) {
    if (metadata == null || metadata.status == ArtistMetadataStatus.pending) {
      return true;
    }
    if (metadata.userConfirmed ||
        metadata.status == ArtistMetadataStatus.forcedCollage) {
      return false;
    }
    final now = _clock();
    if (metadata.retryAfter?.isAfter(now) ?? false) {
      return false;
    }
    final fetchedAt = metadata.fetchedAt;
    return fetchedAt == null ||
        now.difference(fetchedAt) >= const Duration(days: 30);
  }
}

final class _MetadataSource {
  const _MetadataSource(this.id, this.provider);
  final String id;
  final ArtistMetadataProvider provider;
}

List<_MetadataSource> _orderedProviders(
    Iterable<ProviderRegistryEntry> entries) {
  final sources = <_MetadataSource>[];
  for (final id in const ['netease_cloud_music', 'qq_music']) {
    for (final entry in entries) {
      if (!entry.isEnabled || entry.descriptor.id.value != id) continue;
      final provider = entry.provider;
      if (provider is ArtistMetadataProvider) {
        sources.add(_MetadataSource(id, provider as ArtistMetadataProvider));
      }
    }
  }
  return sources;
}

ProviderArtistCandidate? _highConfidence(
  String localName,
  List<ProviderArtistCandidate> candidates,
) {
  final normalized = _normalize(localName);
  final matching = candidates
      .where((candidate) => _normalize(candidate.artist.name) == normalized)
      .where((candidate) => candidate.providerScore >= .8)
      .toList(growable: false)
    ..sort((a, b) => b.providerScore.compareTo(a.providerScore));
  if (matching.isEmpty) {
    return null;
  }
  if (matching.length > 1 &&
      matching[0].providerScore == matching[1].providerScore) {
    return null;
  }
  return matching.first;
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[\s\p{P}]+', unicode: true), '');
