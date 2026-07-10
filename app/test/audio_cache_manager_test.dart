import 'dart:io';

import 'package:melo_union_app/src/bootstrap/audio_cache_manager.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reuses qualifying entries and prunes least recently used files',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('melo_audio_cache_');
    addTearDown(() => directory.delete(recursive: true));
    final store = _MemoryAudioCacheStore();
    final manager = await AudioCacheManager.open(
      store: store,
      directory: directory,
      defaultPolicy: const AudioCachePolicy(
        enabled: true,
        wifiOnly: true,
        maxBytes: 100,
      ),
    );
    final alpha = ProviderTrackRef(
      providerId: ProviderId('alpha_music'),
      trackId: 'track_a',
    );
    final beta = ProviderTrackRef(
      providerId: ProviderId('beta_music'),
      trackId: 'track_b',
    );
    final first = await manager.fileFor(
      alpha,
      AudioQuality.standard,
      Uri.parse('https://example.test/a.mp3'),
    );
    await first.writeAsBytes(List.filled(60, 1));
    await manager.complete(
        ref: alpha, quality: AudioQuality.standard, file: first);
    expect(await manager.findEligible(alpha, AudioQuality.low), isNotNull);

    final second = await manager.fileFor(
      beta,
      AudioQuality.high,
      Uri.parse('https://example.test/b.mp3'),
    );
    await second.writeAsBytes(List.filled(60, 2));
    await manager.complete(ref: beta, quality: AudioQuality.high, file: second);

    expect(await manager.findEligible(alpha, AudioQuality.low), isNull);
    expect(await manager.findEligible(beta, AudioQuality.high), isNotNull);
    expect(await first.exists(), isFalse);
  });

  test('provider clear removes only cache entries for that provider', () async {
    final directory =
        await Directory.systemTemp.createTemp('melo_audio_cache_');
    addTearDown(() => directory.delete(recursive: true));
    final manager = await AudioCacheManager.open(
      store: _MemoryAudioCacheStore(),
      directory: directory,
      defaultPolicy: const AudioCachePolicy(
        enabled: true,
        wifiOnly: true,
        maxBytes: 1000,
      ),
    );
    final alpha = ProviderTrackRef(
      providerId: ProviderId('alpha_music'),
      trackId: 'track_a',
    );
    final beta = ProviderTrackRef(
      providerId: ProviderId('beta_music'),
      trackId: 'track_b',
    );
    for (final ref in [alpha, beta]) {
      final file = await manager.fileFor(
        ref,
        AudioQuality.standard,
        Uri.parse('https://example.test/${ref.trackId}.mp3'),
      );
      await file.writeAsBytes(List.filled(10, 1));
      await manager.complete(
          ref: ref, quality: AudioQuality.standard, file: file);
    }

    await manager.clear(providerId: alpha.providerId);

    expect(await manager.findEligible(alpha, AudioQuality.low), isNull);
    expect(await manager.findEligible(beta, AudioQuality.low), isNotNull);
  });
}

final class _MemoryAudioCacheStore implements AudioCacheStore {
  AudioCachePolicy? policy;
  final Map<String, AudioCacheEntry> entries = {};

  @override
  Future<void> removeEntries(Iterable<AudioCacheEntry> values) async {
    for (final entry in values) {
      entries.remove(entry.identityKey);
    }
  }

  @override
  Future<void> removeEntry(AudioCacheEntry entry) async {
    entries.remove(entry.identityKey);
  }

  @override
  Future<List<AudioCacheEntry>> readEntries() async => entries.values.toList();

  @override
  Future<AudioCachePolicy?> readPolicy() async => policy;

  @override
  Future<void> upsertEntry(AudioCacheEntry entry) async {
    entries[entry.identityKey] = entry;
  }

  @override
  Future<void> writePolicy(AudioCachePolicy value) async {
    policy = value;
  }
}
