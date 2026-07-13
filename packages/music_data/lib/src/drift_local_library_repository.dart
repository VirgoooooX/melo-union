import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import 'drift_melo_database.dart' as db;

final class DriftLocalLibraryRepository implements LocalLibraryRepository {
  DriftLocalLibraryRepository(this.database);

  final db.MeloDriftDatabase database;

  static const _resolvedAlbumArtistSql =
      "COALESCE(NULLIF(trim(t.album_artist), ''), "
      "NULLIF(trim(json_extract(t.artists_json, '\$[0]')), ''), '未知歌手')";
  static const _normalizedAlbumArtistSql =
      "(WITH RECURSIVE normalized(value) AS ("
      "SELECT lower(trim(replace(replace(replace(replace(replace(replace("
      "$_resolvedAlbumArtistSql, char(12288), ' '), char(9), ' '), "
      "char(10), ' '), char(11), ' '), char(12), ' '), char(13), ' '))) "
      "UNION ALL SELECT replace(value, '  ', ' ') FROM normalized "
      "WHERE instr(value, '  ') > 0) "
      "SELECT replace(replace(value, '／', '/'), '\\', '/') FROM normalized "
      "WHERE instr(value, '  ') = 0)";
  static const _normalizedAlbumTitleSql =
      "COALESCE(NULLIF(t.normalized_album, ''), "
      "lower(trim(COALESCE(NULLIF(t.album, ''), '未知专辑'))))";
  static const _albumKeySql = "$_normalizedAlbumArtistSql || '|' || "
      "$_normalizedAlbumTitleSql || '|' || "
      "lower(trim(COALESCE(t.album_edition_key, '')))";

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
            database.storedLocalLibraryTracks.album.lower().like(pattern) |
            database.storedLocalLibraryTracks.albumArtist.lower().like(pattern),
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
      genres: (jsonDecode(row.genresJson) as List)
          .map((value) => value.toString())
          .toList(growable: false),
      embeddedAlbumArtist: row.embeddedAlbumArtist,
      albumArtist: row.albumArtist,
      albumArtistSource: LocalAlbumArtistSource.values.firstWhere(
        (source) => source.name == row.albumArtistSource,
        orElse: () => LocalAlbumArtistSource.unresolved,
      ),
      albumEditionKey: row.albumEditionKey,
      isrc: row.isrc,
      addedAt: row.addedAt ?? row.modifiedAt,
      bitRate: row.bitRate,
      sampleRate: row.sampleRate,
      bitDepth: row.bitDepth,
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
      await database.customStatement(
        'DELETE FROM stored_local_track_matches WHERE local_track_id NOT IN '
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
                  genresJson: Value(jsonEncode(track.genres)),
                  embeddedAlbumArtist: Value(track.embeddedAlbumArtist),
                  albumArtist: Value(track.albumArtist),
                  albumArtistSource: Value(track.albumArtistSource.name),
                  albumEditionKey: Value(track.albumEditionKey),
                  isrc: Value(track.isrc),
                  addedAt: Value(track.addedAt),
                  bitRate: Value(track.bitRate),
                  sampleRate: Value(track.sampleRate),
                  bitDepth: Value(track.bitDepth),
                  normalizedTitle: Value(normalizeLocalMetadata(track.title)),
                  normalizedArtists: Value(
                    (track.artists.map(normalizeLocalMetadata).toList()..sort())
                        .join('|'),
                  ),
                  normalizedAlbum: Value(
                    normalizeLocalMetadata(track.album ?? ''),
                  ),
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
      await database.delete(database.storedLocalTrackMatches).go();
      await database.delete(database.storedLocalArtistMetadata).go();
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

  @override
  Future<LocalLibraryStats> getStats() async {
    final row = await database.customSelect('''
      SELECT COUNT(*) AS track_count,
        COUNT(DISTINCT $_albumKeySql) AS album_count,
        COUNT(DISTINCT $_normalizedAlbumArtistSql) AS artist_count
      FROM stored_local_library_tracks t WHERE t.is_available = 1
    ''').getSingle();
    return LocalLibraryStats(
      trackCount: row.read<int>('track_count'),
      albumCount: row.read<int>('album_count'),
      artistCount: row.read<int>('artist_count'),
    );
  }

  @override
  Future<List<LocalLibraryArtist>> listArtists(
      {String query = '',
      LocalArtistSortOrder sort = LocalArtistSortOrder.name,
      int limit = 100,
      int offset = 0}) async {
    final order = switch (sort) {
      LocalArtistSortOrder.name =>
        'display_name COLLATE NOCASE ASC, artist_key ASC',
      LocalArtistSortOrder.albumCount =>
        'album_count DESC, display_name COLLATE NOCASE ASC, artist_key ASC',
      LocalArtistSortOrder.trackCount =>
        'track_count DESC, display_name COLLATE NOCASE ASC, artist_key ASC',
      LocalArtistSortOrder.recentlyAdded =>
        'recently_added DESC, display_name COLLATE NOCASE ASC, artist_key ASC',
    };
    final rows = await database.customSelect('''
      SELECT $_normalizedAlbumArtistSql AS artist_key,
        MIN($_resolvedAlbumArtistSql) AS display_name,
        COUNT(DISTINCT t.id) AS track_count,
        COUNT(DISTINCT $_albumKeySql) AS album_count,
        MAX(t.added_at) AS recently_added
      FROM stored_local_library_tracks t
      WHERE t.is_available = 1
        AND (lower($_resolvedAlbumArtistSql) LIKE ?
          OR lower(t.artists_json) LIKE ?)
      GROUP BY $_normalizedAlbumArtistSql
      ORDER BY $order LIMIT ? OFFSET ?
    ''', variables: [
      Variable('%${query.trim().toLowerCase()}%'),
      Variable('%${query.trim().toLowerCase()}%'),
      Variable(limit),
      Variable(offset)
    ]).get();
    final keys = [for (final row in rows) row.read<String>('artist_key')];
    if (keys.isEmpty) return const [];

    final metadataRows =
        await (database.select(database.storedLocalArtistMetadata)
              ..where((row) => row.artistKey.isIn(keys)))
            .get();
    final metadataByKey = {
      for (final row in metadataRows)
        row.artistKey: _artistMetadataFromRow(row),
    };
    final artworkRows = await database.customSelect('''
      SELECT $_normalizedAlbumArtistSql AS artist_key, t.artwork_path
      FROM stored_local_library_tracks t
      WHERE t.is_available = 1
        AND t.artwork_path IS NOT NULL
        AND $_normalizedAlbumArtistSql
          IN (${List.filled(keys.length, '?').join(',')})
      ORDER BY t.added_at DESC
    ''', variables: [for (final key in keys) Variable(key)]).get();
    final artworksByKey = <String, List<String>>{};
    for (final row in artworkRows) {
      final key = row.read<String>('artist_key');
      final path = row.read<String>('artwork_path');
      final values = artworksByKey.putIfAbsent(key, () => []);
      if (values.length < 4 && !values.contains(path)) values.add(path);
    }

    return [
      for (final row in rows)
        LocalLibraryArtist(
          artistKey: row.read<String>('artist_key'),
          displayName: row.read<String>('display_name'),
          trackCount: row.read<int>('track_count'),
          albumCount: row.read<int>('album_count'),
          sampleArtworkPaths:
              artworksByKey[row.read<String>('artist_key')] ?? const [],
          metadata: metadataByKey[row.read<String>('artist_key')],
        ),
    ];
  }

  @override
  Future<LocalLibraryArtist?> getArtist(String artistKey) async {
    final normalized = _artistIdentity(artistKey);
    final values = await listArtists(query: artistKey, limit: 100000);
    return values.where((item) => item.artistKey == normalized).firstOrNull;
  }

  @override
  Future<List<LocalLibraryTrack>> listArtistTracks(String artistKey) async {
    final ids = await database.customSelect(
        '''SELECT t.id FROM stored_local_library_tracks t
           WHERE t.is_available = 1
             AND $_normalizedAlbumArtistSql = ?
           ORDER BY t.year, t.album, t.disc_number, t.track_number, t.title''',
        variables: [Variable(_artistIdentity(artistKey))]).get();
    return _tracksByIds(ids.map((r) => r.read<String>('id')).toList());
  }

  @override
  Future<List<LocalLibraryAlbum>> listArtistAlbums(String artistKey) async {
    final normalized = _artistIdentity(artistKey);
    final albums = await listAlbums(query: artistKey, limit: 100000);
    return albums
        .where((album) => _artistIdentity(album.albumArtist) == normalized)
        .toList(growable: false);
  }

  @override
  Future<List<LocalLibraryAlbum>> listAlbums(
      {String query = '',
      LocalAlbumSortOrder sort = LocalAlbumSortOrder.artist,
      int limit = 100,
      int offset = 0}) async {
    final order = switch (sort) {
      LocalAlbumSortOrder.artist =>
        'album_artist COLLATE NOCASE, title COLLATE NOCASE, album_key ASC',
      LocalAlbumSortOrder.title => 'title COLLATE NOCASE, album_key ASC',
      LocalAlbumSortOrder.year =>
        'canonical_year DESC, title COLLATE NOCASE, album_key ASC',
      LocalAlbumSortOrder.recentlyAdded => 'recently_added DESC, album_key ASC',
      LocalAlbumSortOrder.trackCount =>
        'track_count DESC, title COLLATE NOCASE, album_key ASC',
    };
    final rows = await database.customSelect('''
      WITH base AS (
        SELECT t.*, $_resolvedAlbumArtistSql AS resolved_album_artist,
          $_albumKeySql AS album_key
        FROM stored_local_library_tracks t
        WHERE t.is_available = 1
      ), matched_keys AS (
        SELECT DISTINCT matched.album_key FROM base matched
        WHERE lower(COALESCE(matched.album, '')) LIKE ?
          OR lower(matched.resolved_album_artist) LIKE ?
          OR lower(matched.artists_json) LIKE ?
      ), album_groups AS (
        SELECT b.album_key,
          MIN(COALESCE(NULLIF(trim(b.album), ''), '未知专辑')) AS title,
          MIN(b.resolved_album_artist) AS album_artist,
          COUNT(*) AS track_count,
          SUM(b.duration_ms) AS duration_ms,
          MAX(b.artwork_path) AS artwork_path,
          MAX(b.added_at) AS recently_added
        FROM base b INNER JOIN matched_keys matched
          ON matched.album_key = b.album_key
        GROUP BY b.album_key
      ), year_counts AS (
        SELECT album_key, year, COUNT(*) AS year_count FROM base
        WHERE year IS NOT NULL GROUP BY album_key, year
      ), canonical_years AS (
        SELECT candidate.album_key, candidate.year FROM year_counts candidate
        LEFT JOIN year_counts better
          ON better.album_key = candidate.album_key
          AND (better.year_count > candidate.year_count
            OR (better.year_count = candidate.year_count
              AND better.year < candidate.year))
        WHERE better.album_key IS NULL
      ), observed_years AS (
        SELECT ordered.album_key, group_concat(ordered.year, ',') AS years
        FROM (SELECT album_key, year FROM year_counts
          ORDER BY album_key, year) ordered
        GROUP BY ordered.album_key
      ), year_flags AS (
        SELECT album_key, COUNT(DISTINCT year) AS distinct_year_count,
          MAX(year IS NULL) AS has_missing_year,
          MAX(year IS NOT NULL) AS has_dated_year
        FROM base GROUP BY album_key
      ), source_counts AS (
        SELECT album_key, album_artist_source, COUNT(*) AS source_count,
          CASE album_artist_source
            WHEN 'userOverride' THEN 6
            WHEN 'embeddedTag' THEN 5
            WHEN 'directoryConsensus' THEN 4
            WHEN 'albumConsensus' THEN 3
            WHEN 'trackArtistFallback' THEN 2
            WHEN 'variousArtists' THEN 1
            ELSE 0 END AS source_priority
        FROM base GROUP BY album_key, album_artist_source
      ), album_sources AS (
        SELECT candidate.album_key, candidate.album_artist_source
        FROM source_counts candidate
        LEFT JOIN source_counts better
          ON better.album_key = candidate.album_key
          AND (better.source_priority > candidate.source_priority
            OR (better.source_priority = candidate.source_priority
              AND better.source_count > candidate.source_count))
        WHERE better.album_key IS NULL
      )
      SELECT g.*, canonical.year AS canonical_year,
        observed.years AS observed_years,
        (flags.distinct_year_count > 1
          OR (flags.has_missing_year > 0 AND flags.has_dated_year > 0)
        ) AS has_year_conflict,
        source.album_artist_source
      FROM album_groups g
      LEFT JOIN canonical_years canonical ON canonical.album_key = g.album_key
      LEFT JOIN observed_years observed ON observed.album_key = g.album_key
      INNER JOIN year_flags flags ON flags.album_key = g.album_key
      LEFT JOIN album_sources source ON source.album_key = g.album_key
      ORDER BY $order LIMIT ? OFFSET ?
    ''', variables: [
      Variable('%${query.trim().toLowerCase()}%'),
      Variable('%${query.trim().toLowerCase()}%'),
      Variable('%${query.trim().toLowerCase()}%'),
      Variable(limit),
      Variable(offset)
    ]).get();
    return [
      for (final row in rows)
        LocalLibraryAlbum(
            albumKey: row.read<String>('album_key'),
            title: row.read<String>('title'),
            albumArtist: row.read<String>('album_artist'),
            canonicalYear: row.readNullable<int>('canonical_year'),
            observedYears: _observedYears(row),
            hasYearConflict: row.read<int>('has_year_conflict') != 0,
            albumArtistSource: LocalAlbumArtistSource.values.firstWhere(
              (source) =>
                  source.name ==
                  row.readNullable<String>('album_artist_source'),
              orElse: () => LocalAlbumArtistSource.unresolved,
            ),
            trackCount: row.read<int>('track_count'),
            duration: Duration(milliseconds: row.read<int>('duration_ms')),
            artworkPath: row.readNullable<String>('artwork_path'))
    ];
  }

  List<int> _observedYears(QueryRow row) {
    final encoded = row.readNullable<String>('observed_years');
    if (encoded == null || encoded.isEmpty) return const [];
    return encoded.split(',').map(int.parse).toList(growable: false);
  }

  String _artistIdentity(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[／\\]'), '/');

  @override
  Future<LocalLibraryAlbum?> getAlbum(String albumKey) async {
    final values = await listAlbums(limit: 100000);
    return values.where((item) => item.albumKey == albumKey).firstOrNull;
  }

  @override
  Future<List<LocalLibraryTrack>> listAlbumTracks(String albumKey) async {
    final ids = await database.customSelect(
        '''SELECT t.id FROM stored_local_library_tracks t
           WHERE t.is_available = 1 AND $_albumKeySql = ?
           ORDER BY t.disc_number, t.track_number, t.title''',
        variables: [Variable(albumKey)]).get();
    return _tracksByIds(ids.map((r) => r.read<String>('id')).toList());
  }

  Future<List<LocalLibraryTrack>> _tracksByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    final rows =
        await _trackQuery(database.storedLocalLibraryTracks.id.isIn(ids)).get();
    final byId = {
      for (final row in rows)
        row.readTable(database.storedLocalLibraryTracks).id:
            _trackFromJoinedRow(row)
    };
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!
    ];
  }

