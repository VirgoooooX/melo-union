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
  final String? downloadDirectory;
  final FavoritesOverrideRegistry favoritesOverrides;
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
