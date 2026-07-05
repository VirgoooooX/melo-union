import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

final class MeloDataSnapshot {
  MeloDataSnapshot({
    this.playlists = const [],
    this.downloadTasks = const [],
    this.localMediaItems = const [],
    this.playbackQuality = AudioQuality.standard,
    this.volume = 1.0,
    this.downloadDirectory,
    FavoritesOverrideRegistry? favoritesOverrides,
  }) : favoritesOverrides = favoritesOverrides ?? FavoritesOverrideRegistry();

  final List<LocalPlaylist> playlists;
  final List<DownloadTask> downloadTasks;
  final List<LocalMediaItem> localMediaItems;
  final AudioQuality playbackQuality;
  final double volume;
  final String? downloadDirectory;
  final FavoritesOverrideRegistry favoritesOverrides;
}
