import 'audio_cache_models.dart';

abstract interface class AudioCacheStore {
  Future<AudioCachePolicy?> readPolicy();
  Future<void> writePolicy(AudioCachePolicy policy);
  Future<List<AudioCacheEntry>> readEntries();
  Future<void> upsertEntry(AudioCacheEntry entry);
  Future<void> removeEntry(AudioCacheEntry entry);
  Future<void> removeEntries(Iterable<AudioCacheEntry> entries);
}
