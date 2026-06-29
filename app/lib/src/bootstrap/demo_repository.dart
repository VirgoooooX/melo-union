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
  final repository = ref.watch(demoRepositoryProvider);
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
  }

  factory DemoRepository.seeded({
    MeloDataSnapshot? snapshot,
    MeloSnapshotStore? snapshotStore,
    NeteaseCredentials? neteaseCredentials,
    NeteaseSessionStore? neteaseSessionStore,
  }) {
    final alphaId = ProviderId('aurora_stream');
    final betaId = ProviderId('beacon_archive');
    final catalogId = ProviderId('compass_catalog');
    final netease = NeteaseMusicProvider(credentials: neteaseCredentials);

    final alpha = FakeMusicProvider(
      descriptor: ProviderDescriptor(
        id: alphaId,
        displayName: 'Aurora Stream',
        capabilities: const {
          ProviderCapability.authenticate,
          ProviderCapability.readFavorites,
          ProviderCapability.writeFavorites,
          ProviderCapability.readUserPlaylists,
          ProviderCapability.readDailyRecommendations,
          ProviderCapability.search,
          ProviderCapability.resolvePlayback,
          ProviderCapability.resolveDownload,
        },
        shortDescription: 'Full-account provider',
      ),
      profile: const ProviderAccountProfile(
        accountId: 'aurora_demo',
        displayName: 'Aurora Demo Account',
      ),
      seedTracks: [
        SourceTrack(
          ref: ProviderTrackRef(
            providerId: alphaId,
            trackId: 'alpha_midnight',
            extraIds: const {'album_id': 'aurora_001'},
          ),
          title: 'Midnight Signal',
          artists: const ['Luna Park'],
          album: 'Neon Hours',
          duration: const Duration(minutes: 3, seconds: 10),
          isFavorited: true,
          isDownloadable: true,
        ),
        SourceTrack(
          ref: ProviderTrackRef(
            providerId: alphaId,
            trackId: 'alpha_velvet',
            extraIds: const {'album_id': 'aurora_002'},
          ),
          title: 'Velvet Skyline',
          artists: const ['Current Echo'],
          album: 'Afterglow',
          duration: const Duration(minutes: 4, seconds: 2),
          isFavorited: true,
          isDownloadable: true,
        ),
        SourceTrack(
          ref: ProviderTrackRef(
            providerId: alphaId,
            trackId: 'alpha_sundial',
            extraIds: const {'album_id': 'aurora_003'},
          ),
          title: 'Sundial Drive',
          artists: const ['Transit Club'],
          album: 'Windows Down',
          duration: const Duration(minutes: 3, seconds: 28),
          isFavorited: false,
          isDownloadable: true,
        ),
      ],
    );

    final beta = FakeMusicProvider(
      descriptor: ProviderDescriptor(
        id: betaId,
        displayName: 'Beacon Archive',
        capabilities: const {
          ProviderCapability.authenticate,
          ProviderCapability.readFavorites,
          ProviderCapability.readUserPlaylists,
          ProviderCapability.search,
          ProviderCapability.resolvePlayback,
        },
        shortDescription: 'Read-only account provider',
      ),
      profile: const ProviderAccountProfile(
        accountId: 'beacon_demo',
        displayName: 'Beacon Demo Account',
      ),
      seedTracks: [
        SourceTrack(
          ref: ProviderTrackRef(
            providerId: betaId,
            trackId: 'beta_midnight',
            extraIds: const {'catalog_id': 'beacon_101'},
          ),
          title: 'Midnight Signal',
          artists: const ['Luna Park'],
          album: 'Recorded Session',
          duration: const Duration(minutes: 3, seconds: 11),
          isFavorited: true,
        ),
        SourceTrack(
          ref: ProviderTrackRef(
            providerId: betaId,
            trackId: 'beta_archive',
            extraIds: const {'catalog_id': 'beacon_102'},
          ),
          title: 'Archive Tape',
          artists: const ['Signal Room'],
          album: 'Station Set',
          duration: const Duration(minutes: 4),
          isFavorited: true,
        ),
        SourceTrack(
          ref: ProviderTrackRef(
            providerId: betaId,
            trackId: 'beta_transfer',
            extraIds: const {'catalog_id': 'beacon_103'},
          ),
          title: 'Transfer Platform',
          artists: const ['Neon Static'],
          album: 'Shared Line',
          duration: const Duration(minutes: 3, seconds: 45),
          isFavorited: false,
        ),
      ],
    );

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

    final registry = StaticProviderRegistry([alpha, beta, catalog, netease]);
    final defaultPlaylists = [
      LocalPlaylist(
        id: 'playlist_commute',
        name: 'Morning Commute',
        items: [
          LocalPlaylistItem(
            trackRef: alpha.allTracks().first.ref,
            cachedTitle: 'Midnight Signal',
            cachedArtists: const ['Luna Park'],
            cachedProviderName: 'Aurora Stream',
            addedAt: DateTime.utc(2026, 6, 28, 7, 30),
          ),
          LocalPlaylistItem(
            trackRef: beta.allTracks()[1].ref,
            cachedTitle: 'Archive Tape',
            cachedArtists: const ['Signal Room'],
            cachedProviderName: 'Beacon Archive',
            addedAt: DateTime.utc(2026, 6, 28, 7, 32),
          ),
        ],
      ),
      LocalPlaylist(
        id: 'playlist_notes',
        name: 'Crossfade Notes',
        items: [
          LocalPlaylistItem(
            trackRef: beta.allTracks().first.ref,
            cachedTitle: 'Midnight Signal',
            cachedArtists: const ['Luna Park'],
            cachedProviderName: 'Beacon Archive',
            addedAt: DateTime.utc(2026, 6, 28, 23, 10),
          ),
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
        alphaId: alpha,
        betaId: beta,
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
    repo.playbackCoordinator.setQueue([
      alpha.allTracks().first,
      beta.allTracks().first,
    ]);
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

  PlaybackQueueState get queue => playbackCoordinator.queueState;

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
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  Future<void> playUnifiedTrack(UnifiedFavoriteTrack track) async {
    playbackCoordinator.setQueue(track.variants);
    if (track.variants.isNotEmpty) {
      await playbackCoordinator.selectTrack(track.variants.first.ref);
    }
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  void enqueueTrack(SourceTrack track) {
    playbackCoordinator.enqueue(track);
    notifyListeners();
  }

  Future<void> selectTrackInQueue(ProviderTrackRef ref) async {
    await playbackCoordinator.selectTrack(ref);
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  Future<void> queueNext() async {
    await playbackCoordinator.next();
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  Future<void> queuePrevious() async {
    await playbackCoordinator.previous();
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

  Future<void> refreshPlaybackTicket() async {
    await playbackCoordinator.refreshCurrentTicketIfNeeded(force: true);
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

    final nativeItems = <PlatformPlaybackItem>[
      _nativeItemFor(track: current, ticket: currentTicket),
    ];

    final nextTicket = playbackCoordinator.nextTicket;
    if (nextTicket != null) {
      for (final entry in queue.entries) {
        if (entry.track.ref == nextTicket.trackRef) {
          nativeItems
              .add(_nativeItemFor(track: entry.track, ticket: nextTicket));
          break;
        }
      }
    }

    await playbackBridge.loadQueue(nativeItems, playWhenReady: playWhenReady);
  }

  PlatformPlaybackItem _nativeItemFor({
    required SourceTrack track,
    required PlaybackTicket ticket,
  }) {
    return PlatformPlaybackItem(
      mediaUri: ticket.mediaUri,
      title: track.title,
      artists: track.artists,
      providerId: track.ref.providerId.value,
      trackId: track.ref.trackId,
      headers: ticket.headers,
      expiresAt: ticket.expiresAt,
    );
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
}
