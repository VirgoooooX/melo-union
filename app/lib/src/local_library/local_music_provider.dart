import 'dart:io';

import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

final class LocalMusicProvider implements MusicProvider {
  LocalMusicProvider(this.repository);

  final LocalLibraryRepository repository;

  @override
  ProviderDescriptor get descriptor => ProviderDescriptor(
        id: localMusicProviderId,
        displayName: '本地',
        capabilities: const {
          ProviderCapability.readFavorites,
          ProviderCapability.writeFavorites,
          ProviderCapability.search,
          ProviderCapability.resolvePlayback,
          ProviderCapability.lyrics,
          ProviderCapability.artwork,
        },
        shortDescription: 'Windows 本地曲库',
      );

  @override
  bool get isAuthenticated => true;

  @override
  Future<ProviderAccountProfile?> getProfile() async => null;

  @override
  Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false}) async {
    final tracks = await repository.listTracks(limit: 100000);
    return FavoriteSnapshot(
      providerId: localMusicProviderId,
      tracks: [
        for (final track in tracks)
          if (track.isFavorited) track.toSourceTrack(),
      ],
    );
  }

  @override
  Future<void> setFavorite({
    required ProviderTrackRef track,
    required bool liked,
  }) async {
    _ensureLocal(track);
    await repository.setFavorite(track.trackId, liked);
  }

  @override
  Future<List<SourceTrack>> search(String query) async =>
      (await repository.listTracks(query: query, limit: 500))
          .map((track) => track.toSourceTrack())
          .toList(growable: false);

  @override
  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _ensureLocal(track);
    final local = await repository.getTrack(track.trackId);
    if (local == null || !local.isAvailable) {
      throw ProviderTrackNotFoundException(
        providerId: localMusicProviderId,
        track: track,
        message: '本地文件不存在或当前磁盘不可用。',
      );
    }
    final file = File(local.filePath);
    final exists = await file.exists();
    final length = exists ? await file.length() : -1;
    final uri = Uri.file(local.filePath);
    if (!exists || length <= 0) {
      throw ProviderTrackNotFoundException(
        providerId: localMusicProviderId,
        track: track,
        message: '本地文件不存在或当前磁盘不可用，请重扫曲库。',
      );
    }
    return PlaybackTicket(
      mediaUri: uri,
      headers: const {},
      expiresAt: DateTime.utc(9999),
      trackRef: track,
      quality: AudioQuality.lossless,
    );
  }

  @override
  Future<String?> getLyrics(ProviderTrackRef track) async {
    _ensureLocal(track);
    return (await repository.getTrack(track.trackId))?.lyrics;
  }

  @override
  Future<List<SourceTrack>> getDailyRecommendations() async => const [];

  @override
  Future<List<ProviderPlaylist>> getRecommendedPlaylists(
          {int limit = 12}) async =>
      const [];

  @override
  Future<List<ProviderPlaylist>> getChartPlaylists({int limit = 20}) async =>
      const [];

  @override
  Future<List<ProviderPlaylist>> getUserPlaylists() async => const [];

  @override
  Future<List<SourceTrack>> getPlaylistTracks(String playlistId) async =>
      const [];

  @override
  Future<DownloadTicket> createDownloadTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) {
    throw CapabilityUnavailableException(
      providerId: localMusicProviderId,
      capability: ProviderCapability.resolveDownload,
      message: '本地歌曲无需下载。',
    );
  }

  void _ensureLocal(ProviderTrackRef track) {
    if (track.providerId != localMusicProviderId) {
      throw ProviderTrackNotFoundException(
        providerId: localMusicProviderId,
        track: track,
        message: '歌曲不属于本地曲库。',
      );
    }
  }
}
