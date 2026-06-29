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

@DriftDatabase(
  tables: [
    MeloMetaRows,
    StoredPlaylists,
    StoredDownloadTasks,
    StoredLocalMediaItems,
    StoredFavoriteOverrides,
  ],
)
class MeloDriftDatabase extends _$MeloDriftDatabase {
  MeloDriftDatabase(super.executor);

  static const currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;
}
