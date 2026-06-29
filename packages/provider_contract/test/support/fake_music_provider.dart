import 'package:provider_contract/provider_contract.dart';

enum FakeProviderKind { fullAccount, readOnlyAccount, catalogSupplemental }

final class FakeMusicProvider implements MusicProvider {
  FakeMusicProvider({
    required this.descriptor,
    required this.kind,
    required List<SourceTrack> seedTracks,
    this.isAuthenticated = true,
    this.profile,
  }) : _tracks = {for (final track in seedTracks) track.ref.trackId: track};

  @override
  final ProviderDescriptor descriptor;

  final FakeProviderKind kind;
  @override
  bool isAuthenticated;
  final ProviderAccountProfile? profile;
  final Map<String, SourceTrack> _tracks;

  @override
  Future<ProviderAccountProfile?> getProfile() async {
    if (!descriptor.supports(ProviderCapability.authenticate)) {
      return null;
    }
    if (!isAuthenticated) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: '${descriptor.displayName} requires login.',
      );
    }
    return profile;
  }

  @override
  Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false}) async {
    _requireCapability(ProviderCapability.readFavorites);
    _requireAuthenticatedIfNeeded();
    return FavoriteSnapshot(
      providerId: descriptor.id,
      tracks: _tracks.values.where((track) => track.isFavorited).toList(),
    );
  }

  @override
  Future<List<SourceTrack>> search(String query) async {
    _requireCapability(ProviderCapability.search);
    final normalized = query.trim().toLowerCase();
    return _tracks.values
        .where(
          (track) =>
              track.title.toLowerCase().contains(normalized) ||
              track.artists.any(
                (artist) => artist.toLowerCase().contains(normalized),
              ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> setFavorite({
    required ProviderTrackRef track,
    required bool liked,
  }) async {
    _requireCapability(ProviderCapability.writeFavorites);
    _requireAuthenticatedIfNeeded();

    final existing = _tracks[track.trackId];
    if (existing == null) {
      throw ProviderTrackNotFoundException(
        providerId: descriptor.id,
        track: track,
        message: 'Track ${track.trackId} is unknown.',
      );
    }
    _tracks[track.trackId] = existing.copyWith(isFavorited: liked);
  }

  @override
  Future<List<SourceTrack>> getDailyRecommendations() async {
    _requireCapability(ProviderCapability.readDailyRecommendations);
    _requireAuthenticatedIfNeeded();
    return _tracks.values.toList();
  }

  @override
  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _requireCapability(ProviderCapability.resolvePlayback);
    _requireAuthenticatedIfNeeded();
    final existing = _tracks[track.trackId];
    if (existing == null) {
      throw ProviderTrackNotFoundException(
        providerId: descriptor.id,
        track: track,
        message: 'Track ${track.trackId} is unknown.',
      );
    }
    return PlaybackTicket(
      mediaUri: Uri.parse(
          'provider://${descriptor.id.value}/playback/${track.trackId}'),
      headers: const {'X-Fake-Header': 'Playback'},
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      trackRef: track,
      quality: quality,
    );
  }

  @override
  Future<DownloadTicket> createDownloadTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _requireCapability(ProviderCapability.resolveDownload);
    _requireAuthenticatedIfNeeded();
    final existing = _tracks[track.trackId];
    if (existing == null) {
      throw ProviderTrackNotFoundException(
        providerId: descriptor.id,
        track: track,
        message: 'Track ${track.trackId} is unknown.',
      );
    }
    return DownloadTicket(
      mediaUri: Uri.parse(
          'provider://${descriptor.id.value}/download/${track.trackId}'),
      headers: const {'X-Fake-Header': 'Download'},
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      trackRef: track,
      quality: quality,
      fileExtension: 'mp3',
      bytes: 1024 * 1024 * 5,
    );
  }

  @override
  Future<String?> getLyrics(ProviderTrackRef track) async {
    _requireCapability(ProviderCapability.lyrics);
    _requireAuthenticatedIfNeeded();
    final existing = _tracks[track.trackId];
    if (existing == null) {
      throw ProviderTrackNotFoundException(
        providerId: descriptor.id,
        track: track,
        message: 'Track ${track.trackId} is unknown.',
      );
    }
    return '[00:00.00] Fake lyrics for ${existing.title}';
  }

  void _requireCapability(ProviderCapability capability) {
    if (!descriptor.supports(capability)) {
      throw CapabilityUnavailableException(
        providerId: descriptor.id,
        capability: capability,
        message:
            '${descriptor.displayName} does not support ${capability.name}.',
      );
    }
  }

  void _requireAuthenticatedIfNeeded() {
    if (descriptor.supports(ProviderCapability.authenticate) &&
        !isAuthenticated) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: '${descriptor.displayName} requires login.',
      );
    }
  }
}
