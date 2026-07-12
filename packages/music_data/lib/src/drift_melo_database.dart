import 'package:drift/drift.dart';

part 'drift_melo_database.g.dart';

class MeloMetaRows extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

class StoredPlaylists extends Table {
  TextColumn get id => text()();
  IntColumn get sortIndex => integer()();
  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StoredDownloadTasks extends Table {
  TextColumn get refKey => text()();
  IntColumn get sortIndex => integer()();
  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {refKey};
}

class StoredLocalMediaItems extends Table {
  TextColumn get refKey => text()();
  IntColumn get sortIndex => integer()();
  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {refKey};
}

class StoredFavoriteOverrides extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  IntColumn get sortIndex => integer()();
  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FavoriteProviderTracks extends Table {
  TextColumn get providerId => text()();
  TextColumn get refKey => text()();
  IntColumn get sortIndex => integer()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get rawLikedAt => dateTime().nullable()();
  TextColumn get likedAtSource => text().nullable()();
  TextColumn get likedAtPrecision => text().nullable()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {providerId, refKey};
}

class FavoriteLikedAtLedgerRows extends Table {
  TextColumn get identityKey => text()();
  TextColumn get refJson => text()();
  TextColumn get metadataJson => text()();
  DateTimeColumn get updatedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {identityKey};
}

class UnifiedFavoriteCacheRows extends Table {
  TextColumn get unifiedId => text()();
  IntColumn get sortIndex => integer()();
  DateTimeColumn get sortLikedAt => dateTime().nullable()();
  DateTimeColumn get builtAt => dateTime()();
  TextColumn get payloadJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {unifiedId};
}

class FavoriteProviderStates extends Table {
  TextColumn get providerId => text()();
  DateTimeColumn get lastSuccessAt => dateTime().nullable()();
  DateTimeColumn get lastFailureAt => dateTime().nullable()();
  TextColumn get lastFailureMessage => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {providerId};
}

class StoredAudioCacheEntries extends Table {
  TextColumn get identityKey => text()();
  TextColumn get providerId => text()();
  TextColumn get trackId => text()();
  TextColumn get quality => text()();
  TextColumn get filePath => text()();
  IntColumn get fileSize => integer()();
  DateTimeColumn get completedAt => dateTime()();
  DateTimeColumn get lastAccessedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {identityKey};
}

class AudioCacheSettings extends Table {
  IntColumn get id => integer()();
  BoolColumn get enabled => boolean()();
  BoolColumn get wifiOnly => boolean()();
  IntColumn get maxBytes => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StoredLocalLibraryRoots extends Table {
  TextColumn get id => text()();
  TextColumn get path => text().unique()();
  TextColumn get displayName => text()();
  TextColumn get scanState => text()();
  DateTimeColumn get lastScannedAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StoredLocalLibraryTracks extends Table {
  TextColumn get id => text()();
  TextColumn get rootId => text()();
  TextColumn get filePath => text().unique()();
  TextColumn get relativePath => text()();
  IntColumn get fileSize => integer()();
  DateTimeColumn get modifiedAt => dateTime()();
  TextColumn get fingerprint => text()();
  TextColumn get title => text()();
  TextColumn get artistsJson => text()();
  IntColumn get durationMs => integer()();
  TextColumn get format => text()();
  TextColumn get album => text().nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get year => integer().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  TextColumn get lyrics => text().nullable()();
  TextColumn get artworkPath => text().nullable()();
  BoolColumn get isAvailable => boolean().withDefault(const Constant(true))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class StoredLocalLibraryFavorites extends Table {
  TextColumn get trackId => text()();
  DateTimeColumn get likedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {trackId};
}

@DriftDatabase(
  tables: [
    MeloMetaRows,
    StoredPlaylists,
    StoredDownloadTasks,
    StoredLocalMediaItems,
    StoredFavoriteOverrides,
    FavoriteProviderTracks,
    FavoriteLikedAtLedgerRows,
    UnifiedFavoriteCacheRows,
    FavoriteProviderStates,
    StoredAudioCacheEntries,
    AudioCacheSettings,
    StoredLocalLibraryRoots,
    StoredLocalLibraryTracks,
    StoredLocalLibraryFavorites,
  ],
)
class MeloDriftDatabase extends _$MeloDriftDatabase {
  MeloDriftDatabase(super.executor);

  static const currentSchemaVersion = 4;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(favoriteProviderTracks);
            await m.createTable(favoriteLikedAtLedgerRows);
            await m.createTable(unifiedFavoriteCacheRows);
            await m.createTable(favoriteProviderStates);
          }
          if (from < 3) {
            await m.createTable(storedAudioCacheEntries);
            await m.createTable(audioCacheSettings);
          }
          if (from < 4) {
            await m.createTable(storedLocalLibraryRoots);
            await m.createTable(storedLocalLibraryTracks);
            await m.createTable(storedLocalLibraryFavorites);
          }
        },
        beforeOpen: (details) async {
          await _ensureLocalLibraryColumns();
        },
      );

