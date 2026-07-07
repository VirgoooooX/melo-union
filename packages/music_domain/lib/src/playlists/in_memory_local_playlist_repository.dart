import 'package:provider_contract/provider_contract.dart';

import 'local_playlist_models.dart';

final class InMemoryLocalPlaylistRepository implements LocalPlaylistRepository {
  InMemoryLocalPlaylistRepository({
    List<LocalPlaylist> seedPlaylists = const [],
  }) : _playlists = {
          for (final playlist in seedPlaylists) playlist.id: playlist,
        };

  final Map<String, LocalPlaylist> _playlists;
  int _playlistCounter = 0;

  @override
  List<LocalPlaylist> listPlaylists() {
    final items = _playlists.values.toList(growable: false)
      ..sort((left, right) => left.name.compareTo(right.name));
    return List.unmodifiable(items);
  }

  void replaceAll(List<LocalPlaylist> playlists) {
    _playlists
      ..clear()
      ..addEntries(playlists.map((playlist) => MapEntry(playlist.id, playlist)));
  }

  @override
  LocalPlaylist createPlaylist(String name) {
    final playlist = LocalPlaylist(
      id: 'playlist_${_playlistCounter++}',
      name: name.trim(),
    );
    _playlists[playlist.id] = playlist;
    return playlist;
  }

  @override
  void deletePlaylist(String playlistId) {
    _playlists.remove(playlistId);
  }

  @override
  LocalPlaylist renamePlaylist({
    required String playlistId,
    required String nextName,
  }) {
    final playlist = _requirePlaylist(playlistId);
    final updated = playlist.copyWith(name: nextName.trim());
    _playlists[playlistId] = updated;
    return updated;
  }

  @override
  LocalPlaylist addTrack({
    required String playlistId,
    required SourceTrack track,
    DateTime? addedAt,
  }) {
    final playlist = _requirePlaylist(playlistId);
    final nextItems = [
      ...playlist.items,
      LocalPlaylistItem(
        trackRef: track.ref,
        cachedTitle: track.title,
        cachedArtists: track.artists,
        cachedProviderName:
            track.ref.providerId.value.replaceAll('_', ' ').toUpperCase(),
        addedAt: addedAt ?? DateTime.now().toUtc(),
      ),
    ];
    final updated = playlist.copyWith(items: nextItems);
    _playlists[playlistId] = updated;
    return updated;
  }

  @override
  LocalPlaylist removeTrack({
    required String playlistId,
    required ProviderTrackRef trackRef,
  }) {
    final playlist = _requirePlaylist(playlistId);
    final nextItems = playlist.items
        .where((item) => item.trackRef != trackRef)
        .toList(growable: false);
    final updated = playlist.copyWith(items: nextItems);
    _playlists[playlistId] = updated;
    return updated;
  }

  LocalPlaylist _requirePlaylist(String playlistId) {
    final playlist = _playlists[playlistId];
    if (playlist == null) {
      throw StateError('Unknown playlist: $playlistId');
    }
    return playlist;
  }
}
