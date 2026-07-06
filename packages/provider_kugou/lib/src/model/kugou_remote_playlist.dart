final class KugouRemotePlaylist {
  const KugouRemotePlaylist({
    required this.playlistId,
    required this.name,
    this.description,
    this.creatorName,
    this.cover,
    this.trackCount = 0,
    this.playCount,
    this.isFavoriteCollection = false,
  });

  final String playlistId;
  final String name;
  final String? description;
  final String? creatorName;
  final Uri? cover;
  final int trackCount;
  final int? playCount;
  final bool isFavoriteCollection;
}
