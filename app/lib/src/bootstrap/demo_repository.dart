import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:music_data/music_data.dart';
import 'package:music_domain/music_domain.dart';
import 'package:path/path.dart' as path;
import 'package:provider_contract/provider_contract.dart';
import 'package:provider_netease/provider_netease.dart';
import 'package:provider_qq/provider_qq.dart';
import 'package:provider_kugou/provider_kugou.dart';

import '../fakes/fake_music_provider.dart';
import '../platform/notification_permission_bridge.dart';
import 'netease_session_store.dart';
import 'qq_music_session_store.dart';
import 'kugou_session_store.dart';

class _CacheEntry<T> {
  _CacheEntry(this.data, {DateTime? fetchedAt})
      : _fetchedAt = fetchedAt ?? DateTime.now();

  final T data;
  final DateTime _fetchedAt;
  bool isFresh(Duration ttl) => DateTime.now().difference(_fetchedAt) < ttl;
}

final demoRepositoryProvider = ChangeNotifierProvider<DemoRepository>(
  (ref) => DemoRepository.seeded(),
);

final allFavoritesProvider = FutureProvider<List<UnifiedFavoriteTrack>>((ref) {
  ref.watch(demoRepositoryProvider.select((r) => r.favoritesVersion));
  return ref.read(demoRepositoryProvider).loadAllFavorites();
});

const _androidStorageChannel = MethodChannel('melo_union/storage');
const _dataDirOverrideEnv = 'MELO_UNION_DATA_DIR';

enum PlaybackRepeatMode { off, all, one }

enum ProviderSessionActionKind { cookieImport, qrLogin }

final class PlaybackIssue {
  const PlaybackIssue({
    required this.title,
    required this.message,
    required this.occurredAt,
    this.trackRef,
  });

  final ProviderTrackRef? trackRef;
  final String title;
  final String message;
  final DateTime occurredAt;
}

final class _NativePlaybackSource {
  const _NativePlaybackSource({
    required this.track,
    required this.ticket,
  });

  final SourceTrack track;
  final PlaybackTicket ticket;

  ProviderTrackRef get ref => track.ref;

  AudioSource toAudioSource() {
    return AudioSource.uri(
      ticket.mediaUri,
      headers: ticket.headers.isEmpty ? null : ticket.headers,
      tag: MediaItem(
        id: '${track.ref.providerId.value}:${track.ref.trackId}',
        title: track.title,
        artist: track.artists.join(' / '),
        album: track.album,
        duration: track.duration,
        artUri: track.artwork,
      ),
    );
  }
}

final class _NativePlaybackWindow {
  const _NativePlaybackWindow({
    required this.sources,
    required this.currentIndex,
  });

  final List<_NativePlaybackSource> sources;
  final int currentIndex;
}

final class ProviderSessionAction {
  const ProviderSessionAction({
    required this.kind,
    required this.description,
    this.clear,
  });

  final ProviderSessionActionKind kind;
  final String description;
  final Future<void> Function()? clear;
}

