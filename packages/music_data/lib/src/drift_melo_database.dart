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
  ],
)
class MeloDriftDatabase extends _$MeloDriftDatabase {
  MeloDriftDatabase(super.executor);

  static const currentSchemaVersion = 3;

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
        },
      );
}
