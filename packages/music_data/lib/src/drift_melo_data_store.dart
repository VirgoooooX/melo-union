import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:provider_contract/provider_contract.dart';

import 'drift_melo_database.dart';
import 'melo_data_snapshot.dart';
import 'melo_json_codec.dart';
import 'melo_snapshot_store.dart';

final class DriftMeloDataStore implements MeloSnapshotStore {
  DriftMeloDataStore({
    required this.database,
    MeloJsonCodec codec = const MeloJsonCodec(),
  }) : _codec = codec;

  final MeloDriftDatabase database;
  final MeloJsonCodec _codec;

  @override
  Future<MeloDataSnapshot> read() async {
    final metaRows = await database.select(database.meloMetaRows).get();
    final version = metaRows
            .where((row) => row.key == 'schemaVersion')
            .firstOrNull
            ?.value ??
        MeloJsonCodec.schemaVersion.toString();

    final playlistRows = await (database.select(database.storedPlaylists)
          ..orderBy([(row) => OrderingTerm.asc(row.sortIndex)]))
        .get();
    final taskRows = await (database.select(database.storedDownloadTasks)
          ..orderBy([(row) => OrderingTerm.asc(row.sortIndex)]))
        .get();
    final mediaRows = await (database.select(database.storedLocalMediaItems)
          ..orderBy([(row) => OrderingTerm.asc(row.sortIndex)]))
        .get();
    final overrideRows =
        await (database.select(database.storedFavoriteOverrides)
              ..orderBy([(row) => OrderingTerm.asc(row.sortIndex)]))
            .get();

    return _codec.decodeSnapshot({
      'schemaVersion': int.parse(version),
      'playlists': [
        for (final row in playlistRows) _jsonMap(row.payloadJson),
      ],
      'downloadTasks': [
        for (final row in taskRows) _jsonMap(row.payloadJson),
      ],
      'localMediaItems': [
        for (final row in mediaRows) _jsonMap(row.payloadJson),
      ],
      'favoritesOverrides': _decodeOverrides(overrideRows),
    });
  }

  @override
  Future<void> write(MeloDataSnapshot snapshot) async {
    final encoded = _codec.encodeSnapshot(snapshot);
    final playlists = _jsonMapList(encoded['playlists']);
    final downloadTasks = _jsonMapList(encoded['downloadTasks']);
    final localMediaItems = _jsonMapList(encoded['localMediaItems']);
    final overrides = Map<String, Object?>.from(
      encoded['favoritesOverrides']! as Map,
    );

    await database.transaction(() async {
      await database.delete(database.meloMetaRows).go();
      await database.delete(database.storedPlaylists).go();
      await database.delete(database.storedDownloadTasks).go();
      await database.delete(database.storedLocalMediaItems).go();
      await database.delete(database.storedFavoriteOverrides).go();

      await database.into(database.meloMetaRows).insert(
            MeloMetaRowsCompanion.insert(
              key: 'schemaVersion',
              value: MeloJsonCodec.schemaVersion.toString(),
            ),
          );

      for (var i = 0; i < playlists.length; i++) {
        final playlist = playlists[i];
        await database.into(database.storedPlaylists).insert(
              StoredPlaylistsCompanion.insert(
                id: playlist['id']! as String,
                sortIndex: i,
                payloadJson: jsonEncode(playlist),
              ),
            );
      }

      for (var i = 0; i < downloadTasks.length; i++) {
        final task = downloadTasks[i];
        final ref = _trackRefFromSourceTrack(task['track']! as Map);
        await database.into(database.storedDownloadTasks).insert(
              StoredDownloadTasksCompanion.insert(
                refKey: _refKey(ref),
                sortIndex: i,
                payloadJson: jsonEncode(task),
              ),
            );
      }

      for (var i = 0; i < localMediaItems.length; i++) {
        final item = localMediaItems[i];
        final ref = _trackRefFromMap(item['sourceRef']! as Map);
        await database.into(database.storedLocalMediaItems).insert(
              StoredLocalMediaItemsCompanion.insert(
                refKey: _refKey(ref),
                sortIndex: i,
                payloadJson: jsonEncode(item),
              ),
            );
      }

      await _writeOverrideRows(overrides);
    });
  }

  @override
  Future<void> clear() async {
    await database.transaction(() async {
      await database.delete(database.meloMetaRows).go();
      await database.delete(database.storedPlaylists).go();
      await database.delete(database.storedDownloadTasks).go();
      await database.delete(database.storedLocalMediaItems).go();
      await database.delete(database.storedFavoriteOverrides).go();
    });
  }

  Future<void> _writeOverrideRows(Map<String, Object?> overrides) async {
    var index = 0;
    for (final entry in overrides.entries) {
      final items = entry.value as List<Object?>? ?? const [];
      for (var i = 0; i < items.length; i++) {
        await database.into(database.storedFavoriteOverrides).insert(
              StoredFavoriteOverridesCompanion.insert(
                id: '${entry.key}:$i',
                kind: entry.key,
                sortIndex: index++,
                payloadJson: jsonEncode(items[i]),
              ),
            );
      }
    }
  }

  Map<String, Object?> _decodeOverrides(List<StoredFavoriteOverride> rows) {
    final result = <String, List<Object?>>{
      'mergeOverrides': [],
      'splitOverrides': [],
      'hiddenTracks': [],
    };
    for (final row in rows) {
      result.putIfAbsent(row.kind, () => []).add(jsonDecode(row.payloadJson));
    }
    return result;
  }

  Map<String, Object?> _jsonMap(String payload) {
    return Map<String, Object?>.from(jsonDecode(payload) as Map);
  }

  List<Map<String, Object?>> _jsonMapList(Object? raw) {
    return [
      for (final item in raw as List<Object?>? ?? const [])
        Map<String, Object?>.from(item! as Map),
    ];
  }

  ProviderTrackRef _trackRefFromSourceTrack(Map<Object?, Object?> rawTrack) {
    final track = Map<String, Object?>.from(rawTrack);
    return _trackRefFromMap(track['ref']! as Map);
  }

  ProviderTrackRef _trackRefFromMap(Map<Object?, Object?> rawRef) {
    final ref = Map<String, Object?>.from(rawRef);
    return ProviderTrackRef(
      providerId: ProviderId(ref['providerId']! as String),
      trackId: ref['trackId']! as String,
      extraIds: {
        for (final entry
            in Map<String, Object?>.from(ref['extraIds']! as Map).entries)
          entry.key: entry.value! as String,
      },
    );
  }

  String _refKey(ProviderTrackRef ref) {
    final extra = ref.extraIds.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    final extraKey =
        extra.map((entry) => '${entry.key}=${entry.value}').join('&');
    return '${ref.providerId.value}:${ref.trackId}:$extraKey';
  }
}
