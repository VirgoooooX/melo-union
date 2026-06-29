import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import '../fakes/fake_music_provider.dart';
import '../features/all_favorites/all_favorites_page.dart';
import '../features/downloads/downloads_page.dart';
import '../features/local_playlists/local_playlists_page.dart';
import '../features/providers/providers_page.dart';
import '../features/search/search_page.dart';
import '../layout/app_shell_scaffold.dart';

final demoRepositoryProvider = ChangeNotifierProvider<DemoRepository>(
  (ref) => DemoRepository.seeded(),
);

final allFavoritesProvider = FutureProvider<List<UnifiedFavoriteTrack>>((ref) {
  final repository = ref.watch(demoRepositoryProvider);
  return repository.loadAllFavorites();
});

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppDestination.favorites.path,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShellScaffold(
          location: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppDestination.favorites.path,
            builder: (context, state) => const AllFavoritesPage(),
          ),
          GoRoute(
            path: AppDestination.search.path,
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: AppDestination.playlists.path,
            builder: (context, state) => const LocalPlaylistsPage(),
          ),
          GoRoute(
            path: AppDestination.downloads.path,
            builder: (context, state) => const DownloadsPage(),
          ),
          GoRoute(
            path: AppDestination.providers.path,
            builder: (context, state) => const ProvidersPage(),
          ),
        ],
      ),
    ],
  );
});

enum AppDestination {
  favorites('/favorites'),
  search('/search'),
  playlists('/playlists'),
  downloads('/downloads'),
  providers('/providers');

  const AppDestination(this.path);

  final String path;
}

class DemoRepository extends ChangeNotifier {
  DemoRepository._({
    required this.registry,
    required this.playlists,
    required this.providers,
  }) : _selectedPlaylistId = playlists.listPlaylists().isEmpty
            ? null
            : playlists.listPlaylists().first.id {
    playbackCoordinator = PlaybackCoordinator(registry: registry);
    downloadCoordinator = DownloadCoordinator(registry: registry);
  }

  factory DemoRepository.seeded() {
    final alphaId = ProviderId('aurora_stream');
    final betaId = ProviderId('beacon_archive');
    final catalogId = ProviderId('compass_catalog');

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

    final registry = StaticProviderRegistry([alpha, beta, catalog]);
    final playlists = InMemoryLocalPlaylistRepository(
      seedPlaylists: [
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
      ],
    );

    final repo = DemoRepository._(
      registry: registry,
      playlists: playlists,
      providers: {
        alphaId: alpha,
        betaId: beta,
        catalogId: catalog,
      },
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
  final ProviderCapabilityMatrix capabilityMatrix =
      const ProviderCapabilityMatrix();
  final UnifiedFavoritesService favoritesService =
      const UnifiedFavoritesService();
  final CapabilityAwareSearchService searchService =
      const CapabilityAwareSearchService();

  late final PlaybackCoordinator playbackCoordinator;
  late final DownloadCoordinator downloadCoordinator;
  final FavoritesOverrideRegistry favoritesOverrideRegistry =
      FavoritesOverrideRegistry();
  String? _selectedPlaylistId;

  PlaybackQueueState get queue => playbackCoordinator.queueState;

  List<ProviderRegistryEntry> get providerEntries => registry.allEntries();

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
    notifyListeners();
  }

  void deletePlaylist(String playlistId) {
    playlists.deletePlaylist(playlistId);
    if (_selectedPlaylistId == playlistId) {
      _selectedPlaylistId = playlistList.isEmpty ? null : playlistList.first.id;
    }
    notifyListeners();
  }

  void addTrackToPlaylist({
    required String playlistId,
    required SourceTrack track,
  }) {
    playlists.addTrack(playlistId: playlistId, track: track);
    notifyListeners();
  }

  void removeTrackFromPlaylist({
    required String playlistId,
    required ProviderTrackRef trackRef,
  }) {
    playlists.removeTrack(playlistId: playlistId, trackRef: trackRef);
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
    final provider = providers[providerId];
    if (provider == null ||
        !provider.descriptor.supports(ProviderCapability.authenticate)) {
      return;
    }
    provider.setAuthenticated(!provider.isAuthenticated);
    notifyListeners();
  }

  Future<void> playTrack(SourceTrack track) async {
    playbackCoordinator.setQueue([track]);
    await playbackCoordinator.selectTrack(track.ref);
    notifyListeners();
  }

  Future<void> playUnifiedTrack(UnifiedFavoriteTrack track) async {
    playbackCoordinator.setQueue(track.variants);
    if (track.variants.isNotEmpty) {
      await playbackCoordinator.selectTrack(track.variants.first.ref);
    }
    notifyListeners();
  }

  void enqueueTrack(SourceTrack track) {
    playbackCoordinator.enqueue(track);
    notifyListeners();
  }

  Future<void> selectTrackInQueue(ProviderTrackRef ref) async {
    await playbackCoordinator.selectTrack(ref);
    notifyListeners();
  }

  Future<void> queueNext() async {
    await playbackCoordinator.next();
    notifyListeners();
  }

  Future<void> queuePrevious() async {
    await playbackCoordinator.previous();
    notifyListeners();
  }

  void addDownloadTask(SourceTrack track,
      {AudioQuality quality = AudioQuality.standard}) {
    downloadCoordinator.addTask(track, quality: quality);
    notifyListeners();
  }

  Future<void> startDownload(ProviderTrackRef ref) async {
    await downloadCoordinator.startTask(ref);
    notifyListeners();
  }

  void pauseDownload(ProviderTrackRef ref) {
    downloadCoordinator.pauseTask(ref);
    notifyListeners();
  }

  Future<void> resumeDownload(ProviderTrackRef ref) async {
    await downloadCoordinator.resumeTask(ref);
    notifyListeners();
  }

  void cancelDownload(ProviderTrackRef ref) {
    downloadCoordinator.cancelTask(ref);
    notifyListeners();
  }

  void simulateDownloadProgress(ProviderTrackRef ref) {
    downloadCoordinator.simulateProgressStep(ref);
    notifyListeners();
  }

  Future<void> refreshPlaybackTicket() async {
    await playbackCoordinator.refreshCurrentTicketIfNeeded(force: true);
    notifyListeners();
  }
}
