import 'package:provider_contract/provider_contract.dart';
import '../model/kugou_remote_track.dart';

final class KugouTrackMapper {
  KugouTrackMapper({required this.providerId});

  final ProviderId providerId;

  SourceTrack map(KugouRemoteTrack remote, {bool isFavorited = false}) {
    return SourceTrack(
      ref: ProviderTrackRef(
        providerId: providerId,
        trackId: remote.hash,
        extraIds: {
          if (remote.albumId != null && remote.albumId!.isNotEmpty)
            'albumId': remote.albumId!,
          if (remote.albumAudioId != null && remote.albumAudioId!.isNotEmpty)
            'albumAudioId': remote.albumAudioId!,
          if (remote.mixSongId != null && remote.mixSongId!.isNotEmpty)
            'mixSongId': remote.mixSongId!,
          if (remote.favoriteFileId != null &&
              remote.favoriteFileId!.isNotEmpty)
            'favoriteFileId': remote.favoriteFileId!,
        },
      ),
      title: remote.title,
      artists: remote.artists,
      duration: remote.duration,
      album: remote.album,
      artwork: remote.artwork,
      isFavorited: isFavorited || remote.favoriteFileId != null,
      isPlayable: remote.explicitlyBlocked != true,
      isDownloadable: remote.explicitlyBlocked !=
          true, // Can be downloaded if playable and not blocked
      likedAt: remote.favoriteTime,
      likedAtSource: remote.favoriteTime == null ? 'unknown' : 'sync_detected',
      likedAtPrecision: remote.favoriteTime == null ? 'unknown' : 'approximate',
    );
  }
}
