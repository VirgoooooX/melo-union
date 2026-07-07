import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

final class MeloDataSnapshot {
  MeloDataSnapshot({
    this.playlists = const [],
    this.downloadTasks = const [],
    this.localMediaItems = const [],
    this.favoriteProviderSnapshots = const [],
    LikedAtLedger? favoriteLikedAtLedger,
    this.unifiedFavoritesCache,
    this.favoriteProviderStates = const [],
    this.playbackQuality = AudioQuality.standard,
    this.volume = 1.0,
    this.playbackPreferences = const PlaybackPreferencesSnapshot(),
    this.playbackQueue,
    this.downloadDirectory,
    FavoritesOverrideRegistry? favoritesOverrides,
  })  : favoriteLikedAtLedger = favoriteLikedAtLedger ?? LikedAtLedger(),
        favoritesOverrides = favoritesOverrides ?? FavoritesOverrideRegistry();

  final List<LocalPlaylist> playlists;
  final List<DownloadTask> downloadTasks;
  final List<LocalMediaItem> localMediaItems;
  final List<FavoriteSnapshot> favoriteProviderSnapshots;
  final LikedAtLedger favoriteLikedAtLedger;
  final CachedUnifiedFavorites? unifiedFavoritesCache;
  final List<FavoriteProviderStateSnapshot> favoriteProviderStates;
  final AudioQuality playbackQuality;
  final double volume;
  final PlaybackPreferencesSnapshot playbackPreferences;
  final PlaybackQueueSnapshot? playbackQueue;
  final String? downloadDirectory;
  final FavoritesOverrideRegistry favoritesOverrides;
}

final class PlaybackPreferencesSnapshot {
  const PlaybackPreferencesSnapshot({
    this.rememberQueue = false,
    this.restorePlaybackState = false,
  });

  final bool rememberQueue;
  final bool restorePlaybackState;
}

final class PlaybackQueueSnapshot {
  PlaybackQueueSnapshot({
    required this.entries,
    required this.currentIndex,
    this.position = Duration.zero,
    this.shuffleEnabled = false,
    this.repeatMode = 'off',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now().toUtc();

  final List<PlaybackQueueEntrySnapshot> entries;
  final int currentIndex;
  final Duration position;
  final bool shuffleEnabled;
  final String repeatMode;
  final DateTime updatedAt;
}

final class PlaybackQueueEntrySnapshot {
  const PlaybackQueueEntrySnapshot({
    required this.track,
    required this.queuedAt,
  });

  final SourceTrack track;
  final DateTime queuedAt;
}

final class FavoriteProviderStateSnapshot {
  const FavoriteProviderStateSnapshot({
    required this.providerId,
    this.lastSuccessAt,
    this.lastFailureAt,
    this.lastFailureMessage,
  });

  final ProviderId providerId;
  final DateTime? lastSuccessAt;
  final DateTime? lastFailureAt;
  final String? lastFailureMessage;
}
