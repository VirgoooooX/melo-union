import 'package:provider_contract/provider_contract.dart';

final class FakeMusicProvider implements MusicProvider {
  FakeMusicProvider({
    required this.descriptor,
    required List<SourceTrack> seedTracks,
    this.isAuthenticated = true,
  }) : _tracks = {for (final track in seedTracks) track.ref.trackId: track};

  @override
  final ProviderDescriptor descriptor;

  @override
  bool isAuthenticated;

  final Map<String, SourceTrack> _tracks;

  @override
  Future<ProviderAccountProfile?> getProfile() async => null;

  @override
  Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false}) async {
    if (!descriptor.supports(ProviderCapability.readFavorites)) {
      throw CapabilityUnavailableException(
        providerId: descriptor.id,
        capability: ProviderCapability.readFavorites,
        message: 'readFavorites unavailable',
      );
    }
    if (descriptor.supports(ProviderCapability.authenticate) &&
        !isAuthenticated) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: 'login required',
      );
    }
    return FavoriteSnapshot(
      providerId: descriptor.id,
      tracks: _tracks.values.where((track) => track.isFavorited).toList(),
    );
  }

  @override
  Future<List<SourceTrack>> search(String query) async {
    if (!descriptor.supports(ProviderCapability.search)) {
      throw CapabilityUnavailableException(
        providerId: descriptor.id,
        capability: ProviderCapability.search,
        message: 'search unavailable',
      );
    }
    final normalized = query.toLowerCase();
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
    final existing = _tracks[track.trackId];
    if (existing == null) {
      throw ProviderTrackNotFoundException(
        providerId: descriptor.id,
        track: track,
        message: 'unknown track',
      );
    }
    _tracks[track.trackId] = existing.copyWith(isFavorited: liked);
  }

  @override
  Future<List<SourceTrack>> getDailyRecommendations() async {
    if (!descriptor.supports(ProviderCapability.readDailyRecommendations)) {
      throw CapabilityUnavailableException(
        providerId: descriptor.id,
        capability: ProviderCapability.readDailyRecommendations,
        message: 'daily recommendations unavailable',
      );
    }
    return _tracks.values.toList();
  }

  @override
  Future<List<ProviderPlaylist>> getRecommendedPlaylists({
    int limit = 12,
  }) async {
    if (!descriptor.supports(ProviderCapability.readDailyRecommendations)) {
      throw CapabilityUnavailableException(
        providerId: descriptor.id,
        capability: ProviderCapability.readDailyRecommendations,
        message: 'recommended playlists unavailable',
      );
    }
    return [
      ProviderPlaylist(
        providerId: descriptor.id,
        playlistId: '${descriptor.id.value}_recommended',
        name: '${descriptor.displayName} Recommended',
        trackCount: _tracks.length,
        playCount: _tracks.length * 10000,
      ),
    ];
  }

  @override
  Future<List<ProviderPlaylist>> getChartPlaylists({
    int limit = 20,
  }) async {
    if (!descriptor.supports(ProviderCapability.readCharts)) {
      throw CapabilityUnavailableException(
        providerId: descriptor.id,
        capability: ProviderCapability.readCharts,
        message: 'charts unavailable',
      );
    }
    return [
      ProviderPlaylist(
        providerId: descriptor.id,
        playlistId: '${descriptor.id.value}_chart',
        name: '${descriptor.displayName} Chart',
        trackCount: _tracks.length,
        playCount: _tracks.length * 20000,
      ),
    ].take(limit).toList(growable: false);
  }

  @override
  Future<List<ProviderPlaylist>> getUserPlaylists() async {
    if (!descriptor.supports(ProviderCapability.readUserPlaylists)) {
      throw CapabilityUnavailableException(
        providerId: descriptor.id,
        capability: ProviderCapability.readUserPlaylists,
        message: 'user playlists unavailable',
      );
    }
    return [
      ProviderPlaylist(
        providerId: descriptor.id,
        playlistId: '${descriptor.id.value}_playlist',
        name: '${descriptor.displayName} Playlist',
        trackCount: _tracks.length,
      ),
    ];
  }

  @override
  Future<List<SourceTrack>> getPlaylistTracks(String playlistId) async {
    if (!descriptor.supports(ProviderCapability.readUserPlaylists)) {
      throw CapabilityUnavailableException(
        providerId: descriptor.id,
        capability: ProviderCapability.readUserPlaylists,
        message: 'user playlists unavailable',
      );
    }
    return _tracks.values.toList();
  }

  @override
  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    if (!descriptor.supports(ProviderCapability.resolvePlayback)) {
      throw CapabilityUnavailableException(
        providerId: descriptor.id,
        capability: ProviderCapability.resolvePlayback,
        message: 'playback unavailable',
      );
    }
    final existing = _tracks[track.trackId];
    if (existing == null) {
      throw ProviderTrackNotFoundException(
        providerId: descriptor.id,
        track: track,
        message: 'unknown track',
      );
    }
    return PlaybackTicket(
      mediaUri: Uri.parse(
          'provider://${descriptor.id.value}/playback/${track.trackId}'),
      headers: const {},
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
    if (!descriptor.supports(ProviderCapability.resolveDownload)) {
      throw CapabilityUnavailableException(
        providerId: descriptor.id,
        capability: ProviderCapability.resolveDownload,
        message: 'download unavailable',
      );
    }
    final existing = _tracks[track.trackId];
    if (existing == null) {
      throw ProviderTrackNotFoundException(
        providerId: descriptor.id,
        track: track,
        message: 'unknown track',
      );
    }
    return DownloadTicket(
      mediaUri: Uri.parse(
          'provider://${descriptor.id.value}/download/${track.trackId}'),
      headers: const {},
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      trackRef: track,
      quality: quality,
    );
  }

  @override
  Future<String?> getLyrics(ProviderTrackRef track) async {
    return '[00:00.00] lyrics';
  }
}
