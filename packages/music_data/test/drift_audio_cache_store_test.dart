import 'package:drift/native.dart';
import 'package:music_data/music_data_drift.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:test/test.dart';

void main() {
  late MeloDriftDatabase database;
  late DriftAudioCacheStore store;

  setUp(() {
    database = MeloDriftDatabase(NativeDatabase.memory());
    store = DriftAudioCacheStore(database: database);
  });

  tearDown(() => database.close());

  test('persists policy and replaces the entry for a stable track identity',
      () async {
    const policy = AudioCachePolicy(
      enabled: true,
      wifiOnly: true,
      maxBytes: 1024,
    );
    await store.writePolicy(policy);
    expect(await store.readPolicy(), isNotNull);
    expect((await store.readPolicy())!.maxBytes, 1024);

    final now = DateTime.utc(2026, 7, 10);
    final original = AudioCacheEntry(
      providerId: ProviderId('alpha_music'),
      trackId: 'track_1',
      quality: AudioQuality.standard,
      filePath: '/cache/track_1.mp3',
      fileSize: 100,
      completedAt: now,
      lastAccessedAt: now,
    );
    await store.upsertEntry(original);
    await store.upsertEntry(AudioCacheEntry(
      providerId: original.providerId,
      trackId: original.trackId,
      quality: AudioQuality.lossless,
      filePath: '/cache/track_1.flac',
      fileSize: 300,
      completedAt: now,
      lastAccessedAt: now.add(const Duration(minutes: 1)),
    ));

    final entries = await store.readEntries();
    expect(entries, hasLength(1));
    expect(entries.single.quality, AudioQuality.lossless);
    expect(entries.single.filePath, endsWith('.flac'));
  });
}
