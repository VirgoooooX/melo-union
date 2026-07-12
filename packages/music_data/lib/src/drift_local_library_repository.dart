import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:music_domain/music_domain.dart';

import 'drift_melo_database.dart' as db;

final class DriftLocalLibraryRepository implements LocalLibraryRepository {
  DriftLocalLibraryRepository(this.database);

  final db.MeloDriftDatabase database;

  @override
  Future<List<LocalLibraryRoot>> listRoots() async {
    final rows = await (database.select(database.storedLocalLibraryRoots)
          ..orderBy([(r) => OrderingTerm.asc(r.displayName)]))
        .get();
    return rows
        .map((row) => LocalLibraryRoot(
              id: row.id,
              path: row.path,
              displayName: row.displayName,
              scanState: LocalLibraryScanState.values.firstWhere(
                (state) => state.name == row.scanState,
                orElse: () => LocalLibraryScanState.idle,
              ),
              lastScannedAt: row.lastScannedAt,
              lastError: row.lastError,
            ))
        .toList(growable: false);
  }

  @override
  Future<List<LocalLibraryTrack>> listTracks({
    String query = '',
    LocalLibrarySortOrder sort = LocalLibrarySortOrder.album,
    int limit = 200,
    int offset = 0,
  }) async {
    final normalized = query.trim().toLowerCase();
    final statement = database.select(database.storedLocalLibraryTracks).join([
      leftOuterJoin(
        database.storedLocalLibraryFavorites,
        database.storedLocalLibraryFavorites.trackId.equalsExp(
          database.storedLocalLibraryTracks.id,
        ),
      ),
    ]);
    if (normalized.isNotEmpty) {
      final pattern = '%$normalized%';
      statement.where(
        database.storedLocalLibraryTracks.title.lower().like(pattern) |
            database.storedLocalLibraryTracks.artistsJson
                .lower()
                .like(pattern) |
            database.storedLocalLibraryTracks.album.lower().like(pattern),
      );
    }
    statement
      ..orderBy(_trackOrdering(sort))
      ..limit(limit, offset: offset);
    final rows = await statement.get();
    return rows.map(_trackFromJoinedRow).toList(growable: false);
  }

  List<OrderingTerm> _trackOrdering(LocalLibrarySortOrder sort) {
    final tracks = database.storedLocalLibraryTracks;
    final title = OrderingTerm.asc(tracks.title.lower());
    final id = OrderingTerm.asc(tracks.id);
    return switch (sort) {
      LocalLibrarySortOrder.album => [
          OrderingTerm.asc(tracks.artistsJson.lower()),
          OrderingTerm.asc(tracks.year.isNull()),
          OrderingTerm.asc(tracks.year),
          OrderingTerm.asc(tracks.album.isNull()),
          OrderingTerm.asc(tracks.album.lower()),
          OrderingTerm.asc(tracks.discNumber.isNull()),
          OrderingTerm.asc(tracks.discNumber),
          OrderingTerm.asc(tracks.trackNumber.isNull()),
          OrderingTerm.asc(tracks.trackNumber),
          title,
          id,
        ],
      LocalLibrarySortOrder.title => [title, id],
      LocalLibrarySortOrder.artist => [
          OrderingTerm.asc(tracks.artistsJson.lower()),
          title,
          id,
        ],
    };
  }

  @override
  Future<LocalLibraryTrack?> getTrack(String id) async {
    final rows =
        await _trackQuery(database.storedLocalLibraryTracks.id.equals(id))
            .get();
    return rows.isEmpty ? null : _trackFromJoinedRow(rows.first);
  }

  @override
  Future<LocalLibraryTrack?> findByPath(String filePath) async {
    final rows = await _trackQuery(
      database.storedLocalLibraryTracks.filePath.equals(filePath),
    ).get();
    return rows.isEmpty ? null : _trackFromJoinedRow(rows.first);
  }

