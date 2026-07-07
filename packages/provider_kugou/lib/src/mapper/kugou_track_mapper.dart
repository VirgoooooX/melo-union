import 'package:provider_contract/provider_contract.dart';
import '../model/kugou_remote_track.dart';

final class KugouTrackMapper {
  KugouTrackMapper({required this.providerId});

  final ProviderId providerId;

  SourceTrack map(KugouRemoteTrack remote, {bool isFavorited = false}) {
    final favorited = isFavorited || remote.favoriteFileId != null;
    return SourceTrack(
      ref: ProviderTrackRef(
        providerId: providerId,
        trackId: remote.hash,
        extraIds: {
          if (remote.title.trim().isNotEmpty)
            'searchTitle': remote.title.trim(),
          if (remote.artists.isNotEmpty)
            'searchArtists': remote.artists.join('|'),
          if (remote.albumId != null && remote.albumId!.isNotEmpty)
            'albumId': remote.albumId!,
          if (remote.albumAudioId != null && remote.albumAudioId!.isNotEmpty)
            'albumAudioId': remote.albumAudioId!,
          if (remote.mixSongId != null && remote.mixSongId!.isNotEmpty)
            'mixSongId': remote.mixSongId!,
          if (remote.duration.inMilliseconds > 0)
            'expectedDurationMs': remote.duration.inMilliseconds.toString(),
          if (remote.rawHash != null && remote.rawHash!.isNotEmpty)
            'rawHash': remote.rawHash!,
          if (remote.fileHash != null && remote.fileHash!.isNotEmpty)
            'fileHash': remote.fileHash!,
          if (remote.sqHash != null && remote.sqHash!.isNotEmpty)
            'sqHash': remote.sqHash!,
          if (remote.hqHash != null && remote.hqHash!.isNotEmpty)
            'hqHash': remote.hqHash!,
          if (remote.resHash != null && remote.resHash!.isNotEmpty)
            'resHash': remote.resHash!,
          if (remote.ogg320Hash != null && remote.ogg320Hash!.isNotEmpty)
            'ogg320Hash': remote.ogg320Hash!,
          if (remote.ogg128Hash != null && remote.ogg128Hash!.isNotEmpty)
            'ogg128Hash': remote.ogg128Hash!,
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
      isFavorited: favorited,
      isPlayable: remote.explicitlyBlocked != true,
      isDownloadable: remote.explicitlyBlocked !=
          true, // Can be downloaded if playable and not blocked
      likedAt: remote.favoriteTime,
      likedAtSource: remote.favoriteTime != null
          ? 'kugou_raw'
          : favorited
              ? 'kugou_import'
              : null,
      likedAtPrecision: remote.favoriteTime != null
          ? 'exact'
          : favorited
              ? 'unknown'
              : null,
    );
  }
}