  @override
  Future<LocalArtistMetadata?> getArtistMetadata(String artistKey) async {
    final row = await (database.select(database.storedLocalArtistMetadata)
          ..where((t) => t.artistKey.equals(artistKey)))
        .getSingleOrNull();
    if (row == null) return null;
    return _artistMetadataFromRow(row);
  }

  LocalArtistMetadata _artistMetadataFromRow(
    db.StoredLocalArtistMetadataData row,
  ) {
    return LocalArtistMetadata(
        artistKey: row.artistKey,
        displayName: row.displayName,
        status: ArtistMetadataStatus.values.firstWhere(
            (v) => v.name == row.status,
            orElse: () => ArtistMetadataStatus.pending),
        sourceProviderId: row.sourceProviderId == null
            ? null
            : ProviderId(row.sourceProviderId!),
        remoteArtistId: row.remoteArtistId,
        remoteName: row.remoteName,
        avatarUrl: row.avatarUrl,
        avatarCachePath: row.avatarCachePath,
        backgroundUrl: row.backgroundUrl,
        backgroundCachePath: row.backgroundCachePath,
        description: row.description,
        confidence: row.confidence,
        userConfirmed: row.userConfirmed,
        fetchedAt: row.fetchedAt,
        retryAfter: row.retryAfter);
  }

