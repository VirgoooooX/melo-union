import 'package:provider_contract/provider_contract.dart';
import '../model/kugou_remote_playlist.dart';

final class KugouPlaylistMapper {
  KugouPlaylistMapper({required this.providerId});

  final ProviderId providerId;

  ProviderPlaylist map(KugouRemotePlaylist remote) {
    return ProviderPlaylist(
      providerId: providerId,
      playlistId: remote.playlistId,
      name: remote.name,
      description: remote.description,
      creatorName: remote.creatorName,
      cover: remote.cover,
      trackCount: remote.trackCount,
      playCount: remote.playCount,
    );
  }
}
