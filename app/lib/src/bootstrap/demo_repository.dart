import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:music_data/music_data.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:provider_netease/provider_netease.dart';

import '../fakes/fake_music_provider.dart';
import '../platform/playback_platform_bridge.dart';
import 'netease_session_store.dart';

final demoRepositoryProvider = ChangeNotifierProvider<DemoRepository>(
  (ref) => DemoRepository.seeded(),
);

final allFavoritesProvider = FutureProvider<List<UnifiedFavoriteTrack>>((ref) {
  final repository = ref.read(demoRepositoryProvider);
  return repository.loadAllFavorites();
});

class DemoRepository extends ChangeNotifier {
  DemoRepository._({
    required this.registry,
    required this.playlists,
    required this.providers,
    FavoritesOverrideRegistry? favoritesOverrideRegistry,
    List<DownloadTask> seedDownloadTasks = const [],
    List<LocalMediaItem> seedLocalMediaItems = const [],
    this.snapshotStore,
    NeteaseCredentials? neteaseCredentials,
    this.neteaseSessionStore,
    this.playbackBridge = const PlaybackPlatformBridge(),
  })  : favoritesOverrideRegistry =
            favoritesOverrideRegistry ?? FavoritesOverrideRegistry(),
        _neteaseCredentials = neteaseCredentials,
        _selectedPlaylistId = playlists.listPlaylists().isEmpty
            ? null
            : playlists.listPlaylists().first.id {
    playbackCoordinator = PlaybackCoordinator(registry: registry);
    downloadCoordinator = DownloadCoordinator(
      registry: registry,
      seedTasks: seedDownloadTasks,
      seedLocalItems: seedLocalMediaItems,
    );
    // Notify UI when audio player state changes (play/pause/complete)
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed ||
          state.processingState == ProcessingState.idle) {
        _playbackRequested = false;
      }
      notifyListeners();
    });
  }

  factory DemoRepository.seeded({
    MeloDataSnapshot? snapshot,
    MeloSnapshotStore? snapshotStore,
    NeteaseCredentials? neteaseCredentials,
    NeteaseSessionStore? neteaseSessionStore,
    List<MusicProvider> additionalProviders = const [],
  }) {
    final catalogId = ProviderId('compass_catalog');
    final netease = NeteaseMusicProvider(credentials: neteaseCredentials);

    final catalog = FakeMusicProvider(
      descriptor: ProviderDescriptor(
        id: catalogId,
        displayName: 'Compass Catalog',
        capabilities: const {
          ProviderCapability.search,
          ProviderCapability.artwork,
          ProviderCapability.lyrics,
        },
        status: ProviderStatus.experimental,
        shortDescription: 'Catalog and metadata supplement',
      ),
      profile: null,
      isAuthenticated: false,
      seedTracks: [
        SourceTrack(
          ref: ProviderTrackRef(
            providerId: catalogId,
            trackId: 'catalog_midnight',
            extraIds: const {'artwork_key': 'compass_401'},
          ),
          title: 'Midnight Signal',
          artists: const ['Luna Park'],
          album: 'Index Copy',
          duration: const Duration(minutes: 3, seconds: 10),
          isFavorited: false,
          isPlayable: false,
        ),
        SourceTrack(
          ref: ProviderTrackRef(
            providerId: catalogId,
            trackId: 'catalog_cover',
            extraIds: const {'artwork_key': 'compass_402'},
          ),
          title: 'Cover Sheet',
          artists: const ['Reference Artist'],
          album: 'Metadata Only',
          duration: const Duration(minutes: 2, seconds: 58),
          isFavorited: false,
          isPlayable: false,
        ),
        SourceTrack(
          ref: ProviderTrackRef(
            providerId: catalogId,
            trackId: 'catalog_cascade',
            extraIds: const {'artwork_key': 'compass_403'},
          ),
          title: 'Cascade Memory',
          artists: const ['Vector Hall'],
          album: 'Deep Index',
          duration: const Duration(minutes: 5, seconds: 3),
          isFavorited: false,
          isPlayable: false,
        ),
      ],
    );

    final registry = StaticProviderRegistry([
      ...additionalProviders,
      catalog,
      netease,
    ]);

    final defaultPlaylists = [
      LocalPlaylist(
        id: 'playlist_commute',
        name: 'Morning Commute',
        items: [
          for (final provider
              in additionalProviders.whereType<FakeMusicProvider>())
            if (provider.allTracks().isNotEmpty)
              LocalPlaylistItem(
                trackRef: provider.allTracks().first.ref,
                cachedTitle: provider.allTracks().first.title,
                cachedArtists: provider.allTracks().first.artists,
                cachedProviderName: provider.descriptor.displayName,
                addedAt: DateTime.utc(2026, 6, 28, 7, 30),
              ),
        ],
      ),
      LocalPlaylist(
        id: 'playlist_notes',
        name: 'Crossfade Notes',
        items: [
          LocalPlaylistItem(
            trackRef: catalog.allTracks()[1].ref,
            cachedTitle: 'Cover Sheet',
            cachedArtists: const ['Reference Artist'],
            cachedProviderName: 'Compass Catalog',
            addedAt: DateTime.utc(2026, 6, 28, 23, 12),
          ),
        ],
      ),
    ];
    final playlists = InMemoryLocalPlaylistRepository(
      seedPlaylists: snapshot?.playlists ?? defaultPlaylists,
    );

    final repo = DemoRepository._(
      registry: registry,
      playlists: playlists,
      providers: {
        for (final provider
            in additionalProviders.whereType<FakeMusicProvider>())
          provider.descriptor.id: provider,
        catalogId: catalog,
      },
      favoritesOverrideRegistry: snapshot?.favoritesOverrides,
      seedDownloadTasks: snapshot?.downloadTasks ?? const [],
      seedLocalMediaItems: snapshot?.localMediaItems ?? const [],
      snapshotStore: snapshotStore,
      neteaseCredentials: neteaseCredentials,
      neteaseSessionStore: neteaseSessionStore,
      playbackBridge: const PlaybackPlatformBridge(),
    );
    final allSeededTracks = [
      for (final provider in additionalProviders.whereType<FakeMusicProvider>())
        if (provider.allTracks().isNotEmpty) provider.allTracks().first,
    ];
    if (allSeededTracks.isNotEmpty) {
      repo.playbackCoordinator.setQueue(allSeededTracks);
    }
    return repo;
  }

  final StaticProviderRegistry registry;
  final InMemoryLocalPlaylistRepository playlists;
  final Map<ProviderId, FakeMusicProvider> providers;
  final MeloSnapshotStore? snapshotStore;
  final NeteaseSessionStore? neteaseSessionStore;
  final PlaybackPlatformBridge playbackBridge;
  final ProviderCapabilityMatrix capabilityMatrix =
      const ProviderCapabilityMatrix();
  final UnifiedFavoritesService favoritesService =
      const UnifiedFavoritesService();
  final CapabilityAwareSearchService searchService =
      const CapabilityAwareSearchService();

  late final PlaybackCoordinator playbackCoordinator;
  late final DownloadCoordinator downloadCoordinator;
  final FavoritesOverrideRegistry favoritesOverrideRegistry;
  NeteaseCredentials? _neteaseCredentials;
  String? _selectedPlaylistId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingTrackId;
  bool _playbackRequested = false;

  PlaybackQueueState get queue => playbackCoordinator.queueState;

  bool get isPlaying => _audioPlayer.playing;

  bool get isPlaybackActive => _audioPlayer.playing || _playbackRequested;

  AudioPlayer get audioPlayer => _audioPlayer;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  double get volume => _audioPlayer.volume;

  AudioQuality get playbackQuality => playbackCoordinator.quality;

  List<ProviderRegistryEntry> get providerEntries => registry.allEntries();

  bool get hasNeteaseSession => _neteaseCredentials?.hasCookie ?? false;

  List<LocalPlaylist> get playlistList => playlists.listPlaylists();

  String? get selectedPlaylistId =>
      _selectedPlaylistId ??
      (playlistList.isEmpty ? null : playlistList.first.id);

  LocalPlaylist? get selectedPlaylist {
    final id = selectedPlaylistId;
    if (id == null) {
      return null;
    }
    for (final playlist in playlistList) {
      if (playlist.id == id) {
        return playlist;
      }
    }
    return null;
  }

  FavoriteWriteAvailability favoriteWriteAvailability(ProviderId providerId) =>
      capabilityMatrix.favoriteWriteAvailability(registry, providerId);

  PlaylistReferenceResolver get playlistResolver =>
      PlaylistReferenceResolver(registry);

  Future<List<UnifiedFavoriteTrack>> loadAllFavorites() =>
      favoritesService.buildAllFavorites(registry);

  Future<List<SourceTrack>> loadRecommendations(ProviderId providerId) async {
    final entry = registry.entryOf(providerId);
    if (entry == null || !entry.isEnabled) {
      return const [];
    }
    return entry.provider.getDailyRecommendations();
  }

  Future<List<ProviderPlaylist>> loadRecommendedPlaylists(
    ProviderId providerId, {
    int limit = 12,
  }) async {
    final entry = registry.entryOf(providerId);
    if (entry == null || !entry.isEnabled) {
      return const [];
    }
    return entry.provider.getRecommendedPlaylists(limit: limit);
  }

  Future<List<ProviderPlaylist>> loadProviderPlaylists(
    ProviderId providerId,
  ) async {
    final entry = registry.entryOf(providerId);
    if (entry == null || !entry.isEnabled) {
      return const [];
    }
    return entry.provider.getUserPlaylists();
  }

  Future<List<SourceTrack>> loadProviderPlaylistTracks({
    required ProviderId providerId,
    required String playlistId,
  }) async {
    final entry = registry.entryOf(providerId);
    if (entry == null || !entry.isEnabled) {
      return const [];
    }
    return entry.provider.getPlaylistTracks(playlistId);
  }

  MeloDataSnapshot toSnapshot() {
    return MeloDataSnapshot(
      playlists: playlistList,
      downloadTasks: downloadCoordinator.allTasks,
      localMediaItems: downloadCoordinator.localItems,
      favoritesOverrides: favoritesOverrideRegistry,
    );
  }

  Future<void> persistNow() async {
    await snapshotStore?.write(toSnapshot());
  }

  Future<List<ProviderSearchResults>> search(String query) {
    if (query.trim().isEmpty) {
      return Future.value(const []);
    }
    return searchService.searchEverywhere(registry: registry, query: query);
  }

  SourceTrack? sourceTrackByRef(ProviderTrackRef ref) {
    final provider = providers[ref.providerId];
    return provider?.trackByRef(ref);
  }

  void selectPlaylist(String playlistId) {
    _selectedPlaylistId = playlistId;
    notifyListeners();
  }

  void createPlaylist(String name) {
    if (name.trim().isEmpty) {
      return;
    }
    final created = playlists.createPlaylist(name);
    _selectedPlaylistId = created.id;
    _persistSoon();
    notifyListeners();
  }

  void renamePlaylist({
    required String playlistId,
    required String nextName,
  }) {
    if (nextName.trim().isEmpty) {
      return;
    }
    playlists.renamePlaylist(playlistId: playlistId, nextName: nextName);
    _persistSoon();
    notifyListeners();
  }

  void deletePlaylist(String playlistId) {
    playlists.deletePlaylist(playlistId);
    if (_selectedPlaylistId == playlistId) {
      _selectedPlaylistId = playlistList.isEmpty ? null : playlistList.first.id;
    }
    _persistSoon();
    notifyListeners();
  }

  void addTrackToPlaylist({
    required String playlistId,
    required SourceTrack track,
  }) {
    playlists.addTrack(playlistId: playlistId, track: track);
    _persistSoon();
    notifyListeners();
  }

  void removeTrackFromPlaylist({
    required String playlistId,
    required ProviderTrackRef trackRef,
  }) {
    playlists.removeTrack(playlistId: playlistId, trackRef: trackRef);
    _persistSoon();
    notifyListeners();
  }

  Future<void> toggleFavorite({
    required SourceTrack track,
    required bool liked,
  }) async {
    final entry = registry.entryOf(track.ref.providerId);
    if (entry == null || !entry.isEnabled) {
      throw ProviderDisabledException(
        providerId: track.ref.providerId,
        message: 'Source provider is disabled.',
      );
    }
    await entry.provider.setFavorite(track: track.ref, liked: liked);
    notifyListeners();
  }

  void setProviderEnabled(ProviderId providerId, bool enabled) {
    registry.setEnabled(providerId, enabled);
    notifyListeners();
  }

  void toggleProviderAuthentication(ProviderId providerId) {
    if (providerId == neteaseProviderId) {
      clearNeteaseCredentials();
      return;
    }
    final provider = providers[providerId];
    if (provider == null ||
        !provider.descriptor.supports(ProviderCapability.authenticate)) {
      return;
    }
    provider.setAuthenticated(!provider.isAuthenticated);
    notifyListeners();
  }

  Future<void> saveNeteaseCredentials({
    required String cookie,
    String? userId,
  }) async {
    final credentials = NeteaseCredentials(
      cookie: cookie.trim(),
      userId: userId == null || userId.trim().isEmpty ? null : userId.trim(),
    );
    if (!credentials.hasCookie) {
      throw ArgumentError.value(cookie, 'cookie', 'Cookie must not be empty.');
    }
    await neteaseSessionStore?.write(credentials);
    _neteaseCredentials = credentials;
    _replaceNeteaseProvider(credentials);
    notifyListeners();
  }

  Future<void> clearNeteaseCredentials() async {
    await neteaseSessionStore?.clear();
    _neteaseCredentials = null;
    _replaceNeteaseProvider(null);
    notifyListeners();
  }

  Future<void> playTrack(SourceTrack track) async {
    playbackCoordinator.setQueue([track]);
    await playbackCoordinator.selectTrack(track.ref);
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  Future<void> playTracks(List<SourceTrack> tracks) async {
    final playableTracks =
        tracks.where((track) => track.isPlayable).toList(growable: false);
    if (playableTracks.isEmpty) return;

    playbackCoordinator.setQueue(playableTracks);
    await playbackCoordinator.selectTrack(playableTracks.first.ref);
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  Future<void> playUnifiedTrack(UnifiedFavoriteTrack track) async {
    playbackCoordinator.setQueue(track.variants);
    if (track.variants.isNotEmpty) {
      await playbackCoordinator.selectTrack(track.variants.first.ref);
    }
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  void enqueueTrack(SourceTrack track) {
    playbackCoordinator.enqueue(track);
    notifyListeners();
  }

  Future<void> selectTrackInQueue(ProviderTrackRef ref) async {
    await playbackCoordinator.selectTrack(ref);
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  Future<void> queueNext() async {
    await playbackCoordinator.next();
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  Future<void> queuePrevious() async {
    await playbackCoordinator.previous();
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  void addDownloadTask(SourceTrack track,
      {AudioQuality quality = AudioQuality.standard}) {
    downloadCoordinator.addTask(track, quality: quality);
    _persistSoon();
    notifyListeners();
  }

  Future<void> startDownload(ProviderTrackRef ref) async {
    await downloadCoordinator.startTask(ref);
    _persistSoon();
    notifyListeners();
  }

  void pauseDownload(ProviderTrackRef ref) {
    downloadCoordinator.pauseTask(ref);
    _persistSoon();
    notifyListeners();
  }

  Future<void> resumeDownload(ProviderTrackRef ref) async {
    await downloadCoordinator.resumeTask(ref);
    _persistSoon();
    notifyListeners();
  }

  void cancelDownload(ProviderTrackRef ref) {
    downloadCoordinator.cancelTask(ref);
    _persistSoon();
    notifyListeners();
  }

  void removeLocalMedia(ProviderTrackRef ref) {
    downloadCoordinator.removeLocalItem(ref);
    _persistSoon();
    notifyListeners();
  }

  void redownloadLocalMedia(ProviderTrackRef ref) {
    final track = sourceTrackByRef(ref);
    if (track == null) {
      removeLocalMedia(ref);
      return;
    }
    downloadCoordinator.removeLocalItem(ref);
    downloadCoordinator.addTask(track);
    _persistSoon();
    notifyListeners();
  }

  void simulateDownloadProgress(ProviderTrackRef ref) {
    downloadCoordinator.simulateProgressStep(ref);
    _persistSoon();
    notifyListeners();
  }

  Future<void> togglePlayPause() async {
    if (_audioPlayer.playing || _playbackRequested) {
      _playbackRequested = false;
      await _audioPlayer.pause();
    } else if (_playingTrackId != null) {
      _playbackRequested = true;
      await _audioPlayer.play();
    } else {
      await refreshPlaybackTicket();
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  Future<void> setVolume(double value) async {
    await _audioPlayer.setVolume(value.clamp(0.0, 1.0));
    notifyListeners();
  }

  Future<void> setPlaybackQuality(AudioQuality quality) async {
    playbackCoordinator.quality = quality;
    _playingTrackId = null;
    await _syncNativePlayback(playWhenReady: isPlaybackActive);
    notifyListeners();
  }

  Future<void> refreshPlaybackTicket() async {
    await playbackCoordinator.refreshCurrentTicketIfNeeded(force: true);
    _playingTrackId = null;
    _playbackRequested = false;
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  Future<void> _syncNativePlayback({required bool playWhenReady}) async {
    final queue = playbackCoordinator.queueState;
    final current = queue.current?.track;
    final currentTicket = playbackCoordinator.currentTicket;
    if (current == null || currentTicket == null) {
      return;
    }

    // Dedup: don't restart if the same track is already playing.
    final trackId = current.ref.trackId;
    if (_playingTrackId == trackId && _audioPlayer.playing) {
      return;
    }

    if (playWhenReady) {
      _playingTrackId = trackId;
      _playbackRequested = true;
      try {
        final url = currentTicket.mediaUri.toString();
        debugPrint('AUDIO: playing "${current.title}"');
        await _audioPlayer.setUrl(
          url,
          headers: currentTicket.headers.isEmpty ? null : currentTicket.headers,
        );
        _audioPlayer.play();
      } catch (e) {
        debugPrint('Audio Error: $e');
        _playingTrackId = null;
        _playbackRequested = false;
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _persistSoon() {
    final store = snapshotStore;
    if (store == null) {
      return;
    }
    Future<void>(() => store.write(toSnapshot()));
  }

  void _replaceNeteaseProvider(NeteaseCredentials? credentials) {
    final wasEnabled = registry.isEnabled(neteaseProviderId);
    registry.register(
      NeteaseMusicProvider(credentials: credentials),
      enabled: wasEnabled,
    );
  }

  Future<String?> getLyrics(ProviderTrackRef ref) async {
    final provider = registry.entryOf(ref.providerId)?.provider;
    if (provider == null) return null;
    return provider.getLyrics(ref);
  }
}