  @override
  Future<void> upsertArtistMetadata(LocalArtistMetadata value) => database
      .into(database.storedLocalArtistMetadata)
      .insertOnConflictUpdate(db.StoredLocalArtistMetadataCompanion.insert(
          artistKey: value.artistKey,
          displayName: value.displayName,
          status: value.status.name,
          sourceProviderId: Value(value.sourceProviderId?.value),
          remoteArtistId: Value(value.remoteArtistId),
          remoteName: Value(value.remoteName),
          avatarUrl: Value(value.avatarUrl),
          avatarCachePath: Value(value.avatarCachePath),
          backgroundUrl: Value(value.backgroundUrl),
          backgroundCachePath: Value(value.backgroundCachePath),
          description: Value(value.description),
          confidence: Value(value.confidence),
          userConfirmed: Value(value.userConfirmed),
          fetchedAt: Value(value.fetchedAt),
          retryAfter: Value(value.retryAfter)));

  @override
  Future<LocalTrackMatch?> findLocalMatch(ProviderTrackRef remote) async {
    final row = await (database.select(database.storedLocalTrackMatches)
          ..where((t) =>
              t.providerId.equalsExp(Variable(remote.providerId.value)) &
              t.providerTrackId.equalsExp(Variable(remote.trackId))))
        .getSingleOrNull();
    return row == null
        ? null
        : LocalTrackMatch(
            remote: remote,
            localTrackId: row.localTrackId,
            method: row.matchMethod,
            confidence: row.confidence,
            updatedAt: row.updatedAt);
  }

  @override
  Future<void> upsertLocalTrackMatch(LocalTrackMatch value) => database
      .into(database.storedLocalTrackMatches)
      .insertOnConflictUpdate(db.StoredLocalTrackMatchesCompanion.insert(
          providerId: value.remote.providerId.value,
          providerTrackId: value.remote.trackId,
          localTrackId: value.localTrackId,
          matchMethod: value.method,
          confidence: value.confidence,
          updatedAt: value.updatedAt));

  @override
  Future<void> removeLocalTrackMatch(ProviderTrackRef remote) =>
      (database.delete(database.storedLocalTrackMatches)
            ..where((t) =>
                t.providerId.equalsExp(Variable(remote.providerId.value)) &
                t.providerTrackId.equalsExp(Variable(remote.trackId))))
          .go();
}

Iterable<List<T>> _chunks<T>(List<T> values, int size) sync* {
  for (var i = 0; i < values.length; i += size) {
    final end = i + size < values.length ? i + size : values.length;
    yield values.sublist(i, end);
  }
}
