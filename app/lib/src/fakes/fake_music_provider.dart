import 'package:provider_contract/provider_contract.dart';

final class FakeMusicProvider implements MusicProvider {
  FakeMusicProvider({
    required this.descriptor,
    required List<SourceTrack> seedTracks,
    required this.profile,
    this.isAuthenticated = true,
  }) : _tracks = {for (final track in seedTracks) track.ref.trackId: track};

  @override
  final ProviderDescriptor descriptor;

  final ProviderAccountProfile? profile;
  final Map<String, SourceTrack> _tracks;

  @override
  bool isAuthenticated;

  List<SourceTrack> allTracks() =>
      List.unmodifiable(_tracks.values.toList(growable: false));

  SourceTrack? trackByRef(ProviderTrackRef ref) => _tracks[ref.trackId];

  void setAuthenticated(bool value) {
    isAuthenticated = value;
  }

  @override
  Future<ProviderAccountProfile?> getProfile() async {
    if (!descriptor.supports(ProviderCapability.authenticate)) {
      return null;
    }
    if (!isAuthenticated) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: '${descriptor.displayName} account is signed out.',
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
        message: 'Unknown fake track ${track.trackId}.',
      );
    }
    _tracks[track.trackId] = existing.copyWith(isFavorited: liked);
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
        message: '${descriptor.displayName} account is signed out.',
      );
    }
  }

  @override
  Future<List<SourceTrack>> getDailyRecommendations() async {
    _requireCapability(ProviderCapability.readDailyRecommendations);
    _requireAuthenticatedIfNeeded();
    return _tracks.values.toList();
  }

  @override
  Future<List<ProviderPlaylist>> getRecommendedPlaylists({
    int limit = 12,
  }) async {
    _requireCapability(ProviderCapability.readDailyRecommendations);
    _requireAuthenticatedIfNeeded();
    return [
      ProviderPlaylist(
        providerId: descriptor.id,
        playlistId: '${descriptor.id.value}_recommended',
        name: '${descriptor.displayName} 推荐歌单',
        creatorName: profile?.displayName,
        trackCount: _tracks.length,
        playCount: _tracks.length * 10000,
      ),
    ];
  }

  @override
  Future<List<ProviderPlaylist>> getChartPlaylists({
    int limit = 20,
  }) async {
    _requireCapability(ProviderCapability.readCharts);
    _requireAuthenticatedIfNeeded();
    return [
      ProviderPlaylist(
        providerId: descriptor.id,
        playlistId: '${descriptor.id.value}_chart',
        name: '${descriptor.displayName} 热门榜',
        creatorName: '榜单',
        trackCount: _tracks.length,
        playCount: _tracks.length * 20000,
      ),
    ].take(limit).toList(growable: false);
  }

  @override
  Future<List<ProviderPlaylist>> getUserPlaylists() async {
    _requireCapability(ProviderCapability.readUserPlaylists);
    _requireAuthenticatedIfNeeded();
    return [
      ProviderPlaylist(
        providerId: descriptor.id,
        playlistId: '${descriptor.id.value}_liked',
        name: '${descriptor.displayName} 喜欢的音乐',
        creatorName: profile?.displayName,
        trackCount: _tracks.length,
      ),
    ];
  }

  @override
  Future<List<SourceTrack>> getPlaylistTracks(String playlistId) async {
    _requireCapability(ProviderCapability.readUserPlaylists);
    _requireAuthenticatedIfNeeded();
    return _tracks.values.toList(growable: false);
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
        message: 'Unknown fake track ${track.trackId}.',
      );
    }
    return PlaybackTicket(
      mediaUri: Uri.parse(
          'provider://${descriptor.id.value}/playback/${track.trackId}'),
      headers: const {'X-App-Fake': 'Playback'},
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
        message: 'Unknown fake track ${track.trackId}.',
      );
    }
    return DownloadTicket(
      mediaUri: Uri.parse(
          'provider://${descriptor.id.value}/download/${track.trackId}'),
      headers: const {'X-App-Fake': 'Download'},
      expiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      trackRef: track,
      quality: quality,
      fileExtension: 'mp3',
      bytes: 1024 * 1024 * 6,
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
        message: 'Unknown fake track ${track.trackId}.',
      );
    }
    return '[00:00.00] Demo lyrics for ${existing.title}';
  }
}