  Future<void> _ensureLocalLibraryColumns() async {
    // Create tables if they don't exist (handles cases where the schema
    // version is already 4 but tables were dropped or never created).
    await customStatement(
      'CREATE TABLE IF NOT EXISTS "stored_local_library_roots" ('
      '"id" TEXT NOT NULL, '
      '"path" TEXT NOT NULL UNIQUE, '
      '"display_name" TEXT NOT NULL, '
      '"scan_state" TEXT NOT NULL, '
      '"last_scanned_at" INTEGER, '
      '"last_error" TEXT, '
      'PRIMARY KEY ("id"))',
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS "stored_local_library_tracks" ('
      '"id" TEXT NOT NULL, '
      '"root_id" TEXT NOT NULL, '
      '"file_path" TEXT NOT NULL UNIQUE, '
      '"relative_path" TEXT NOT NULL, '
      '"file_size" INTEGER NOT NULL, '
      '"modified_at" INTEGER NOT NULL, '
      '"fingerprint" TEXT NOT NULL, '
      '"title" TEXT NOT NULL, '
      '"artists_json" TEXT NOT NULL, '
      '"duration_ms" INTEGER NOT NULL DEFAULT 0, '
      '"format" TEXT NOT NULL, '
      '"album" TEXT, '
      '"genre" TEXT, '
      '"year" INTEGER, '
      '"track_number" INTEGER, '
      '"disc_number" INTEGER, '
      '"lyrics" TEXT, '
      '"artwork_path" TEXT, '
      '"is_available" INTEGER NOT NULL DEFAULT 1, '
      'PRIMARY KEY ("id"))',
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS "stored_local_library_favorites" ('
      '"track_id" TEXT NOT NULL, '
      '"liked_at" INTEGER NOT NULL, '
      'PRIMARY KEY ("track_id"))',
    );

    final rootColumns = await _columnNames('stored_local_library_roots');
    if (rootColumns.isNotEmpty) {
      await _addColumnIfMissing(
        'stored_local_library_roots',
        rootColumns,
        'display_name',
        "TEXT NOT NULL DEFAULT ''",
      );
      await _addColumnIfMissing(
        'stored_local_library_roots',
        rootColumns,
        'scan_state',
        "TEXT NOT NULL DEFAULT 'idle'",
      );
      await _addColumnIfMissing(
        'stored_local_library_roots',
        rootColumns,
        'last_error',
        'TEXT',
      );
      await customStatement(
        "UPDATE stored_local_library_roots SET display_name = path "
        "WHERE display_name = ''",
      );
    }

    final trackColumns = await _columnNames('stored_local_library_tracks');
    if (trackColumns.isNotEmpty) {
      final additions = <String, String>{
        'relative_path': "TEXT NOT NULL DEFAULT ''",
        'fingerprint': "TEXT NOT NULL DEFAULT ''",
        'title': "TEXT NOT NULL DEFAULT ''",
        'artists_json': "TEXT NOT NULL DEFAULT '[]'",
        'duration_ms': 'INTEGER NOT NULL DEFAULT 0',
        'format': "TEXT NOT NULL DEFAULT ''",
        'album': 'TEXT',
        'genre': 'TEXT',
        'year': 'INTEGER',
        'track_number': 'INTEGER',
        'disc_number': 'INTEGER',
        'lyrics': 'TEXT',
        'artwork_path': 'TEXT',
        'is_available': 'INTEGER NOT NULL DEFAULT 1',
      };
      for (final entry in additions.entries) {
        await _addColumnIfMissing(
          'stored_local_library_tracks',
          trackColumns,
          entry.key,
          entry.value,
        );
      }
      if (trackColumns.contains('content_hash')) {
        await customStatement(
          "UPDATE stored_local_library_tracks SET fingerprint = content_hash "
          "WHERE fingerprint = ''",
        );
      }
      if (trackColumns.contains('is_missing')) {
        await customStatement(
          'UPDATE stored_local_library_tracks '
          'SET is_available = CASE WHEN is_missing = 0 THEN 1 ELSE 0 END',
        );
      }
      if (trackColumns.contains('is_favorited')) {
        await customStatement(
          'INSERT OR IGNORE INTO stored_local_library_favorites(track_id, liked_at) '
          "SELECT id, COALESCE(liked_at, strftime('%s','now')) * 1000 "
          'FROM stored_local_library_tracks WHERE is_favorited = 1',
        );
      }
    }
  }

  Future<Set<String>> _columnNames(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return rows
        .map((row) => row.data['name']?.toString())
        .whereType<String>()
        .toSet();
  }

  Future<void> _addColumnIfMissing(
    String table,
    Set<String> columns,
    String name,
    String definition,
  ) async {
    if (columns.contains(name)) return;
    await customStatement('ALTER TABLE $table ADD COLUMN $name $definition');
    columns.add(name);
  }
}