class DemoRepository extends ChangeNotifier {
  DemoRepository._({
    required this.registry,
    required this.playlists,
    required this.providers,
    FavoritesOverrideRegistry? favoritesOverrideRegistry,
    LikedAtLedger? favoriteLikedAtLedger,
    List<FavoriteSnapshot> seedFavoriteProviderSnapshots = const [],
    CachedUnifiedFavorites? seedUnifiedFavoritesCache,
    List<FavoriteProviderStateSnapshot> seedFavoriteProviderStates = const [],
    List<DownloadTask> seedDownloadTasks = const [],
    List<LocalMediaItem> seedLocalMediaItems = const [],
    this.snapshotStore,
    NeteaseCredentials? neteaseCredentials,
    this.neteaseSessionStore,
    QqMusicCredentials? qqMusicCredentials,
    this.qqMusicSessionStore,
    this.kugouSessionStore,
    this.notificationPermissionBridge = const NotificationPermissionBridge(),
    AudioQuality playbackQuality = AudioQuality.standard,
    double volume = 1.0,
    PlaybackPreferencesSnapshot playbackPreferences =
        const PlaybackPreferencesSnapshot(),
    PlaybackQueueSnapshot? playbackQueue,
    String? downloadDirectory,
  })  : favoritesOverrideRegistry =
            favoritesOverrideRegistry ?? FavoritesOverrideRegistry(),
        favoriteLikedAtLedger = favoriteLikedAtLedger ?? LikedAtLedger(),
        _favoriteProviderSnapshots = {
          for (final snapshot in seedFavoriteProviderSnapshots)
            snapshot.providerId: snapshot,
        },
        _favoriteProviderStates = {
          for (final state in seedFavoriteProviderStates)
            state.providerId: state,
        },
        _unifiedFavoritesCache = seedUnifiedFavoritesCache,
        _neteaseCredentials = neteaseCredentials,
        _qqMusicCredentials = qqMusicCredentials,
        _volume = volume.clamp(0.0, 1.0).toDouble(),
        _rememberQueue = playbackPreferences.rememberQueue,
        _restorePlaybackState = playbackPreferences.restorePlaybackState &&
            playbackPreferences.rememberQueue,
        _downloadDirectory = _normalizeConfiguredDirectory(downloadDirectory),
        _selectedPlaylistId = playlists.listPlaylists().isEmpty
            ? null
            : playlists.listPlaylists().first.id {
    playbackCoordinator = PlaybackCoordinator(
      registry: registry,
      defaultQuality: playbackQuality,
    );
    downloadCoordinator = DownloadCoordinator(
      registry: registry,
      seedTasks: seedDownloadTasks,
      seedLocalItems: seedLocalMediaItems,
    );
    _restorePlaybackQueue(playbackQueue);
    unawaited(_audioPlayer.setVolume(_volume));
    _audioPlayer.positionStream.listen((position) {
      _lastKnownPlaybackPosition = position;
      if (!_rememberQueue || !_restorePlaybackState) return;
      final now = DateTime.now();
      final previous = _lastPlaybackPositionPersistAt;
      if (previous != null && now.difference(previous).inSeconds < 5) {
        return;
      }
      _lastPlaybackPositionPersistAt = now;
      _persistSoon();
    });
    // Notify UI when audio player state changes (play/pause/complete)
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _playbackRequested = false;
        notifyListeners();
        unawaited(_handlePlaybackCompleted());
        return;
      }
      if (state.processingState == ProcessingState.idle) {
        _playbackRequested = false;
      }
      if (!state.playing &&
          (state.processingState == ProcessingState.ready ||
              state.processingState == ProcessingState.completed)) {
        _playbackRequested = false;
      }
      _persistPlaybackStateSoon();
      notifyListeners();
    });
    _audioPlayer.currentIndexStream.listen((index) {
      if (_updatingNativeAudioSource || _handlingNativeAudioIndexChange) {
        return;
      }
      if (index == null ||
          index < 0 ||
          index >= _nativeAudioSourceRefs.length) {
        return;
      }
      final ref = _nativeAudioSourceRefs[index];
      if (queue.current?.track.ref == ref) {
        return;
      }
      unawaited(_handleNativeAudioIndexChange(ref));
    });
  }

  factory DemoRepository.seeded({
    MeloDataSnapshot? snapshot,
    MeloSnapshotStore? snapshotStore,
    NeteaseCredentials? neteaseCredentials,
    NeteaseSessionStore? neteaseSessionStore,
    QqMusicCredentials? qqMusicCredentials,
    QqMusicSessionStore? qqMusicSessionStore,
    KugouSession? kugouSession,
    KugouSessionStore? kugouSessionStore,
    List<MusicProvider> additionalProviders = const [],
  }) {
    final catalogId = ProviderId('compass_catalog');
    final netease = NeteaseMusicProvider(credentials: neteaseCredentials);
    final qqMusic = QqMusicProvider(credentials: qqMusicCredentials);
    final kugou = KugouMusicProvider.create(
      secureStore: kugouSessionStore ?? const NullKugouSessionStore(),
      initialSession: kugouSession,
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

    final registry = StaticProviderRegistry([
      ...additionalProviders,
      catalog,
      netease,
      qqMusic,
      kugou,
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
      favoriteLikedAtLedger: snapshot?.favoriteLikedAtLedger,
      seedFavoriteProviderSnapshots:
          snapshot?.favoriteProviderSnapshots ?? const [],
      seedUnifiedFavoritesCache: snapshot?.unifiedFavoritesCache,
      seedFavoriteProviderStates: snapshot?.favoriteProviderStates ?? const [],
      seedDownloadTasks: snapshot?.downloadTasks ?? const [],
      seedLocalMediaItems: snapshot?.localMediaItems ?? const [],
      snapshotStore: snapshotStore,
      neteaseCredentials: neteaseCredentials,
      neteaseSessionStore: neteaseSessionStore,
      qqMusicCredentials: qqMusicCredentials,
      qqMusicSessionStore: qqMusicSessionStore,
      kugouSessionStore: kugouSessionStore,
      notificationPermissionBridge: const NotificationPermissionBridge(),
      playbackQuality: snapshot?.playbackQuality ?? AudioQuality.standard,
      volume: snapshot?.volume ?? 1.0,
      playbackPreferences:
          snapshot?.playbackPreferences ?? const PlaybackPreferencesSnapshot(),
      playbackQueue: snapshot?.playbackQueue,
      downloadDirectory: snapshot?.downloadDirectory,
    );
    final allSeededTracks = [
      for (final provider in additionalProviders.whereType<FakeMusicProvider>())
        if (provider.allTracks().isNotEmpty) provider.allTracks().first,
    ];
    if (allSeededTracks.isNotEmpty && snapshot?.playbackQueue == null) {
      repo.playbackCoordinator.setQueue(allSeededTracks);
    }
    final cachedFavorites = snapshot?.unifiedFavoritesCache?.tracks;
    if (cachedFavorites != null && cachedFavorites.isNotEmpty) {
      repo._lastFavoritesData = List.unmodifiable(cachedFavorites);
      for (final track in cachedFavorites) {
        repo._rememberTracks(track.variants);
      }
    }
    return repo;
  }

  final StaticProviderRegistry registry;
  final InMemoryLocalPlaylistRepository playlists;
  final Map<ProviderId, FakeMusicProvider> providers;
  final MeloSnapshotStore? snapshotStore;
  final NeteaseSessionStore? neteaseSessionStore;
  final QqMusicSessionStore? qqMusicSessionStore;
  final KugouSessionStore? kugouSessionStore;
  final NotificationPermissionBridge notificationPermissionBridge;
  final ProviderCapabilityMatrix capabilityMatrix =
      const ProviderCapabilityMatrix();
  final UnifiedFavoritesService favoritesService =
      const UnifiedFavoritesService();
  final CapabilityAwareSearchService searchService =
      const CapabilityAwareSearchService();

  late final PlaybackCoordinator playbackCoordinator;
  late final DownloadCoordinator downloadCoordinator;
  final FavoritesOverrideRegistry favoritesOverrideRegistry;
  final LikedAtLedger favoriteLikedAtLedger;
  final Map<ProviderId, FavoriteSnapshot> _favoriteProviderSnapshots;
  final Map<ProviderId, FavoriteProviderStateSnapshot> _favoriteProviderStates;
  CachedUnifiedFavorites? _unifiedFavoritesCache;
  NeteaseCredentials? _neteaseCredentials;
  QqMusicCredentials? _qqMusicCredentials;
  String? _selectedPlaylistId;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
  final Map<ProviderTrackRef, SourceTrack> _trackCache = {};
  String? _playingTrackId;
  PlaybackIssue? _playbackIssue;
  double _volume;
  bool _rememberQueue;
  bool _restorePlaybackState;
  Duration _lastKnownPlaybackPosition = Duration.zero;
  Duration? _pendingRestorePosition;
  DateTime? _lastPlaybackPositionPersistAt;
  String? _downloadDirectory;
  List<ProviderTrackRef> _nativeAudioSourceRefs = const [];
  bool _updatingNativeAudioSource = false;
  bool _handlingNativeAudioIndexChange = false;
  bool _playbackRequested = false;
  bool _shuffleEnabled = false;
  bool _isAdvancingAfterCompletion = false;
  PlaybackRepeatMode _repeatMode = PlaybackRepeatMode.off;

  /// Incremented on login/logout/toggle to trigger [allFavoritesProvider] refresh.
  int _favoritesVersion = 0;

  int get favoritesVersion => _favoritesVersion;

  PlaybackQueueState get queue => playbackCoordinator.queueState;

  bool get isPlaying => _audioPlayer.playing;

  bool get isPlaybackActive => _audioPlayer.playing || _playbackRequested;

  bool get isPlaybackStarting => _playbackRequested && !_audioPlayer.playing;

  AudioPlayer get audioPlayer => _audioPlayer;

  PlaybackIssue? get playbackIssue => _playbackIssue;

  bool get hasPlaybackIssue => _playbackIssue != null;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  double get volume => _volume;

  AudioQuality get playbackQuality => playbackCoordinator.quality;

  bool get rememberQueue => _rememberQueue;

  bool get restorePlaybackState => _restorePlaybackState;

  bool get shuffleEnabled => _shuffleEnabled;

  PlaybackRepeatMode get repeatMode => _repeatMode;

  List<ProviderRegistryEntry> get providerEntries => registry.allEntries();

  bool get hasNeteaseSession => _neteaseCredentials?.hasCookie ?? false;

  bool get hasQqMusicSession => _qqMusicCredentials?.hasCookie ?? false;

  bool get hasKugouSession =>
      registry.find(kugouProviderId)?.isAuthenticated ?? false;

  ProviderSessionAction? sessionActionFor(ProviderId providerId) {
    if (providerId == neteaseProviderId) {
      return ProviderSessionAction(
        kind: ProviderSessionActionKind.qrLogin,
        description:
            '推荐使用网易云音乐 App 扫码登录；Cookie 不写入 SQLite 或快照，会保存到平台安全存储。高级兜底仍可导入本机 Cookie。',
        clear: clearNeteaseCredentials,
      );
    }
    if (providerId == qqMusicProviderId) {
      return ProviderSessionAction(
        kind: ProviderSessionActionKind.cookieImport,
        description:
            'QQ 音乐扫码登录暂不可用。请从浏览器已登录的 y.qq.com 复制完整 Cookie 导入，Cookie 会保存到平台安全存储。',
        clear: clearQqMusicCredentials,
      );
    }
    if (providerId == kugouProviderId) {
      return ProviderSessionAction(
        kind: ProviderSessionActionKind.qrLogin,
        description: '请使用酷狗音乐 App 扫码登录。当前扫码登录是登录酷狗账号的唯一方式。',
        clear: () async {
          final provider =
              registry.find(kugouProviderId) as KugouMusicProvider?;
          if (provider != null) {
            await provider.logout();
          }
          _discardFavoriteProvider(kugouProviderId);
          _favoritesVersion++;
          notifyListeners();
        },
      );
    }
    return null;
  }

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

  Future<List<UnifiedFavoriteTrack>> loadAllFavorites() async {
    final eligibleEntries = capabilityMatrix.eligibleFavoritesEntries(registry);
    final failures = <ProviderId, String>{};

    for (final entry in eligibleEntries) {
      final providerId = entry.descriptor.id;
      try {
        final pulled = await entry.provider.pullFavorites();
        final normalized = _normalizeFavoriteSnapshot(
          pulled,
          previous: _favoriteProviderSnapshots[providerId],
        );
        _favoriteProviderSnapshots[providerId] = normalized;
        _favoriteProviderStates[providerId] = FavoriteProviderStateSnapshot(
          providerId: providerId,
          lastSuccessAt: DateTime.now().toUtc(),
          lastFailureAt: _favoriteProviderStates[providerId]?.lastFailureAt,
          lastFailureMessage:
              _favoriteProviderStates[providerId]?.lastFailureMessage,
        );
      } catch (e) {
        failures[providerId] = e.toString();
        final previous = _favoriteProviderStates[providerId];
        _favoriteProviderStates[providerId] = FavoriteProviderStateSnapshot(
          providerId: providerId,
          lastSuccessAt: previous?.lastSuccessAt,
          lastFailureAt: DateTime.now().toUtc(),
          lastFailureMessage: e.toString(),
        );
      }
    }

    final result = favoritesService.buildFromSnapshots(
      _eligibleFavoriteSnapshots(),
      failures: failures,
      overrides: favoritesOverrideRegistry,
      likedAtLedger: favoriteLikedAtLedger,
    );
    _unifiedFavoritesCache = CachedUnifiedFavorites(
      tracks: result.tracks,
      builtAt: DateTime.now().toUtc(),
    );
    _lastFavoritesData = result.tracks;
    for (final track in result.tracks) {
      _rememberTracks(track.variants);
    }
    _persistSoon();
    return result.tracks;
  }

  /// Most recently loaded favorites data, persisted across page rebuilds.
  /// Null until the first successful load.
  List<UnifiedFavoriteTrack>? _lastFavoritesData;
  List<UnifiedFavoriteTrack>? get lastFavoritesData => _lastFavoritesData;

  // ——— Generic TTL cache ———
  static const _recommendationsTtl = Duration(minutes: 30);
  static const _playlistsTtl = Duration(minutes: 10);

  final Map<String, _CacheEntry<List<SourceTrack>>> _recCache = {};
  final Map<String, _CacheEntry<List<ProviderPlaylist>>> _playlistCache = {};
  final Map<String, _CacheEntry<List<SourceTrack>>> _playlistTrackCache = {};

  void _rememberTrack(SourceTrack track) {
    _trackCache[track.ref] = track;
  }

  void _rememberTracks(Iterable<SourceTrack> tracks) {
    for (final track in tracks) {
      _rememberTrack(track);
    }
  }

  List<SourceTrack>? cachedRecommendations(ProviderId pid) =>
      _recCache[pid.value]?.data;
  bool get hasFreshRecommendations =>
      _recCache.values.any((e) => e.isFresh(_recommendationsTtl));

  List<ProviderPlaylist>? cachedRemotePlaylists(ProviderId pid) =>
      _playlistCache[pid.value]?.data;
  bool hasFreshRemotePlaylists(ProviderId pid) =>
      _playlistCache[pid.value]?.isFresh(_playlistsTtl) ?? false;

  List<ProviderPlaylist>? cachedRecommendedPlaylists(ProviderId pid) =>
      _playlistCache['${pid.value}/recommended']?.data;
  bool hasFreshRecommendedPlaylists(ProviderId pid) =>
      _playlistCache['${pid.value}/recommended']?.isFresh(_playlistsTtl) ??
      false;

  List<ProviderPlaylist>? cachedChartPlaylists(ProviderId pid) =>
      _playlistCache['${pid.value}/charts']?.data;
  bool hasFreshChartPlaylists(ProviderId pid) =>
      _playlistCache['${pid.value}/charts']?.isFresh(_playlistsTtl) ?? false;

  List<SourceTrack>? cachedPlaylistTracks(ProviderId pid, String playlistId) =>
      _playlistTrackCache['${pid.value}/$playlistId']?.data;
  bool hasFreshPlaylistTracks(ProviderId pid, String playlistId) =>
      _playlistTrackCache['${pid.value}/$playlistId']?.isFresh(_playlistsTtl) ??
      false;

  Future<List<SourceTrack>> loadRecommendations(ProviderId providerId) async {
    final entry = registry.entryOf(providerId);
    if (entry == null || !entry.isEnabled) {
      return const [];
    }
    final result = await entry.provider.getDailyRecommendations();
    _rememberTracks(result);
    _recCache[providerId.value] = _CacheEntry(result);
    return result;
  }

  Future<List<ProviderPlaylist>> loadRecommendedPlaylists(
    ProviderId providerId, {
    int limit = 12,
  }) async {
    final entry = registry.entryOf(providerId);
    if (entry == null || !entry.isEnabled) {
      return const [];
    }
    final result = await entry.provider.getRecommendedPlaylists(limit: limit);
    _playlistCache['${providerId.value}/recommended'] = _CacheEntry(result);
    return result;
  }

  Future<List<ProviderPlaylist>> loadChartPlaylists(
    ProviderId providerId, {
    int limit = 20,
  }) async {
    final entry = registry.entryOf(providerId);
    if (entry == null || !entry.isEnabled) {
      return const [];
    }
    final result = await entry.provider.getChartPlaylists(limit: limit);
    _playlistCache['${providerId.value}/charts'] = _CacheEntry(result);
    return result;
  }

  Future<List<ProviderPlaylist>> loadProviderPlaylists(
    ProviderId providerId,
  ) async {
    final entry = registry.entryOf(providerId);
    if (entry == null || !entry.isEnabled) {
      return const [];
    }
    final result = await entry.provider.getUserPlaylists();
    _playlistCache[providerId.value] = _CacheEntry(result);
    return result;
  }

  Future<List<SourceTrack>> loadProviderPlaylistTracks({
    required ProviderId providerId,
    required String playlistId,
  }) async {
    final entry = registry.entryOf(providerId);
    if (entry == null || !entry.isEnabled) {
      return const [];
    }
    final result = await entry.provider.getPlaylistTracks(playlistId);
    _rememberTracks(result);
    _playlistTrackCache['${providerId.value}/$playlistId'] =
        _CacheEntry(result);
    return result;
  }

  MeloDataSnapshot toSnapshot() {
    return MeloDataSnapshot(
      playlists: playlistList,
      downloadTasks: downloadCoordinator.allTasks,
      localMediaItems: downloadCoordinator.localItems,
      favoriteProviderSnapshots:
          _favoriteProviderSnapshots.values.toList(growable: false),
      favoriteLikedAtLedger: favoriteLikedAtLedger,
      unifiedFavoritesCache: _unifiedFavoritesCache,
      favoriteProviderStates:
          _favoriteProviderStates.values.toList(growable: false),
      playbackQuality: playbackQuality,
      volume: volume,
      playbackPreferences: PlaybackPreferencesSnapshot(
        rememberQueue: _rememberQueue,
        restorePlaybackState: _restorePlaybackState,
      ),
      playbackQueue: _rememberQueue ? _currentPlaybackQueueSnapshot() : null,
      downloadDirectory: _downloadDirectory,
      favoritesOverrides: favoritesOverrideRegistry,
    );
  }

  Future<void> restoreFromSnapshot(MeloDataSnapshot snapshot) async {
    playlists.replaceAll(snapshot.playlists);
    _selectedPlaylistId = playlistList.isEmpty ? null : playlistList.first.id;
    downloadCoordinator.replaceState(
      tasks: snapshot.downloadTasks,
      localItems: snapshot.localMediaItems,
    );
    favoritesOverrideRegistry.replaceWith(snapshot.favoritesOverrides);
    favoriteLikedAtLedger.replaceAll(snapshot.favoriteLikedAtLedger.entries);
    _favoriteProviderSnapshots
      ..clear()
      ..addEntries(
        snapshot.favoriteProviderSnapshots.map(
          (item) => MapEntry(item.providerId, item),
        ),
      );
    _favoriteProviderStates
      ..clear()
      ..addEntries(
        snapshot.favoriteProviderStates.map(
          (item) => MapEntry(item.providerId, item),
        ),
      );
    _unifiedFavoritesCache = snapshot.unifiedFavoritesCache;
    _lastFavoritesData = snapshot.unifiedFavoritesCache?.tracks;
    if (_lastFavoritesData?.isEmpty ?? false) {
      _lastFavoritesData = null;
    }
    for (final track in _lastFavoritesData ?? const <UnifiedFavoriteTrack>[]) {
      _rememberTracks(track.variants);
    }
    playbackCoordinator.quality = snapshot.playbackQuality;
    _volume = snapshot.volume.clamp(0.0, 1.0).toDouble();
    await _audioPlayer.setVolume(_volume);
    _playingTrackId = null;
    _playbackRequested = false;
    await _audioPlayer.stop();
    _rememberQueue = snapshot.playbackPreferences.rememberQueue;
    _restorePlaybackState = snapshot.playbackPreferences.restorePlaybackState &&
        snapshot.playbackPreferences.rememberQueue;
    _restorePlaybackQueue(snapshot.playbackQueue);
    _downloadDirectory = _normalizeConfiguredDirectory(
      snapshot.downloadDirectory,
    );
    _favoritesVersion++;
    await persistNow();
    notifyListeners();
  }

  Future<void> refreshFavoritesAfterRestore() async {
    try {
      await loadAllFavorites();
    } finally {
      _favoritesVersion++;
      notifyListeners();
    }
  }

  Future<void> persistNow() async {
    await snapshotStore?.write(toSnapshot());
  }

  Future<void> setRememberQueue(bool value) async {
    _rememberQueue = value;
    if (!value) {
      _restorePlaybackState = false;
      _pendingRestorePosition = null;
    }
    await persistNow();
    notifyListeners();
  }

  Future<void> setRestorePlaybackState(bool value) async {
    _restorePlaybackState = value && _rememberQueue;
    await persistNow();
    notifyListeners();
  }

  PlaybackQueueSnapshot? _currentPlaybackQueueSnapshot() {
    final queueState = playbackCoordinator.queueState;
    if (queueState.entries.isEmpty) return null;
    return PlaybackQueueSnapshot(
      entries: [
        for (final entry in queueState.entries)
          PlaybackQueueEntrySnapshot(
            track: entry.track,
            queuedAt: entry.queuedAt,
          ),
      ],
      currentIndex: queueState.currentIndex,
      position: _restorePlaybackState
          ? _playbackPositionForSnapshot()
          : Duration.zero,
      shuffleEnabled: _shuffleEnabled,
      repeatMode: _repeatMode.name,
    );
  }

  Duration _playbackPositionForSnapshot() {
    final pending = _pendingRestorePosition;
    if (pending != null) return pending;
    final livePosition = _audioPlayer.position;
    if (livePosition > Duration.zero) return livePosition;
    return _lastKnownPlaybackPosition;
  }

  void _restorePlaybackQueue(PlaybackQueueSnapshot? snapshot) {
    _pendingRestorePosition = null;
    _lastKnownPlaybackPosition = Duration.zero;
    if (!_rememberQueue || snapshot == null || snapshot.entries.isEmpty) {
      playbackCoordinator.restoreQueue(PlaybackQueueState.empty());
      _shuffleEnabled = false;
      _repeatMode = PlaybackRepeatMode.off;
      return;
    }

    final entries = [
      for (final entry in snapshot.entries)
        PlaybackQueueEntry(track: entry.track, queuedAt: entry.queuedAt),
    ];
    final currentIndex =
        snapshot.currentIndex >= 0 && snapshot.currentIndex < entries.length
            ? snapshot.currentIndex
            : 0;
    playbackCoordinator.restoreQueue(
      PlaybackQueueState(
        entries: List.unmodifiable(entries),
        currentIndex: currentIndex,
      ),
    );
    _rememberTracks(entries.map((entry) => entry.track));
    _shuffleEnabled = snapshot.shuffleEnabled;
    _repeatMode = _playbackRepeatModeFromName(snapshot.repeatMode);
    if (_restorePlaybackState && snapshot.position > Duration.zero) {
      _pendingRestorePosition = snapshot.position;
      _lastKnownPlaybackPosition = snapshot.position;
    }
  }

  PlaybackRepeatMode _playbackRepeatModeFromName(String value) {
    for (final mode in PlaybackRepeatMode.values) {
      if (mode.name == value) return mode;
    }
    return PlaybackRepeatMode.off;
  }

  void _clearPendingRestorePosition() {
    _pendingRestorePosition = null;
    _lastKnownPlaybackPosition = Duration.zero;
  }

  void _persistPlaybackStateSoon() {
    if (_rememberQueue) {
      _persistSoon();
    }
  }

  Future<List<ProviderSearchResults>> search(String query) {
    if (query.trim().isEmpty) {
      return Future.value(const []);
    }
    return searchService.searchEverywhere(registry: registry, query: query);
  }

  SourceTrack? sourceTrackByRef(ProviderTrackRef ref) {
    final cached = _trackCache[ref];
    if (cached != null) return cached;
    final provider = providers[ref.providerId];
    return provider?.trackByRef(ref);
  }

  String? get customDownloadDirectory => _downloadDirectory;

  Future<String> downloadDirectoryPath() async {
    final directory = await _downloadRootDirectory();
    return directory.path;
  }

  Future<void> setDownloadDirectory(String? directory) async {
    final next = _normalizeConfiguredDirectory(directory);
    if (next != null) {
      await Directory(next).create(recursive: true);
    }
    _downloadDirectory = next;
    _persistSoon();
    notifyListeners();
  }

  Future<void> revealDownloadDirectory() async {
    final directory = await _downloadRootDirectory();
    await directory.create(recursive: true);
    if (Platform.isWindows) {
      await Process.start('explorer.exe', [directory.path]);
    } else if (Platform.isMacOS) {
      await Process.start('open', [directory.path]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [directory.path]);
    }
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
    _rememberTrack(track);
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

  Future<bool> toggleFavorite({
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

    // Optimistically update the queue track so the UI (e.g. player bar heart)
    // reflects the new state immediately.
    playbackCoordinator.updateFavoriteState(track.ref, liked);

    if (liked) {
      // Record app-action liked-at timestamp (precise).
      favoriteLikedAtLedger.record(
        track.ref,
        LikedAtMetadata(
          likedAt: DateTime.now().toUtc(),
          source: LikedAtMetadata.sourceAppAction,
          precision: LikedAtMetadata.precisionExact,
        ),
      );
    } else {
      // Remove liked-at metadata when unliking.
      favoriteLikedAtLedger.remove(track.ref);
    }
    _persistSoon();
    _favoritesVersion++;
    notifyListeners();
    return liked;
  }

  void setProviderEnabled(ProviderId providerId, bool enabled) {
    registry.setEnabled(providerId, enabled);
    _rebuildUnifiedFavoritesCache();
    _persistSoon();
    _favoritesVersion++;
    notifyListeners();
  }

  void notifyFavoritesChanged() {
    _favoritesVersion++;
    notifyListeners();
  }

  void toggleProviderAuthentication(ProviderId providerId) {
    if (providerId == neteaseProviderId) {
      clearNeteaseCredentials();
      return;
    }
    if (providerId == qqMusicProviderId) {
      clearQqMusicCredentials();
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

  Future<NeteaseQrLoginSession> createNeteaseQrLoginSession() {
    return NeteaseMusicProvider().createQrLoginSession();
  }

  Future<NeteaseQrLoginResult> checkNeteaseQrLoginSession(
    NeteaseQrLoginSession session,
  ) async {
    final result = await NeteaseMusicProvider().checkQrLoginSession(session);
    final credentials = result.credentials;
    if (credentials != null && credentials.hasCookie) {
      await saveNeteaseCredentials(
        cookie: credentials.cookie,
        userId: credentials.userId,
      );
    }
    return result;
  }

  Future<void> clearNeteaseCredentials() async {
    await neteaseSessionStore?.clear();
    _neteaseCredentials = null;
    _replaceNeteaseProvider(null);
    _discardFavoriteProvider(neteaseProviderId);
    _favoritesVersion++;
    notifyListeners();
  }

  Future<KugouQrLoginSession> createKugouQrLoginSession() {
    final provider = registry.find(kugouProviderId) as KugouMusicProvider;
    return provider.createQrLoginSession();
  }

  Future<KugouQrLoginResult> checkKugouQrLoginSession(
    KugouQrLoginSession session,
  ) async {
    final provider = registry.find(kugouProviderId) as KugouMusicProvider;
    final result = await provider.checkQrLoginSession(session);
    if (result.status == KugouQrLoginStatus.authorized) {
      _favoritesVersion++;
      notifyListeners();
    }
    return result;
  }

  Future<void> saveKugouCookieSession({
    required String cookie,
    String? userId,
  }) async {
    final session = _kugouSessionFromCookie(cookie: cookie, userId: userId);
    await kugouSessionStore?.write(session);
    _replaceKugouProvider(session);
    _favoritesVersion++;
    notifyListeners();
  }

  KugouSession _kugouSessionFromCookie({
    required String cookie,
    String? userId,
  }) {
    final cookies = _parseCookieHeader(cookie);
    final normalized = {
      for (final entry in cookies.entries) entry.key.toLowerCase(): entry.value,
    };
    String? value(List<String> keys) {
      for (final key in keys) {
        final candidate = normalized[key.toLowerCase()]?.trim();
        if (candidate != null && candidate.isNotEmpty) {
          return candidate;
        }
      }
      return null;
    }

    String decodeUnicodeEscape(String input) {
      final regex = RegExp(r'%u([0-9a-fA-F]{4})');
      return input.replaceAllMapped(regex, (match) {
        final hex = match.group(1)!;
        final code = int.parse(hex, radix: 16);
        return String.fromCharCode(code);
      });
    }

    String? nestedCookieValue(String cookieKey, List<String> nestedKeys) {
      final raw = value([cookieKey]);
      if (raw == null || raw.isEmpty) return null;
      final parts = raw.replaceAll('&amp;', '&').split('&');
      final pairs = <String, String>{};
      for (final part in parts) {
        final eqIdx = part.indexOf('=');
        if (eqIdx == -1) {
          pairs[part.trim()] = '';
        } else {
          final k = part.substring(0, eqIdx).trim();
          final v = part.substring(eqIdx + 1).trim();
          pairs[k] = v;
        }
      }
      for (final nestedKey in nestedKeys) {
        final candidate = pairs[nestedKey];
        if (candidate != null && candidate.isNotEmpty) {
          try {
            return Uri.decodeQueryComponent(candidate);
          } catch (_) {
            return decodeUnicodeEscape(candidate);
          }
        }
      }
      return null;
    }

    final resolvedUserId = userId?.trim().isNotEmpty == true
        ? userId!.trim()
        : value(['userid', 'user_id', 'kg_uid', 'kugouid', 'kugooid']) ??
            nestedCookieValue('kugoo', ['KugooID', 'userid']);

    var token = value(['KuGooToken', 'kugou_token', 'token']) ??
        nestedCookieValue('kugoo', ['KugooPwd', 'token']);

    if (token == null) {
      final rawKugoo = value(['kugoo']);
      if (rawKugoo != null && rawKugoo.isNotEmpty) {
        final firstSegment = rawKugoo.split('&').first;
        if (firstSegment.length == 40 || firstSegment.length == 32) {
          token = firstSegment;
        }
      }
    }

    final mid = value(['kg_mid', 'mid', 'kg_mid_temp']);
    final dfid = value(['kg_dfid', 'dfid', 'kg_dfid_collect']);

    if (resolvedUserId == null ||
        token == null ||
        mid == null ||
        dfid == null) {
      throw ArgumentError.value(
        cookie,
        'cookie',
        'Kugou cookie must include KugooID/userid, KuGoo/KuGooToken, kg_mid/mid, and kg_dfid/dfid.',
      );
    }

    return KugouSession(
      userId: resolvedUserId,
      token: token,
      deviceId: value(['device_id', 'kg_deviceid']) ?? mid,
      mid: mid,
      deviceFingerprint: dfid,
      vipToken: value(['vip_token', 'viptoken']),
      vipType: value(['vip_type', 'viptype']),
      refreshMetadata: {'cookie': cookie.trim()},
      updatedAt: DateTime.now(),
    );
  }

  Map<String, String> _parseCookieHeader(String cookie) {
    final result = <String, String>{};
    for (final part in cookie.split(';')) {
      final index = part.indexOf('=');
      if (index <= 0) continue;
      final key = part.substring(0, index).trim();
      final value = part.substring(index + 1).trim();
      if (key.isNotEmpty && value.isNotEmpty) {
        result[key] = value;
      }
    }
    return result;
  }

  Future<void> saveQqMusicCredentials(QqMusicCredentials credentials) async {
    if (!credentials.hasCookie) {
      throw ArgumentError.value(
        credentials.cookie,
        'credentials.cookie',
        'QQ Music cookie must not be empty.',
      );
    }
    final cookieProblem = _validateQqMusicCookie(credentials.cookie);
    if (cookieProblem != null) {
      throw ArgumentError.value(
        credentials.cookie,
        'credentials.cookie',
        cookieProblem,
      );
    }
    await qqMusicSessionStore?.write(credentials);
    _qqMusicCredentials = credentials;
    // Keep QQ liked-at records across cookie refreshes. The registry keys by
    // stable QQ song identity, so a re-import can recover the previous time.
    _replaceQqMusicProvider(credentials);
    notifyListeners();
  }

  Future<void> clearQqMusicCredentials() async {
    await qqMusicSessionStore?.clear();
    _qqMusicCredentials = null;
    _replaceQqMusicProvider(null);
    _discardFavoriteProvider(qqMusicProviderId);
    _favoritesVersion++;
    notifyListeners();
  }

  String? _validateQqMusicCookie(String cookie) {
    final hasUin =
        RegExp(r'(^|;\s*)uin=o?\d+', caseSensitive: false).hasMatch(cookie);
    final hasAuthKey = RegExp(
      r'(^|;\s*)(qqmusic_key|qm_keyst|p_skey)=\S+',
      caseSensitive: false,
    ).hasMatch(cookie);
    if (!hasUin || !hasAuthKey) {
      return 'QQ Music cookie must include uin and qqmusic_key/qm_keyst.';
    }
    return null;
  }

  Future<QqMusicQrLoginSession> createQqMusicQrLoginSession(
    QqMusicQrLoginMode mode,
  ) {
    return QqMusicProvider().createQrLoginSession(mode);
  }

  Future<QqMusicQrLoginResult> checkQqMusicQrLoginSession(
    QqMusicQrLoginSession session,
  ) async {
    final result = await QqMusicProvider().checkQrLoginSession(session);
    final credentials = result.credentials;
    if (credentials != null && credentials.hasCookie) {
      await saveQqMusicCredentials(credentials);
    }
    return result;
  }

  Future<void> playTrack(SourceTrack track) async {
    if (!track.isPlayable) return;

    _rememberTrack(track);
    _clearPendingRestorePosition();
    playbackCoordinator.setQueue([track]);
    await playbackCoordinator.selectTrack(track.ref);
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    _persistPlaybackStateSoon();
    notifyListeners();
  }

  Future<void> playOrToggleTrack(SourceTrack track) async {
    if (queue.current?.track.ref == track.ref) {
      await togglePlayPause();
      return;
    }
    await playTrack(track);
  }

  Future<void> playTracks(List<SourceTrack> tracks) async {
    final playableTracks =
        tracks.where((track) => track.isPlayable).toList(growable: false);
    if (playableTracks.isEmpty) return;

    _rememberTracks(playableTracks);
    _clearPendingRestorePosition();
    playbackCoordinator.setQueue(playableTracks);
    await playbackCoordinator.selectTrack(playableTracks.first.ref);
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    _persistPlaybackStateSoon();
    notifyListeners();
  }

  Future<void> playTracksFrom(
    List<SourceTrack> tracks,
    ProviderTrackRef selectedRef,
  ) async {
    final playableTracks =
        tracks.where((track) => track.isPlayable).toList(growable: false);
    if (playableTracks.isEmpty) return;

    final selected = playableTracks.any((track) => track.ref == selectedRef)
        ? selectedRef
        : playableTracks.first.ref;
    _rememberTracks(playableTracks);
    _clearPendingRestorePosition();
    playbackCoordinator.setQueue(playableTracks);
    await playbackCoordinator.selectTrack(selected);
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    _persistPlaybackStateSoon();
    notifyListeners();
  }

  Future<void> playUnifiedTrack(UnifiedFavoriteTrack track) async {
    final playableVariants = track.variants
        .where((variant) => variant.isPlayable)
        .toList(growable: false);
    if (playableVariants.isEmpty) return;

    _rememberTracks(playableVariants);
    _clearPendingRestorePosition();
    playbackCoordinator.setQueue(playableVariants);
    if (playableVariants.isNotEmpty) {
      await playbackCoordinator.selectTrack(playableVariants.first.ref);
    }
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    _persistPlaybackStateSoon();
    notifyListeners();
  }

  Future<void> playOrToggleUnifiedTrack(UnifiedFavoriteTrack track) async {
    final currentRef = queue.current?.track.ref;
    if (currentRef != null &&
        track.variants.any((variant) => variant.ref == currentRef)) {
      await togglePlayPause();
      return;
    }
    await playUnifiedTrack(track);
  }

  void enqueueTrack(SourceTrack track) {
    _rememberTrack(track);
    playbackCoordinator.enqueue(track);
    _persistPlaybackStateSoon();
    notifyListeners();
  }

  Future<void> removeQueueEntry(int index) async {
    final queueState = queue;
    if (index < 0 || index >= queueState.entries.length) return;

    final wasCurrent = index == queueState.currentIndex;
    final wasPlaying = _audioPlayer.playing || _playbackRequested;
    playbackCoordinator.removeAt(index);

    if (!wasCurrent) {
      _persistPlaybackStateSoon();
      notifyListeners();
      return;
    }

    _playingTrackId = null;
    if (queue.current == null) {
      _clearPendingRestorePosition();
      _playbackRequested = false;
      await _audioPlayer.stop();
      _persistPlaybackStateSoon();
      notifyListeners();
      return;
    }

    if (wasPlaying) {
      await _syncNativePlayback(playWhenReady: true);
    } else {
      await _audioPlayer.stop();
    }
    _persistPlaybackStateSoon();
    notifyListeners();
  }

  void clearQueue() {
    _clearPendingRestorePosition();
    playbackCoordinator.setQueue([]);
    _playingTrackId = null;
    _playbackRequested = false;
    unawaited(_audioPlayer.stop());
    _persistPlaybackStateSoon();
    notifyListeners();
  }

  Future<void> selectTrackInQueue(ProviderTrackRef ref) async {
    if (queue.current?.track.ref != ref) {
      _clearPendingRestorePosition();
    }
    await playbackCoordinator.selectTrack(ref);
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    _persistPlaybackStateSoon();
    notifyListeners();
  }

  Future<void> playOrToggleQueueTrack(ProviderTrackRef ref) async {
    if (queue.current?.track.ref == ref) {
      await togglePlayPause();
      return;
    }
    await selectTrackInQueue(ref);
  }

  Future<void> queueNext({bool automatic = false}) async {
    final queueState = queue;
    if (queueState.entries.isEmpty) return;

    if (automatic && _repeatMode == PlaybackRepeatMode.one) {
      await _restartCurrentTrack();
      return;
    }

    final nextRef = _nextTrackRef(queueState);
    if (nextRef == null) {
      if (automatic) {
        _playbackRequested = false;
        notifyListeners();
      }
      return;
    }

    await playbackCoordinator.selectTrack(nextRef);
    _clearPendingRestorePosition();
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    _persistPlaybackStateSoon();
    notifyListeners();
  }

  Future<void> queuePrevious() async {
    final queueState = queue;
    if (queueState.entries.isEmpty) return;

    ProviderTrackRef? previousRef;
    if (queueState.currentIndex > 0) {
      previousRef = queueState.entries[queueState.currentIndex - 1].track.ref;
    } else if (_repeatMode == PlaybackRepeatMode.all &&
        queueState.entries.length > 1) {
      previousRef = queueState.entries.last.track.ref;
    }
    if (previousRef == null) return;

    await playbackCoordinator.selectTrack(previousRef);
    _clearPendingRestorePosition();
    _playingTrackId = null; // Force new playback
    await _syncNativePlayback(playWhenReady: true);
    _persistPlaybackStateSoon();
    notifyListeners();
  }

  void addDownloadTask(SourceTrack track,
      {AudioQuality quality = AudioQuality.standard}) {
    _rememberTrack(track);
    downloadCoordinator.addTask(track, quality: quality);
    _persistSoon();
    notifyListeners();
  }

  bool canDownloadTrack(SourceTrack track) {
    if (!track.isDownloadable) return false;
    return registry
            .entryOf(track.ref.providerId)
            ?.descriptor
            .supports(ProviderCapability.resolveDownload) ??
        false;
  }

  Future<DownloadStatus?> downloadTrack(
    SourceTrack track, {
    AudioQuality quality = AudioQuality.standard,
  }) async {
    if (!canDownloadTrack(track)) return null;
    _rememberTrack(track);

    final existing = downloadCoordinator.getTask(track.ref);
    if (downloadCoordinator.isAvailableLocally(track.ref)) {
      return DownloadStatus.completed;
    }
    if (existing != null &&
        (existing.status == DownloadStatus.resolving ||
            existing.status == DownloadStatus.downloading)) {
      return existing.status;
    }

    if (existing == null ||
        existing.status == DownloadStatus.failed ||
        existing.status == DownloadStatus.cancelled ||
        existing.status == DownloadStatus.completed) {
      downloadCoordinator.addTask(track, quality: quality);
      _persistSoon();
      notifyListeners();
    }

    await startDownload(track.ref);
    return downloadCoordinator.getTask(track.ref)?.status;
  }

  Future<void> startDownload(ProviderTrackRef ref) async {
    await downloadCoordinator.startTask(ref);
    _persistSoon();
    notifyListeners();
    await _materializeDownload(ref);
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
    downloadCoordinator.removeTask(ref);
    _persistSoon();
    notifyListeners();
  }

  void removeLocalMedia(ProviderTrackRef ref) {
    final localItem = downloadCoordinator.getLocalItem(ref);
    final filePath = localItem?.filePath;
    if (filePath != null && !filePath.startsWith('local://')) {
      unawaited(
        File(filePath).delete().then<void>((_) {}).catchError((Object _) {}),
      );
    }
    downloadCoordinator.removeLocalItem(ref);
    _persistSoon();
    notifyListeners();
  }

  Future<void> redownloadLocalMedia(ProviderTrackRef ref,
      {AudioQuality quality = AudioQuality.standard}) {
    final track = sourceTrackByRef(ref);
    if (track == null) {
      removeLocalMedia(ref);
      return Future<void>.value();
    }
    downloadCoordinator.removeLocalItem(ref);
    downloadCoordinator.addTask(track, quality: quality);
    _persistSoon();
    notifyListeners();
    return startDownload(ref);
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
      _startAudioPlayer();
    } else {
      await refreshPlaybackTicket();
    }
    notifyListeners();
  }

  Future<void> retryCurrentPlayback() async {
    _playbackIssue = null;
    _playingTrackId = null;
    await playbackCoordinator.refreshCurrentTicketIfNeeded(force: true);
    await _syncNativePlayback(playWhenReady: true);
    notifyListeners();
  }

  void dismissPlaybackIssue() {
    if (_playbackIssue == null) return;
    _playbackIssue = null;
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    _pendingRestorePosition = null;
    _lastKnownPlaybackPosition = position;
    await _audioPlayer.seek(position);
    _persistPlaybackStateSoon();
  }

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0.0, 1.0).toDouble();
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
    _persistSoon();
  }

  Future<void> setPlaybackQuality(AudioQuality quality) async {
    playbackCoordinator.quality = quality;
    _playingTrackId = null;
    await _syncNativePlayback(playWhenReady: isPlaybackActive);
    _persistSoon();
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffleEnabled = !_shuffleEnabled;
    _persistPlaybackStateSoon();
    notifyListeners();
  }

  void cycleRepeatMode() {
    _repeatMode = switch (_repeatMode) {
      PlaybackRepeatMode.off => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.off,
    };
    _persistPlaybackStateSoon();
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
      final error = playbackCoordinator.currentError;
      if (current != null && error != null) {
        _setPlaybackIssue(
          track: current,
          title: '播放链接解析失败',
          message: _playbackErrorMessage(error),
        );
        _playbackRequested = false;
      }
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
        if (!_isSupportedPlaybackUri(currentTicket.mediaUri)) {
          throw FormatException(
            'Unsupported playback URI scheme: ${currentTicket.mediaUri.scheme}',
            url,
          );
        }
        debugPrint('AUDIO: playing "${current.title}"');
        await _audioPlayer.stop();
        final nativeWindow =
            await _buildNativePlaybackWindow(queue, current, currentTicket);
        _nativeAudioSourceRefs = [
          for (final source in nativeWindow.sources) source.ref,
        ];
        final audioSource = nativeWindow.sources.length == 1
            ? nativeWindow.sources.single.toAudioSource()
            : ConcatenatingAudioSource(
                useLazyPreparation: true,
                children: [
                  for (final source in nativeWindow.sources)
                    source.toAudioSource(),
                ],
              );
        _updatingNativeAudioSource = true;
        await _audioPlayer.setAudioSource(
          audioSource,
          initialIndex: nativeWindow.currentIndex,
        );
        final restorePosition = _pendingRestorePosition;
        if (_restorePlaybackState &&
            restorePosition != null &&
            restorePosition > Duration.zero) {
          await _audioPlayer.seek(restorePosition);
          _lastKnownPlaybackPosition = restorePosition;
        }
        _pendingRestorePosition = null;
        _updatingNativeAudioSource = false;
        _playbackIssue = null;
        await notificationPermissionBridge.requestPostNotifications();
        _startAudioPlayer();
      } catch (e) {
        _updatingNativeAudioSource = false;
        debugPrint('Audio Error: $e');
        _playingTrackId = null;
        _playbackRequested = false;
        _setPlaybackIssue(
          track: current,
          title: '播放启动失败',
          message: _playbackErrorMessage(e),
        );
      }
    }
  }

  Future<void> _handleNativeAudioIndexChange(ProviderTrackRef ref) async {
    _handlingNativeAudioIndexChange = true;
    try {
      await playbackCoordinator.selectTrack(ref);
      _clearPendingRestorePosition();
      _playingTrackId = null;
      await _syncNativePlayback(playWhenReady: true);
      _persistPlaybackStateSoon();
      notifyListeners();
    } finally {
      _handlingNativeAudioIndexChange = false;
    }
  }

  Future<_NativePlaybackWindow> _buildNativePlaybackWindow(
    PlaybackQueueState queueState,
    SourceTrack current,
    PlaybackTicket currentTicket,
  ) async {
    final sources = <_NativePlaybackSource>[];
    final previous = _previousTrackForNotification(queueState);
    if (previous != null) {
      final ticket = await _resolvePlaybackTicketForTrack(previous);
      if (ticket != null) {
        sources.add(_NativePlaybackSource(track: previous, ticket: ticket));
      }
    }

    final currentIndex = sources.length;
    sources.add(_NativePlaybackSource(track: current, ticket: currentTicket));

    final next = _nextTrackForNotification(queueState);
    if (next != null) {
      final prefetched = playbackCoordinator.nextTicket;
      final ticket = prefetched != null &&
              prefetched.trackRef == next.ref &&
              !prefetched.isExpired
          ? prefetched
          : await _resolvePlaybackTicketForTrack(next);
      if (ticket != null) {
        sources.add(_NativePlaybackSource(track: next, ticket: ticket));
      }
    }

    return _NativePlaybackWindow(
      sources: sources,
      currentIndex: currentIndex,
    );
  }

  Future<PlaybackTicket?> _resolvePlaybackTicketForTrack(
    SourceTrack track,
  ) async {
    try {
      final entry = registry.entryOf(track.ref.providerId);
      if (entry == null || !entry.isEnabled) return null;
      final provider = entry.provider;
      if (!provider.descriptor.supports(ProviderCapability.resolvePlayback)) {
        return null;
      }
      return provider.createPlaybackTicket(
        track: track.ref,
        quality: playbackCoordinator.quality,
      );
    } catch (_) {
      return null;
    }
  }

  SourceTrack? _previousTrackForNotification(PlaybackQueueState queueState) {
    if (queueState.entries.isEmpty || queueState.currentIndex < 0) {
      return null;
    }
    if (queueState.currentIndex > 0) {
      return queueState.entries[queueState.currentIndex - 1].track;
    }
    if (_repeatMode == PlaybackRepeatMode.all &&
        queueState.entries.length > 1) {
      return queueState.entries.last.track;
    }
    return null;
  }

  SourceTrack? _nextTrackForNotification(PlaybackQueueState queueState) {
    final ref = _nextTrackRef(queueState);
    if (ref == null) return null;
    for (final entry in queueState.entries) {
      if (entry.track.ref == ref) return entry.track;
    }
    return null;
  }

  ProviderTrackRef? _nextTrackRef(PlaybackQueueState queueState) {
    if (queueState.entries.isEmpty || queueState.currentIndex < 0) {
      return null;
    }
    if (_shuffleEnabled && queueState.entries.length > 1) {
      var nextIndex = queueState.currentIndex;
      while (nextIndex == queueState.currentIndex) {
        nextIndex = _random.nextInt(queueState.entries.length);
      }
      return queueState.entries[nextIndex].track.ref;
    }

    final nextIndex = queueState.currentIndex + 1;
    if (nextIndex < queueState.entries.length) {
      return queueState.entries[nextIndex].track.ref;
    }
    if (_repeatMode == PlaybackRepeatMode.all &&
        queueState.entries.length > 1) {
      return queueState.entries.first.track.ref;
    }
    return null;
  }

  Future<void> _restartCurrentTrack() async {
    await _audioPlayer.seek(Duration.zero);
    _playbackRequested = true;
    _startAudioPlayer();
    notifyListeners();
  }

  void _startAudioPlayer() {
    final current = queue.current?.track;
    unawaited(
      _audioPlayer.play().catchError((Object error, StackTrace stackTrace) {
        debugPrint('Audio Error: $error');
        _playingTrackId = null;
        _playbackRequested = false;
        if (current != null) {
          _setPlaybackIssue(
            track: current,
            title: '播放失败',
            message: _playbackErrorMessage(error),
          );
        }
        notifyListeners();
      }),
    );
  }

  void _setPlaybackIssue({
    required SourceTrack track,
    required String title,
    required String message,
  }) {
    _playbackIssue = PlaybackIssue(
      trackRef: track.ref,
      title: title,
      message: message,
      occurredAt: DateTime.now().toUtc(),
    );
  }

  bool _isSupportedPlaybackUri(Uri uri) {
    return uri.isScheme('http') ||
        uri.isScheme('https') ||
        uri.isScheme('file') ||
        uri.isScheme('content');
  }

  String _playbackErrorMessage(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty) {
      return '请检查网络或稍后重试。';
    }
    if (text.length > 140) {
      return '${text.substring(0, 140)}...';
    }
    return text;
  }

  Future<void> _materializeDownload(ProviderTrackRef ref) async {
    final task = downloadCoordinator.getTask(ref);
    final ticket = task?.ticket;
    if (task == null ||
        task.status != DownloadStatus.downloading ||
        ticket == null) {
      return;
    }

    final uri = ticket.mediaUri;
    if (!uri.isScheme('http') && !uri.isScheme('https')) {
      downloadCoordinator.failTask(
        ref,
        'Unsupported download URI scheme: ${uri.scheme}',
      );
      return;
    }

    File? tempFile;
    IOSink? sink;
    final client = HttpClient();
    try {
      final target = await _downloadFileFor(task.track, ticket);
      await target.parent.create(recursive: true);
      tempFile = File('${target.path}.part');
      final request = await client.getUrl(uri);
      ticket.headers.forEach(request.headers.add);
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<List<int>>(<int>[]);
        throw HttpException(
          'Download failed with HTTP ${response.statusCode}.',
          uri: uri,
        );
      }

      sink = tempFile.openWrite();
      var received = 0;
      final total = response.contentLength;
      await for (final chunk in response) {
        sink.add(chunk);
        received += chunk.length.toInt();
        if (total > 0) {
          downloadCoordinator.updateProgress(ref, received / total);
          notifyListeners();
        }
      }
      await sink.close();
      sink = null;
      if (await target.exists()) {
        await target.delete();
      }
      await tempFile.rename(target.path);
      await _embedDownloadedMetadata(target, task.track, ticket);
      final fileSize = await target.length();
      downloadCoordinator.completeTask(
        ref: ref,
        filePath: target.path,
        fileSize: fileSize,
      );
    } catch (error) {
      downloadCoordinator.failTask(ref, error);
      try {
        await sink?.close();
        if (tempFile != null && await tempFile.exists()) {
          await tempFile.delete();
        }
      } on FileSystemException {
        // Best-effort cleanup only.
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<File> _downloadFileFor(
    SourceTrack track,
    DownloadTicket ticket,
  ) async {
    final root = await _downloadRootDirectory();
    final providerDir =
        Directory(path.join(root.path, track.ref.providerId.value));
    final extension = _downloadExtension(ticket);
    final fileName = '${_downloadFileBaseName(track)}.$extension';
    return _uniqueDownloadFile(File(path.join(providerDir.path, fileName)));
  }

  Future<Directory> _downloadRootDirectory() async {
    final configured = _downloadDirectory;
    if (configured != null && configured.trim().isNotEmpty) {
      return Directory(configured);
    }

    final override = Platform.environment[_dataDirOverrideEnv];
    if (override != null && override.trim().isNotEmpty) {
      return Directory(path.join(override, 'downloads'));
    }

    if (Platform.isAndroid) {
      try {
        final androidPath = await _androidStorageChannel.invokeMethod<String>(
          'getApplicationSupportDirectory',
        );
        if (androidPath != null && androidPath.trim().isNotEmpty) {
          return Directory(path.join(androidPath, 'melo_union', 'downloads'));
        }
      } on MissingPluginException {
        // Unit tests and non-Flutter VM runs do not have the Android host channel.
      } on PlatformException {
        // Fall through to the generic writable location.
      }
    }

    return Directory(
        path.join(_defaultSupportRoot().path, 'MeloUnion', 'downloads'));
  }

  Directory _defaultSupportRoot() {
    final environment = Platform.environment;
    if (Platform.isWindows) {
      return Directory(
        environment['APPDATA'] ??
            environment['LOCALAPPDATA'] ??
            Directory.systemTemp.path,
      );
    }
    if (Platform.isMacOS) {
      final home = environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory(path.join(home, 'Library', 'Application Support'));
      }
    }
    if (Platform.isLinux) {
      final xdgDataHome = environment['XDG_DATA_HOME'];
      if (xdgDataHome != null && xdgDataHome.isNotEmpty) {
        return Directory(xdgDataHome);
      }
      final home = environment['HOME'];
      if (home != null && home.isNotEmpty) {
        return Directory(path.join(home, '.local', 'share'));
      }
    }
    return Directory.systemTemp;
  }

  String _downloadExtension(DownloadTicket ticket) {
    final raw = ticket.fileExtension?.trim().toLowerCase() ?? '';
    final cleaned = raw.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (cleaned.isNotEmpty && cleaned.length <= 8) {
      return cleaned;
    }
    final pathExtension = path.extension(ticket.mediaUri.path);
    if (pathExtension.isNotEmpty) {
      return pathExtension.replaceFirst('.', '').toLowerCase();
    }
    return 'mp3';
  }

  String _safeFileSegment(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]+'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'^[. ]+|[. ]+$'), '');
    if (cleaned.isEmpty) return 'track';
    return cleaned.length <= 140 ? cleaned : cleaned.substring(0, 140).trim();
  }

  String _downloadFileBaseName(SourceTrack track) {
    final artists = track.artists.isEmpty ? '未知歌手' : track.artists.join('／');
    return _safeFileSegment('$artists - ${track.title}');
  }

  static String? _normalizeConfiguredDirectory(String? directory) {
    final trimmed = directory?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return path.normalize(path.absolute(trimmed));
  }

  Future<File> _uniqueDownloadFile(File desired) async {
    if (!await desired.exists()) return desired;
    final directory = desired.parent.path;
    final extension = path.extension(desired.path);
    final baseName = path.basenameWithoutExtension(desired.path);
    for (var i = 2; i < 1000; i++) {
      final candidate = File(path.join(directory, '$baseName ($i)$extension'));
      if (!await candidate.exists()) return candidate;
    }
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return File(path.join(directory, '$baseName ($timestamp)$extension'));
  }

  Future<void> _embedDownloadedMetadata(
    File file,
    SourceTrack track,
    DownloadTicket ticket,
  ) async {
    final extension = _downloadExtension(ticket).toLowerCase();
    if (extension != 'mp3' && extension != 'flac') return;

    try {
      final lyrics = await _downloadLyricsFor(track);
      final artwork = await _downloadArtwork(track.artwork);
      if (extension == 'mp3') {
        await _writeId3v24Tag(
          file,
          track: track,
          lyrics: lyrics,
          artworkBytes: artwork?.bytes,
          artworkMime: artwork?.mimeType,
        );
      } else if (extension == 'flac') {
        await _writeFlacMetadata(
          file,
          track: track,
          lyrics: lyrics,
          artworkBytes: artwork?.bytes,
          artworkMime: artwork?.mimeType,
        );
      }
    } catch (error) {
      debugPrint('Failed to embed download metadata: $error');
    }
  }

  Future<String?> _downloadLyricsFor(SourceTrack track) async {
    final entry = registry.entryOf(track.ref.providerId);
    if (entry == null ||
        !entry.isEnabled ||
        !entry.descriptor.supports(ProviderCapability.lyrics)) {
      return null;
    }
    try {
      final lyrics = await entry.provider.getLyrics(track.ref);
      final cleaned = lyrics?.trim();
      return cleaned == null || cleaned.isEmpty ? null : cleaned;
    } catch (_) {
      return null;
    }
  }

  Future<({Uint8List bytes, String mimeType})?> _downloadArtwork(
    Uri? artwork,
  ) async {
    if (artwork == null ||
        (!artwork.isScheme('http') && !artwork.isScheme('https'))) {
      return null;
    }
    final client = HttpClient();
    try {
      final request = await client.getUrl(artwork);
      request.headers.set(HttpHeaders.userAgentHeader, 'MeloUnion/1.0');
      final response = await request.close();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<List<int>>(<int>[]);
        return null;
      }
      final builder = BytesBuilder(copy: false);
      var total = 0;
      await for (final chunk in response) {
        total += chunk.length;
        if (total > 8 * 1024 * 1024) return null;
        builder.add(chunk);
      }
      final bytes = builder.takeBytes();
      if (bytes.isEmpty) return null;
      final contentType = response.headers.contentType?.mimeType;
      return (
        bytes: bytes,
        mimeType: _artworkMimeType(contentType, artwork, bytes),
      );
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  String _artworkMimeType(String? contentType, Uri uri, Uint8List bytes) {
    if (contentType != null && contentType.startsWith('image/')) {
      return contentType;
    }
    final extension = path.extension(uri.path).toLowerCase();
    if (extension == '.png') return 'image/png';
    if (extension == '.webp') return 'image/webp';
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    return 'image/jpeg';
  }

  Future<void> _writeId3v24Tag(
    File file, {
    required SourceTrack track,
    required String? lyrics,
    required Uint8List? artworkBytes,
    required String? artworkMime,
  }) async {
    final frames = <int>[
      ..._id3TextFrame('TIT2', track.title),
      ..._id3TextFrame('TPE1', track.artists.join('/')),
      if (track.album != null) ..._id3TextFrame('TALB', track.album!),
      if (track.isrc != null) ..._id3TextFrame('TSRC', track.isrc!),
      if (lyrics != null) ..._id3LyricsFrame(lyrics),
      if (artworkBytes != null && artworkMime != null)
        ..._id3PictureFrame(artworkBytes, artworkMime),
    ];
    if (frames.isEmpty) return;

    final original = await file.readAsBytes();
    final audioBytes = _stripExistingId3(original);
    final tag = <int>[
      0x49, 0x44, 0x33, // ID3
      0x04, 0x00,
      0x00,
      ..._synchsafe(frames.length),
      ...frames,
    ];
    await file.writeAsBytes([...tag, ...audioBytes], flush: false);
  }

  List<int> _id3TextFrame(String id, String text) {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return const [];
    return _id3Frame(id, [0x03, ...utf8.encode(cleaned)]);
  }

  List<int> _id3LyricsFrame(String lyrics) {
    return _id3Frame(
        'USLT', [0x03, 0x7A, 0x68, 0x6F, 0x00, ...utf8.encode(lyrics)]);
  }

  List<int> _id3PictureFrame(Uint8List bytes, String mimeType) {
    return _id3Frame('APIC', [
      0x03,
      ...utf8.encode(mimeType),
      0x00,
      0x03,
      0x00,
      ...bytes,
    ]);
  }

  List<int> _id3Frame(String id, List<int> payload) {
    return [
      ...ascii.encode(id),
      ..._synchsafe(payload.length),
      0x00,
      0x00,
      ...payload,
    ];
  }

  Uint8List _stripExistingId3(Uint8List bytes) {
    if (bytes.length < 10 ||
        bytes[0] != 0x49 ||
        bytes[1] != 0x44 ||
        bytes[2] != 0x33) {
      return bytes;
    }
    final size = _readSynchsafe(bytes, 6);
    final offset = 10 + size;
    if (offset <= 10 || offset > bytes.length) return bytes;
    return Uint8List.sublistView(bytes, offset);
  }

  Future<void> _writeFlacMetadata(
    File file, {
    required SourceTrack track,
    required String? lyrics,
    required Uint8List? artworkBytes,
    required String? artworkMime,
  }) async {
    final bytes = await file.readAsBytes();
    if (bytes.length < 8 ||
        bytes[0] != 0x66 ||
        bytes[1] != 0x4C ||
        bytes[2] != 0x61 ||
        bytes[3] != 0x43) {
      return;
    }

    var offset = 4;
    final preservedBlocks = <Uint8List>[];
    while (offset + 4 <= bytes.length) {
      final type = bytes[offset] & 0x7F;
      final length = (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
      final blockEnd = offset + 4 + length;
      if (blockEnd > bytes.length) return;
      if (type != 4 && type != 6) {
        final block = Uint8List.fromList(bytes.sublist(offset, blockEnd));
        block[0] = block[0] & 0x7F;
        preservedBlocks.add(block);
      }
      offset = blockEnd;
      if ((bytes[offset - length - 4] & 0x80) != 0) break;
    }
    if (preservedBlocks.isEmpty || offset >= bytes.length) return;

    final addedBlocks = <Uint8List>[
      _flacMetadataBlock(
        type: 4,
        payload: _vorbisCommentPayload(track, lyrics),
        isLast: artworkBytes == null || artworkMime == null,
      ),
      if (artworkBytes != null && artworkMime != null)
        _flacMetadataBlock(
          type: 6,
          payload: _flacPicturePayload(artworkBytes, artworkMime),
          isLast: true,
        ),
    ];

    final next = BytesBuilder(copy: false)..add(bytes.sublist(0, 4));
    for (final block in preservedBlocks) {
      next.add(block);
    }
    for (final block in addedBlocks) {
      next.add(block);
    }
    next.add(bytes.sublist(offset));
    await file.writeAsBytes(next.takeBytes(), flush: false);
  }

  Uint8List _flacMetadataBlock({
    required int type,
    required Uint8List payload,
    required bool isLast,
  }) {
    return Uint8List.fromList([
      (isLast ? 0x80 : 0x00) | (type & 0x7F),
      (payload.length >> 16) & 0xFF,
      (payload.length >> 8) & 0xFF,
      payload.length & 0xFF,
      ...payload,
    ]);
  }

  Uint8List _vorbisCommentPayload(SourceTrack track, String? lyrics) {
    final comments = <String>[
      'TITLE=${track.title}',
      for (final artist in track.artists) 'ARTIST=$artist',
      if (track.album != null && track.album!.trim().isNotEmpty)
        'ALBUM=${track.album}',
      if (track.isrc != null && track.isrc!.trim().isNotEmpty)
        'ISRC=${track.isrc}',
      if (lyrics != null) 'LYRICS=$lyrics',
    ];
    final vendor = utf8.encode('MeloUnion');
    final builder = BytesBuilder(copy: false)
      ..add(_littleEndianInt32(vendor.length))
      ..add(vendor)
      ..add(_littleEndianInt32(comments.length));
    for (final comment in comments) {
      final bytes = utf8.encode(comment);
      builder
        ..add(_littleEndianInt32(bytes.length))
        ..add(bytes);
    }
    return builder.takeBytes();
  }

  Uint8List _flacPicturePayload(Uint8List bytes, String mimeType) {
    final mimeBytes = utf8.encode(mimeType);
    final builder = BytesBuilder(copy: false)
      ..add(_bigEndianInt32(3))
      ..add(_bigEndianInt32(mimeBytes.length))
      ..add(mimeBytes)
      ..add(_bigEndianInt32(0))
      ..add(_bigEndianInt32(0))
      ..add(_bigEndianInt32(0))
      ..add(_bigEndianInt32(0))
      ..add(_bigEndianInt32(0))
      ..add(_bigEndianInt32(bytes.length))
      ..add(bytes);
    return builder.takeBytes();
  }

  List<int> _littleEndianInt32(int value) => [
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ];

  List<int> _bigEndianInt32(int value) => [
        (value >> 24) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 8) & 0xFF,
        value & 0xFF,
      ];

  List<int> _synchsafe(int value) => [
        (value >> 21) & 0x7F,
        (value >> 14) & 0x7F,
        (value >> 7) & 0x7F,
        value & 0x7F,
      ];

  int _readSynchsafe(Uint8List bytes, int offset) {
    return (bytes[offset] << 21) |
        (bytes[offset + 1] << 14) |
        (bytes[offset + 2] << 7) |
        bytes[offset + 3];
  }

  Future<void> _handlePlaybackCompleted() async {
    if (_isAdvancingAfterCompletion) return;
    _isAdvancingAfterCompletion = true;
    try {
      await queueNext(automatic: true);
    } finally {
      _isAdvancingAfterCompletion = false;
    }
  }

  FavoriteSnapshot _normalizeFavoriteSnapshot(
    FavoriteSnapshot snapshot, {
    FavoriteSnapshot? previous,
  }) {
    final previousByRef = {
      for (final track in previous?.tracks ?? const <SourceTrack>[])
        _refKey(track.ref): track,
    };
    final tracks = <SourceTrack>[];
    final seenRefs = <String>{};
    for (final track in snapshot.tracks) {
      final key = _refKey(track.ref);
      if (!seenRefs.add(key)) continue;
      if (snapshot.providerId == qqMusicProviderId) {
        tracks.add(_qqTrackWithoutProviderLikedAt(track));
        continue;
      }
      if (snapshot.providerId == kugouProviderId &&
          track.likedAtSource != LikedAtMetadata.sourceKugouRaw) {
        final previousTrack = previousByRef[key];
        if (previousTrack?.likedAtSource == LikedAtMetadata.sourceKugouRaw &&
            previousTrack?.likedAt != null) {
          tracks.add(
            track.copyWith(
              likedAt: previousTrack!.likedAt,
              likedAtSource: previousTrack.likedAtSource,
              likedAtPrecision: previousTrack.likedAtPrecision,
            ),
          );
          continue;
        }
      }
      tracks.add(track);
    }
    return FavoriteSnapshot(
      providerId: snapshot.providerId,
      tracks: tracks,
      fetchedAt: snapshot.fetchedAt,
      partialFailureReason: snapshot.partialFailureReason,
    );
  }

  Set<ProviderId> _eligibleFavoriteProviderIds() {
    return {
      for (final entry in capabilityMatrix.eligibleFavoritesEntries(registry))
        entry.descriptor.id,
    };
  }

  List<FavoriteSnapshot> _eligibleFavoriteSnapshots() {
    final eligible = _eligibleFavoriteProviderIds();
    return [
      for (final entry in _favoriteProviderSnapshots.entries)
        if (eligible.contains(entry.key)) entry.value,
    ];
  }

  void _discardFavoriteProvider(ProviderId providerId) {
    _favoriteProviderSnapshots.remove(providerId);
    _favoriteProviderStates.remove(providerId);
    _rebuildUnifiedFavoritesCache();
    _persistSoon();
  }

  void _rebuildUnifiedFavoritesCache() {
    final result = favoritesService.buildFromSnapshots(
      _eligibleFavoriteSnapshots(),
      overrides: favoritesOverrideRegistry,
      likedAtLedger: favoriteLikedAtLedger,
    );
    _unifiedFavoritesCache = CachedUnifiedFavorites(
      tracks: result.tracks,
      builtAt: DateTime.now().toUtc(),
    );
    _lastFavoritesData = result.tracks.isEmpty ? null : result.tracks;
    for (final track in result.tracks) {
      _rememberTracks(track.variants);
    }
  }

  String _refKey(ProviderTrackRef ref) {
    final extra = ref.extraIds.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    final extraKey =
        extra.map((entry) => '${entry.key}=${entry.value}').join('&');
    return '${ref.providerId.value}:${ref.trackId}:$extraKey';
  }

  SourceTrack _qqTrackWithoutProviderLikedAt(SourceTrack track) {
    return SourceTrack(
      ref: track.ref,
      title: track.title,
      artists: track.artists,
      duration: track.duration,
      isFavorited: track.isFavorited,
      album: track.album,
      isrc: track.isrc,
      artwork: track.artwork,
      isPlayable: track.isPlayable,
      isDownloadable: track.isDownloadable,
      likedAtSource: LikedAtMetadata.sourceQqImport,
      likedAtPrecision: LikedAtMetadata.precisionUnknown,
    );
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

  void _replaceQqMusicProvider(QqMusicCredentials? credentials) {
    final wasEnabled = registry.isEnabled(qqMusicProviderId);
    registry.register(
      QqMusicProvider(credentials: credentials),
      enabled: wasEnabled,
    );
  }

  void _replaceKugouProvider(KugouSession? session) {
    final wasEnabled = registry.isEnabled(kugouProviderId);
    registry.register(
      KugouMusicProvider.create(
        secureStore: kugouSessionStore ?? const NullKugouSessionStore(),
        initialSession: session,
      ),
      enabled: wasEnabled,
    );
  }

  Future<String?> getLyrics(ProviderTrackRef ref) async {
    final provider = registry.entryOf(ref.providerId)?.provider;
    if (provider == null) return null;
    return provider.getLyrics(ref);
  }
}
