import 'package:drift/drift.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

import 'drift_melo_database.dart';

final class DriftAudioCacheStore implements AudioCacheStore {
  DriftAudioCacheStore({required this.database});

  final MeloDriftDatabase database;

  @override
  Future<AudioCachePolicy?> readPolicy() async {
    final row = await (database.select(database.audioCacheSettings)
          ..where((table) => table.id.equals(1)))
        .getSingleOrNull();
    if (row == null) return null;
    return AudioCachePolicy(
      enabled: row.enabled,
      wifiOnly: row.wifiOnly,
      maxBytes: row.maxBytes,
    );
  }

  @override
  Future<void> writePolicy(AudioCachePolicy policy) async {
    await database.into(database.audioCacheSettings).insertOnConflictUpdate(
          AudioCacheSettingsCompanion.insert(
            id: const Value(1),
            enabled: policy.enabled,
            wifiOnly: policy.wifiOnly,
            maxBytes: policy.maxBytes,
          ),
        );
  }

  @override
  Future<List<AudioCacheEntry>> readEntries() async {
    final rows = await database.select(database.storedAudioCacheEntries).get();
    return [
      for (final row in rows)
        AudioCacheEntry(
          providerId: ProviderId(row.providerId),
          trackId: row.trackId,
          quality: AudioQuality.values.byName(row.quality),
          filePath: row.filePath,
          fileSize: row.fileSize,
          completedAt: row.completedAt.toUtc(),
          lastAccessedAt: row.lastAccessedAt.toUtc(),
        ),
    ];
  }

  @override
  Future<void> upsertEntry(AudioCacheEntry entry) async {
    await database
        .into(database.storedAudioCacheEntries)
        .insertOnConflictUpdate(
          StoredAudioCacheEntriesCompanion.insert(
            identityKey: entry.identityKey,
            providerId: entry.providerId.value,
            trackId: entry.trackId,
            quality: entry.quality.name,
            filePath: entry.filePath,
            fileSize: entry.fileSize,
            completedAt: entry.completedAt.toUtc(),
            lastAccessedAt: entry.lastAccessedAt.toUtc(),
          ),
        );
  }

  @override
  Future<void> removeEntry(AudioCacheEntry entry) async {
    await (database.delete(database.storedAudioCacheEntries)
          ..where((table) => table.identityKey.equals(entry.identityKey)))
        .go();
  }

  @override
  Future<void> removeEntries(Iterable<AudioCacheEntry> entries) async {
    await database.batch((batch) {
      for (final entry in entries) {
        batch.deleteWhere(
          database.storedAudioCacheEntries,
          (table) => table.identityKey.equals(entry.identityKey),
        );
      }
    });
  }
}
