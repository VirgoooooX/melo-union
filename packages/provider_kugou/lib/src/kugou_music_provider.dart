import 'package:http/http.dart' as http;
import 'package:provider_contract/provider_contract.dart';

import 'auth/kugou_auth_service.dart';
import 'auth/kugou_qr_login_service.dart';
import 'auth/kugou_qr_login_service_impl.dart';
import 'auth/kugou_secure_session_store.dart';
import 'auth/kugou_session.dart';
import 'auth/kugou_session_manager.dart';
import 'kugou_descriptor.dart';
import 'api/kugou_api_client.dart';
import 'api/kugou_account_api.dart';
import 'api/kugou_library_api.dart';
import 'api/kugou_catalog_api.dart';
import 'api/kugou_media_api.dart';
import 'api/kugou_lyrics_api.dart';
import 'mapper/kugou_track_mapper.dart';
import 'mapper/kugou_playlist_mapper.dart';
import 'mapper/kugou_profile_mapper.dart';
import 'model/kugou_media_resolution.dart';
import 'model/kugou_remote_track.dart';

final class KugouMusicProvider implements MusicProvider {
  KugouMusicProvider({
    required KugouAuthService authService,
    required KugouAccountApi accountApi,
    required KugouLibraryApi libraryApi,
    required KugouCatalogApi catalogApi,
    required KugouMediaResolver mediaResolver,
    required KugouLyricsApi lyricsApi,
  })  : _authService = authService,
        _accountApi = accountApi,
        _libraryApi = libraryApi,
        _catalogApi = catalogApi,
        _mediaResolver = mediaResolver,
        _lyricsApi = lyricsApi,
        _trackMapper = KugouTrackMapper(providerId: kugouProviderId),
        _playlistMapper = KugouPlaylistMapper(providerId: kugouProviderId),
        _profileMapper = KugouProfileMapper();

  factory KugouMusicProvider.create({
    required KugouSecureSessionStore secureStore,
    KugouSession? initialSession,
    http.Client? httpClient,
  }) {
    final sessionManager = KugouSessionManager(
      secureStore: secureStore,
      initialSession: initialSession,
    );
    final apiClient = KugouApiClient(
      client: httpClient,
      sessionManager: sessionManager,
    );
    final authService = KugouAuthService(
      sessionManager: sessionManager,
      qrLoginService: KugouQrLoginServiceImpl(apiClient: apiClient),
      apiClient: apiClient,
    );
    final accountApi = KugouAccountApi(
      sessionManager: sessionManager,
      client: apiClient,
      providerId: kugouProviderId,
    );
    final libraryApi = KugouLibraryApi(
      client: apiClient,
      providerId: kugouProviderId,
    );
    final catalogApi = KugouCatalogApi(
      client: apiClient,
    );
    final mediaResolver = KugouMediaApi(
      client: apiClient,
      providerId: kugouProviderId,
    );
    final lyricsApi = KugouLyricsApi(
      client: apiClient,
    );

    return KugouMusicProvider(
      authService: authService,
      accountApi: accountApi,
      libraryApi: libraryApi,
      catalogApi: catalogApi,
      mediaResolver: mediaResolver,
      lyricsApi: lyricsApi,
    );
  }

  final KugouAuthService _authService;
  final KugouAccountApi _accountApi;
  final KugouLibraryApi _libraryApi;
  final KugouCatalogApi _catalogApi;
  final KugouMediaResolver _mediaResolver;
  final KugouLyricsApi _lyricsApi;

  final KugouTrackMapper _trackMapper;
  final KugouPlaylistMapper _playlistMapper;
  final KugouProfileMapper _profileMapper;

  @override
  ProviderDescriptor get descriptor => kugouDescriptor;

  @override
  bool get isAuthenticated => _authService.isAuthenticatedSync;

  // Let's expose createQrLoginSession and checkQrLoginSession on the provider directly
  // so the repository can delegate UI actions.
  Future<KugouQrLoginSession> createQrLoginSession() =>
      _authService.createQrLoginSession();

  Future<KugouQrLoginResult> checkQrLoginSession(KugouQrLoginSession session) =>
      _authService.checkQrLoginSession(session);

  Future<void> logout() => _authService.logout();

