import 'package:provider_contract/provider_contract.dart';

final class LocalPlaylist {
  LocalPlaylist({
    required this.id,
    required this.name,
    List<LocalPlaylistItem> items = const [],
  }) : items = List.unmodifiable(items);

  final String id;
  final String name;
  final List<LocalPlaylistItem> items;

  LocalPlaylist copyWith({
    String? id,
    String? name,
    List<LocalPlaylistItem>? items,
  }) {
    return LocalPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }
}

final class LocalPlaylistItem {
  const LocalPlaylistItem({
    required this.trackRef,
    required this.cachedTitle,
    required this.cachedArtists,
    required this.cachedProviderName,
    required this.addedAt,
  });

  final ProviderTrackRef trackRef;
  final String cachedTitle;
  final List<String> cachedArtists;
  final String cachedProviderName;
  final DateTime addedAt;
}

abstract interface class LocalPlaylistRepository {
  List<LocalPlaylist> listPlaylists();

  LocalPlaylist createPlaylist(String name);

  LocalPlaylist renamePlaylist({
    required String playlistId,
    required String nextName,
  });

  void deletePlaylist(String playlistId);

  LocalPlaylist addTrack({
    required String playlistId,
    required SourceTrack track,
    DateTime? addedAt,
  });

  LocalPlaylist removeTrack({
    required String playlistId,
    required ProviderTrackRef trackRef,
  });
}
