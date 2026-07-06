final class KugouRemoteTrack {
  const KugouRemoteTrack({
    required this.hash,
    required this.title,
    required this.artists,
    required this.duration,
    this.album,
    this.albumId,
    this.albumAudioId,
    this.mixSongId,
    this.fileHash,
    this.sqHash,
    this.hqHash,
    this.resHash,
    this.ogg320Hash,
    this.ogg128Hash,
    this.favoriteFileId,
    this.explicitlyBlocked,
    this.favoriteTime,
    this.artwork,
  });

  final String hash;
  final String title;
  final List<String> artists;
  final Duration duration;
  final String? album;
  final String? albumId;
  final String? albumAudioId;
  final String? mixSongId;
  final String? fileHash;
  final String? sqHash;
  final String? hqHash;
  final String? resHash;
  final String? ogg320Hash;
  final String? ogg128Hash;
  final String? favoriteFileId;
  final bool? explicitlyBlocked;
  final DateTime? favoriteTime;
  final Uri? artwork;
}
