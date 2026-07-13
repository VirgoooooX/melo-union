import 'package:music_domain/music_domain.dart';

const localVariousArtistsName = '群星';

/// Resolves the library artist for tracks already known to be one candidate
/// album (same directory and normalized album title).
List<LocalLibraryTrack> resolveAlbumArtists(List<LocalLibraryTrack> tracks) {
  if (tracks.isEmpty) return const [];

  final overrides = tracks
      .where((track) =>
          track.albumArtistSource == LocalAlbumArtistSource.userOverride)
      .toList(growable: false);
  if (overrides.isNotEmpty) {
    final identities =
        overrides.map((track) => _identity(track.albumArtist)).toSet();
    final adopted = overrides.first.albumArtist?.trim();
    if (identities.length == 1 && adopted != null && adopted.isNotEmpty) {
      return [
        for (final track in tracks)
          track.albumArtistSource == LocalAlbumArtistSource.userOverride
              ? track
              : track.copyWith(
                  albumArtist: adopted,
                  albumArtistSource: LocalAlbumArtistSource.albumConsensus,
                ),
      ];
    }
    return [
      for (final track in tracks)
        track.albumArtistSource == LocalAlbumArtistSource.userOverride
            ? track
            : _resolveTrackFallback(track),
    ];
  }

  final embedded = _majority(
    tracks.map((track) => track.embeddedAlbumArtist),
  );
  if (embedded != null) {
    return _apply(tracks, embedded, LocalAlbumArtistSource.embeddedTag);
  }

  if (tracks.length == 1) {
    final artist = _firstArtist(tracks.single) ?? localVariousArtistsName;
    return _apply(
      tracks,
      artist,
      artist == localVariousArtistsName
          ? LocalAlbumArtistSource.variousArtists
          : LocalAlbumArtistSource.trackArtistFallback,
    );
  }

  final candidate = _majority(
    tracks.map(_firstArtist),
    minimumCount: 2,
  );
  if (candidate != null) {
    final count = tracks
        .map(_firstArtist)
        .where((artist) => _identity(artist) == _identity(candidate))
        .length;
    if (count / tracks.length >= 0.7) {
      return _apply(
        tracks,
        candidate,
        LocalAlbumArtistSource.directoryConsensus,
      );
    }
  }

  return _apply(
    tracks,
    localVariousArtistsName,
    LocalAlbumArtistSource.variousArtists,
  );
}

LocalLibraryTrack _resolveTrackFallback(LocalLibraryTrack track) {
  final embedded = track.embeddedAlbumArtist?.trim();
  if (embedded != null && embedded.isNotEmpty) {
    return track.copyWith(
      albumArtist: embedded,
      albumArtistSource: LocalAlbumArtistSource.embeddedTag,
    );
  }
  final artist = _firstArtist(track)?.trim();
  return track.copyWith(
    albumArtist: artist ?? localVariousArtistsName,
    albumArtistSource: artist == null
        ? LocalAlbumArtistSource.variousArtists
        : LocalAlbumArtistSource.trackArtistFallback,
  );
}

List<LocalLibraryTrack> _apply(
  List<LocalLibraryTrack> tracks,
  String artist,
  LocalAlbumArtistSource source,
) =>
    [
      for (final track in tracks)
        track.copyWith(albumArtist: artist, albumArtistSource: source),
    ];

String? _firstArtist(LocalLibraryTrack track) =>
    track.artists.where((artist) => artist.trim().isNotEmpty).firstOrNull;

String? _majority(
  Iterable<String?> values, {
  int minimumCount = 1,
}) {
  final votes = <String, ({int count, int firstIndex, String display})>{};
  var index = 0;
  for (final value in values) {
    final display = value?.trim();
    if (display == null || display.isEmpty) {
      index++;
      continue;
    }
    final key = _identity(display);
    final previous = votes[key];
    votes[key] = (
      count: (previous?.count ?? 0) + 1,
      firstIndex: previous?.firstIndex ?? index,
      display: previous?.display ?? display,
    );
    index++;
  }
  final ranked = votes.values.toList()
    ..sort((left, right) {
      final byCount = right.count.compareTo(left.count);
      return byCount != 0
          ? byCount
          : left.firstIndex.compareTo(right.firstIndex);
    });
  if (ranked.isEmpty || ranked.first.count < minimumCount) return null;
  return ranked.first.display;
}

String _identity(String? value) => (value ?? '')
    .trim()
    .toLowerCase()
    .replaceAll(RegExp(r'\s+'), ' ')
    .replaceAll(RegExp(r'[／\\]'), '/');