  @override
  Future<List<LocalLibraryTrack>> findByFingerprint(String fingerprint) async {
    final rows = await _trackQuery(
      database.storedLocalLibraryTracks.fingerprint.equals(fingerprint),
    ).get();
    return rows.map(_trackFromJoinedRow).toList(growable: false);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _trackQuery(
      Expression<bool> where) {
    return database.select(database.storedLocalLibraryTracks).join([
      leftOuterJoin(
        database.storedLocalLibraryFavorites,
        database.storedLocalLibraryFavorites.trackId.equalsExp(
          database.storedLocalLibraryTracks.id,
        ),
      ),
    ])
      ..where(where);
  }

  LocalLibraryTrack _trackFromJoinedRow(TypedResult result) {
    final row = result.readTable(database.storedLocalLibraryTracks);
    final favorite =
        result.readTableOrNull(database.storedLocalLibraryFavorites);
    return LocalLibraryTrack(
      id: row.id,
      rootId: row.rootId,
      filePath: row.filePath,
      relativePath: row.relativePath,
      fileSize: row.fileSize,
      modifiedAt: row.modifiedAt,
      fingerprint: row.fingerprint,
      title: row.title,
      artists: (jsonDecode(row.artistsJson) as List)
          .map((value) => value.toString())
          .toList(growable: false),
      duration: Duration(milliseconds: row.durationMs),
      format: row.format,
      album: row.album,
      genre: row.genre,
      year: row.year,
      trackNumber: row.trackNumber,
      discNumber: row.discNumber,
      lyrics: row.lyrics,
      artworkPath: row.artworkPath,
      isAvailable: row.isAvailable,
      isFavorited: favorite != null,
      likedAt: favorite?.likedAt,
    );
  }

  @override
  Future<void> upsertRoot(LocalLibraryRoot root) async {
    await database
        .into(database.storedLocalLibraryRoots)
        .insertOnConflictUpdate(
          db.StoredLocalLibraryRootsCompanion.insert(
            id: root.id,
            path: root.path,
            displayName: root.displayName,
            scanState: root.scanState.name,
            lastScannedAt: Value(root.lastScannedAt),
            lastError: Value(root.lastError),
          ),
        );
  }

  @override
  Future<void> removeRoot(String rootId) async {
    await database.transaction(() async {
      await (database.delete(database.storedLocalLibraryTracks)
            ..where((row) => row.rootId.equals(rootId)))
          .go();
      await (database.delete(database.storedLocalLibraryRoots)
            ..where((row) => row.id.equals(rootId)))
          .go();
      // 外键级联未启用，手动移除失去曲目引用的喜欢记录。
      await database.customStatement(
        'DELETE FROM stored_local_library_favorites WHERE track_id NOT IN '
        '(SELECT id FROM stored_local_library_tracks)',
      );
    });
  }

  @override
  Future<void> upsertTracks(List<LocalLibraryTrack> tracks) async {
    if (tracks.isEmpty) return;
    await database.batch((batch) {
      batch.insertAllOnConflictUpdate(
        database.storedLocalLibraryTracks,
        tracks
            .map((track) => db.StoredLocalLibraryTracksCompanion.insert(
                  id: track.id,
                  rootId: track.rootId,
                  filePath: track.filePath,
                  relativePath: track.relativePath,
                  fileSize: track.fileSize,
                  modifiedAt: track.modifiedAt,
                  fingerprint: track.fingerprint,
                  title: track.title,
                  artistsJson: jsonEncode(track.artists),
                  durationMs: track.duration.inMilliseconds,
                  format: track.format,
                  album: Value(track.album),
                  genre: Value(track.genre),
                  year: Value(track.year),
                  trackNumber: Value(track.trackNumber),
                  discNumber: Value(track.discNumber),
                  lyrics: Value(track.lyrics),
                  artworkPath: Value(track.artworkPath),
                  isAvailable: Value(track.isAvailable),
                ))
            .toList(growable: false),
      );
    });
  }

  @override
  Future<void> replaceAll(
    List<LocalLibraryRoot> roots,
    List<LocalLibraryTrack> tracks,
  ) async {
    await database.transaction(() async {
      await database.delete(database.storedLocalLibraryFavorites).go();
      await database.delete(database.storedLocalLibraryTracks).go();
      await database.delete(database.storedLocalLibraryRoots).go();
      for (final root in roots) {
        await upsertRoot(root);
      }
      for (final chunk in _chunks(tracks, 200)) {
        await upsertTracks(chunk);
        for (final track in chunk) {
          if (track.isFavorited) {
            await setFavorite(track.id, true, likedAt: track.likedAt);
          }
        }
      }
    });
  }

  @override
  Future<void> markUnavailableExcept(
    String rootId,
    Set<String> availablePaths,
  ) async {
    // Windows 路径匹配不区分大小写。
    final availableLower = {
      for (final p in availablePaths) p.toLowerCase(),
    };
    await database.transaction(() async {
      await (database.update(database.storedLocalLibraryTracks)
            ..where((row) => row.rootId.equals(rootId)))
          .write(const db.StoredLocalLibraryTracksCompanion(
              isAvailable: Value(false)));
      if (availableLower.isEmpty) return;
      await (database.update(database.storedLocalLibraryTracks)
            ..where((row) =>
                row.rootId.equals(rootId) &
                row.filePath.lower().isIn(availableLower)))
          .write(const db.StoredLocalLibraryTracksCompanion(
              isAvailable: Value(true)));
    });
  }

  @override
  Future<void> setFavorite(String trackId, bool liked,
      {DateTime? likedAt}) async {
    if (!liked) {
      await (database.delete(database.storedLocalLibraryFavorites)
            ..where((row) => row.trackId.equals(trackId)))
          .go();
      return;
    }
    await database
        .into(database.storedLocalLibraryFavorites)
        .insertOnConflictUpdate(
          db.StoredLocalLibraryFavoritesCompanion.insert(
            trackId: trackId,
            likedAt: likedAt ?? DateTime.now().toUtc(),
          ),
        );
  }
}

Iterable<List<T>> _chunks<T>(List<T> values, int size) sync* {
  for (var i = 0; i < values.length; i += size) {
    final end = i + size < values.length ? i + size : values.length;
    yield values.sublist(i, end);
  }
}
