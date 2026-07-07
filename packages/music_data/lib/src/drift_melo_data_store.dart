import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:music_domain/music_domain.dart';
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
    final favoriteRows = await (database.select(database.favoriteProviderTracks)
          ..orderBy([
            (row) => OrderingTerm.asc(row.providerId),
            (row) => OrderingTerm.asc(row.sortIndex),
          ]))
        .get();
    final ledgerRows =
        await database.select(database.favoriteLikedAtLedgerRows).get();
    final unifiedRows =
        await (database.select(database.unifiedFavoriteCacheRows)
              ..orderBy([(row) => OrderingTerm.asc(row.sortIndex)]))
            .get();
    final providerStateRows =
        await database.select(database.favoriteProviderStates).get();

    return _codec.decodeSnapshot({
      'schemaVersion': int.parse(version),
      'playbackQuality': metaRows
          .where((row) => row.key == 'playbackQuality')
          .firstOrNull
          ?.value,
      'volume': double.tryParse(
        metaRows.where((row) => row.key == 'volume').firstOrNull?.value ?? '',
      ),
      'downloadDirectory': metaRows
          .where((row) => row.key == 'downloadDirectory')
          .firstOrNull
          ?.value,
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
      'favoriteProviderSnapshots': _decodeFavoriteProviderSnapshots(
        favoriteRows,
      ),
      'favoriteLikedAtLedger': [
        for (final row in ledgerRows)
          {
            'ref': _jsonMap(row.refJson),
            'metadata': _jsonMap(row.metadataJson),
            'updatedAt': row.updatedAt?.toUtc().toIso8601String(),
          },
      ],
      'unifiedFavoritesCache': unifiedRows.isEmpty
          ? null
          : {
              'builtAt': unifiedRows.first.builtAt.toUtc().toIso8601String(),
              'tracks': [
                for (final row in unifiedRows) _jsonMap(row.payloadJson),
              ],
            },
      'favoriteProviderStates': [
        for (final row in providerStateRows)
          {
            'providerId': row.providerId,
            'lastSuccessAt': row.lastSuccessAt?.toUtc().toIso8601String(),
            'lastFailureAt': row.lastFailureAt?.toUtc().toIso8601String(),
            'lastFailureMessage': row.lastFailureMessage,
          },
      ],
    });
  }

  @override
  Future<void> write(MeloDataSnapshot snapshot) async {
    final encoded = _codec.encodeSnapshot(snapshot);
    final playlists = _jsonMapList(encoded['playlists']);
    final downloadTasks = _jsonMapList(encoded['downloadTasks']);
    final localMediaItems = _jsonMapList(encoded['localMediaItems']);
    final favoriteProviderSnapshots =
        _jsonMapList(encoded['favoriteProviderSnapshots']);
    final likedAtLedger = _jsonMapList(encoded['favoriteLikedAtLedger']);
    final unifiedFavoritesCache = encoded['unifiedFavoritesCache'] == null
        ? null
        : Map<String, Object?>.from(encoded['unifiedFavoritesCache']! as Map);
    final favoriteProviderStates =
        _jsonMapList(encoded['favoriteProviderStates']);
    final overrides = Map<String, Object?>.from(
      encoded['favoritesOverrides']! as Map,
    );

    await database.transaction(() async {
      await database.delete(database.meloMetaRows).go();
      await database.delete(database.storedPlaylists).go();
      await database.delete(database.storedDownloadTasks).go();
      await database.delete(database.storedLocalMediaItems).go();
      await database.delete(database.storedFavoriteOverrides).go();
      await database.delete(database.favoriteProviderTracks).go();
      await database.delete(database.favoriteLikedAtLedgerRows).go();
      await database.delete(database.unifiedFavoriteCacheRows).go();
      await database.delete(database.favoriteProviderStates).go();

      await database.into(database.meloMetaRows).insert(
            MeloMetaRowsCompanion.insert(
              key: 'schemaVersion',
              value: MeloJsonCodec.schemaVersion.toString(),
            ),
          );
      await database.into(database.meloMetaRows).insert(
            MeloMetaRowsCompanion.insert(
              key: 'playbackQuality',
              value: snapshot.playbackQuality.name,
            ),
          );
      await database.into(database.meloMetaRows).insert(
            MeloMetaRowsCompanion.insert(
              key: 'volume',
              value: snapshot.volume.toStringAsFixed(4),
            ),
          );
      if (snapshot.downloadDirectory != null) {
        await database.into(database.meloMetaRows).insert(
              MeloMetaRowsCompanion.insert(
                key: 'downloadDirectory',
                value: snapshot.downloadDirectory!,
              ),
            );
      }

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
      await _writeFavoriteProviderRows(favoriteProviderSnapshots);
      await _writeLikedAtLedgerRows(likedAtLedger);
      await _writeUnifiedFavoriteCacheRows(unifiedFavoritesCache);
      await _writeFavoriteProviderStateRows(favoriteProviderStates);
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
      await database.delete(database.favoriteProviderTracks).go();
      await database.delete(database.favoriteLikedAtLedgerRows).go();
      await database.delete(database.unifiedFavoriteCacheRows).go();
      await database.delete(database.favoriteProviderStates).go();
    });
  }

  Future<void> _writeFavoriteProviderRows(
    List<Map<String, Object?>> snapshots,
  ) async {
    for (final snapshot in snapshots) {
      final providerId = snapshot['providerId']! as String;
      final fetchedAt =
          DateTime.parse(snapshot['fetchedAt']! as String).toUtc();
      final tracks = _jsonMapList(snapshot['tracks']);
      for (var i = 0; i < tracks.length; i++) {
        final track = tracks[i];
        final ref = _trackRefFromMap(track['ref']! as Map);
        await database.into(database.favoriteProviderTracks).insert(
              FavoriteProviderTracksCompanion.insert(
                providerId: providerId,
                refKey: _refKey(ref),
                sortIndex: i,
                payloadJson: jsonEncode(track),
                rawLikedAt: Value(_optionalDateTime(track['likedAt'])),
                likedAtSource: Value(track['likedAtSource'] as String?),
                likedAtPrecision: Value(track['likedAtPrecision'] as String?),
                fetchedAt: fetchedAt,
              ),
            );
      }
    }
  }

  Future<void> _writeLikedAtLedgerRows(
    List<Map<String, Object?>> entries,
  ) async {
    for (final entry in entries) {
      final ref = Map<String, Object?>.from(entry['ref']! as Map);
      final metadata = Map<String, Object?>.from(entry['metadata']! as Map);
      await database.into(database.favoriteLikedAtLedgerRows).insert(
            FavoriteLikedAtLedgerRowsCompanion.insert(
              identityKey: _likedAtIdentityKey(_trackRefFromMap(ref)),
              refJson: jsonEncode(ref),
              metadataJson: jsonEncode(metadata),
              updatedAt: Value(_optionalDateTime(entry['updatedAt'])),
            ),
          );
    }
  }

  Future<void> _writeUnifiedFavoriteCacheRows(
    Map<String, Object?>? cache,
  ) async {
    if (cache == null) return;
    final builtAt = DateTime.parse(cache['builtAt']! as String).toUtc();
    final tracks = _jsonMapList(cache['tracks']);
    for (var i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      await database.into(database.unifiedFavoriteCacheRows).insert(
            UnifiedFavoriteCacheRowsCompanion.insert(
              unifiedId: track['unifiedId']! as String,
              sortIndex: i,
              sortLikedAt: Value(_bestLikedAtFromUnifiedJson(track)),
              builtAt: builtAt,
              payloadJson: jsonEncode(track),
            ),
          );
    }
  }

  Future<void> _writeFavoriteProviderStateRows(
    List<Map<String, Object?>> states,
  ) async {
    for (final state in states) {
      await database.into(database.favoriteProviderStates).insert(
            FavoriteProviderStatesCompanion.insert(
              providerId: state['providerId']! as String,
              lastSuccessAt: Value(_optionalDateTime(state['lastSuccessAt'])),
              lastFailureAt: Value(_optionalDateTime(state['lastFailureAt'])),
              lastFailureMessage: Value(state['lastFailureMessage'] as String?),
            ),
          );
    }
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

  List<Map<String, Object?>> _decodeFavoriteProviderSnapshots(
    List<FavoriteProviderTrack> rows,
  ) {
    final byProvider = <String, List<FavoriteProviderTrack>>{};
    for (final row in rows) {
      byProvider.putIfAbsent(row.providerId, () => []).add(row);
    }
    return [
      for (final entry in byProvider.entries)
        {
          'providerId': entry.key,
          'fetchedAt': entry.value.first.fetchedAt.toUtc().toIso8601String(),
          'tracks': [
            for (final row in entry.value) _jsonMap(row.payloadJson),
          ],
        },
    ];
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

  String _likedAtIdentityKey(ProviderTrackRef ref) {
    final keys = FavoritesOverrideRegistry.likedAtIdentityKeys(ref).toList()
      ..sort();
    final songIdKeys = keys.where((key) => key.contains(':song_id:'));
    return songIdKeys.isNotEmpty ? songIdKeys.first : keys.first;
  }

  DateTime? _optionalDateTime(Object? value) {
    final text = value?.toString();
    if (text == null || text.trim().isEmpty) return null;
    return DateTime.tryParse(text)?.toUtc();
  }

  DateTime? _bestLikedAtFromUnifiedJson(Map<String, Object?> track) {
    DateTime? best;
    for (final variant in _jsonMapList(track['variants'])) {
      final likedAt = _optionalDateTime(variant['likedAt']);
      if (likedAt != null && (best == null || likedAt.isAfter(best))) {
        best = likedAt;
      }
    }
    return best;
  }
}