  @override
  Future<ProviderAccountProfile?> getProfile() async {
    final session = await _authService.currentSession;
    if (session == null) return null;
    final details = await _accountApi.getProfileDetails();
    return _profileMapper.map(
      session,
      displayName: details.displayName,
      avatarUrl: details.avatarUrl,
    );
  }

  @override
  Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false}) async {
    _requireCapability(ProviderCapability.readFavorites);
    _requireAuthenticated();
    if (forceRefresh) {
      _libraryApi.invalidateCollectionId();
    }

    String? partialFailureReason;
    final tracks = <SourceTrack>[];

    String? playlistId;
    try {
      playlistId ??= await _libraryApi.getOrResolveFavoriteCollectionId();

      // Page through favorite collection
      var page = 1;
      const pageSize = 100;
      while (true) {
        final pageTracks = await _libraryApi.getPlaylistTracks(
          playlistId,
          page: page,
          pageSize: pageSize,
        );
        if (pageTracks.isEmpty) {
          break;
        }
        tracks.addAll(
            pageTracks.map((e) => _trackMapper.map(e, isFavorited: true)));
        if (pageTracks.length < pageSize) {
          break;
        }
        page++;
      }
    } catch (e) {
      if (tracks.isEmpty) {
        partialFailureReason = 'Kugou favorites are not available yet: $e';
      } else {
        partialFailureReason =
            'Failed to load remaining pages of favorites: $e';
      }
    }

    return FavoriteSnapshot(
      providerId: descriptor.id,
      tracks: tracks,
      partialFailureReason: partialFailureReason,
    );
  }

  @override
  Future<void> setFavorite({
    required ProviderTrackRef track,
    required bool liked,
  }) async {
    _requireCapability(ProviderCapability.writeFavorites);
    _requireAuthenticated();
    if (track.providerId != descriptor.id) {
      throw ProviderException(
        providerId: descriptor.id,
        message:
            'Track provider ${track.providerId} does not match ${descriptor.id}.',
      );
    }

    final hash = track.trackId;
    final albumId = track.extraIds['albumId'];
    final mixSongId = track.extraIds['mixSongId'];
    final playlistId = await _libraryApi.getOrResolveFavoriteCollectionId();

    if (liked) {
      await _libraryApi.addTrackToPlaylist(
        playlistId,
        hash,
        albumId: albumId,
        mixSongId: mixSongId,
      );
      final verified =
          await _verifyTrackInFavorites(playlistId, hash, exists: true);
      if (!verified) {
        throw ProviderException(
          providerId: descriptor.id,
          message:
              'Favorite synchronization validation failed. Track not found in remote favorites after add.',
        );
      }
    } else {
      final favoriteFileId = track.extraIds['favoriteFileId'] ??
          await _resolveFavoriteFileId(playlistId, hash);
      await _libraryApi.removeTrackFromPlaylist(playlistId, hash,
          favoriteFileId: favoriteFileId);
      final verified =
          await _verifyTrackInFavorites(playlistId, hash, exists: false);
      if (!verified) {
        throw ProviderException(
          providerId: descriptor.id,
          message:
              'Favorite synchronization validation failed. Track still exists in remote favorites after remove.',
        );
      }
    }
  }

  Future<String> _resolveFavoriteFileId(String playlistId, String hash) async {
    final remoteTrack = await _findTrackInFavorites(playlistId, hash);
    final favoriteFileId = remoteTrack?.favoriteFileId;
    if (favoriteFileId == null || favoriteFileId.isEmpty) {
      throw ProviderException(
        providerId: descriptor.id,
        message: 'Cannot remove Kugou favorite without a favorite file id.',
      );
    }
    return favoriteFileId;
  }

  Future<bool> _verifyTrackInFavorites(String playlistId, String hash,
      {required bool exists}) async {
    for (var i = 0; i < 3; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      final found = await _findTrackInFavorites(playlistId, hash) != null;
      if (found == exists) {
        return true;
      }
    }
    return false;
  }

  Future<KugouRemoteTrack?> _findTrackInFavorites(
      String playlistId, String hash) async {
    var page = 1;
    const pageSize = 100;
    while (true) {
      final tracks = await _libraryApi.getPlaylistTracks(
        playlistId,
        page: page,
        pageSize: pageSize,
      );
      for (final track in tracks) {
        if (track.hash.toLowerCase() == hash.toLowerCase()) {
          return track;
        }
      }
      if (tracks.length < pageSize) {
        return null;
      }
      page++;
    }
  }

  @override
  Future<List<SourceTrack>> search(String query) async {
    _requireCapability(ProviderCapability.search);
    final results = await _catalogApi.search(query);
    return results.map((e) => _trackMapper.map(e, isFavorited: false)).toList();
  }

  @override
  Future<List<SourceTrack>> getDailyRecommendations() async {
    _requireCapability(ProviderCapability.readDailyRecommendations);
    final results = await _catalogApi.getDailyRecommendations();
    return results.map((e) => _trackMapper.map(e, isFavorited: false)).toList();
  }

  @override
  Future<List<ProviderPlaylist>> getRecommendedPlaylists(
      {int limit = 12}) async {
    _requireCapability(ProviderCapability.readDailyRecommendations);
    final results = await _catalogApi.getRecommendedPlaylists(limit: limit);
    return results.map((e) => _playlistMapper.map(e)).toList();
  }

  @override
  Future<List<ProviderPlaylist>> getChartPlaylists({int limit = 20}) async {
    _requireCapability(ProviderCapability.readCharts);
    final results = await _catalogApi.getChartPlaylists(limit: limit);
    return results.map((e) => _playlistMapper.map(e)).toList();
  }

  @override
  Future<List<ProviderPlaylist>> getUserPlaylists() async {
    _requireCapability(ProviderCapability.readUserPlaylists);
    _requireAuthenticated();

    final results = await _libraryApi.getUserPlaylists();
    final privatePlaylists = results
        .where((e) => !e.isFavoriteCollection)
        .map((e) => _playlistMapper.map(e))
        .toList();
    return privatePlaylists;
  }

  @override
  Future<List<SourceTrack>> getPlaylistTracks(String playlistId) async {
    final normalizedId = playlistId.trim();
    if (normalizedId.startsWith('rank:')) {
      _requireCapability(ProviderCapability.readCharts);
      final results =
          await _catalogApi.getChartTracks(normalizedId.substring(5));
      return results
          .map((e) => _trackMapper.map(e, isFavorited: false))
          .toList();
    }
    if (normalizedId.startsWith('plist:')) {
      _requireCapability(ProviderCapability.readDailyRecommendations);
      final results = await _catalogApi
          .getRecommendedPlaylistTracks(normalizedId.substring(6));
      return results
          .map((e) => _trackMapper.map(e, isFavorited: false))
          .toList();
    }

    _requireCapability(ProviderCapability.readUserPlaylists);
    final results = await _libraryApi.getPlaylistTracks(normalizedId);
    return results.map((e) => _trackMapper.map(e, isFavorited: false)).toList();
  }

  @override
  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _requireCapability(ProviderCapability.resolvePlayback);
    final resolution = await _mediaResolver.resolve(
      track: track,
      requestedQuality: quality,
      use: KugouMediaUse.playback,
    );

    return PlaybackTicket(
      mediaUri: resolution.url,
      headers: resolution.headers,
      expiresAt: resolution.expiresAt,
      trackRef: track,
      quality: resolution.quality,
    );
  }

  @override
  Future<DownloadTicket> createDownloadTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  }) async {
    _requireCapability(ProviderCapability.resolveDownload);
    final resolution = await _mediaResolver.resolve(
      track: track,
      requestedQuality: quality,
      use: KugouMediaUse.download,
    );

    return DownloadTicket(
      mediaUri: resolution.url,
      headers: resolution.headers,
      expiresAt: resolution.expiresAt,
      trackRef: track,
      quality: resolution.quality,
      bytes: resolution.fileSize,
      fileExtension: resolution.format,
    );
  }

  @override
  Future<String?> getLyrics(ProviderTrackRef track) {
    _requireCapability(ProviderCapability.lyrics);
    return _lyricsApi.getLyrics(track);
  }

  void _requireAuthenticated() {
    if (!isAuthenticated) {
      throw AuthenticationRequiredException(
        providerId: descriptor.id,
        message: '酷狗音乐账号未登录。',
      );
    }
  }

  void _requireCapability(ProviderCapability capability) {
    if (!descriptor.supports(capability)) {
      _unsupported(capability);
    }
  }

  Never _unsupported(ProviderCapability capability) {
    throw CapabilityUnavailableException(
      providerId: descriptor.id,
      capability: capability,
      message: 'Kugou Music ${capability.name} is not available yet.',
    );
  }
}
