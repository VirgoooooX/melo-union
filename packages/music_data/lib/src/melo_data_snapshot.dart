import 'package:music_domain/music_domain.dart';

final class MeloDataSnapshot {
  MeloDataSnapshot({
    this.playlists = const [],
    this.downloadTasks = const [],
    this.localMediaItems = const [],
    FavoritesOverrideRegistry? favoritesOverrides,
  }) : favoritesOverrides = favoritesOverrides ?? FavoritesOverrideRegistry();

  final List<LocalPlaylist> playlists;
  final List<DownloadTask> downloadTasks;
  final List<LocalMediaItem> localMediaItems;
  final FavoritesOverrideRegistry favoritesOverrides;
}
