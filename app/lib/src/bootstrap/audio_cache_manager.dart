import 'dart:async';
import 'dart:io';

import 'package:music_domain/music_domain.dart';
import 'package:path/path.dart' as path;
import 'package:provider_contract/provider_contract.dart';

/// Owns disposable streamed-audio files and their device-local index.
final class AudioCacheManager {
  AudioCacheManager._({
    required AudioCacheStore store,
    required this.directory,
    required AudioCachePolicy defaultPolicy,
  })  : _store = store,
        _policy = defaultPolicy;

  final AudioCacheStore _store;
  final Directory directory;
  AudioCachePolicy _policy;
  final Map<String, AudioCacheEntry> _entries = {};
  final Set<String> _inUsePaths = {};
  final Set<String> _pendingDeletion = {};

  AudioCachePolicy get policy => _policy;
  List<AudioCacheEntry> get entries => _entries.values.toList(growable: false);
  int get totalBytes =>
      _entries.values.fold(0, (sum, entry) => sum + entry.fileSize);

  static Future<AudioCacheManager> open({
    required AudioCacheStore store,
    required Directory directory,
    required AudioCachePolicy defaultPolicy,
  }) async {
    final manager = AudioCacheManager._(
      store: store,
      directory: directory,
      defaultPolicy: defaultPolicy,
    );
    await manager._initialize();
    return manager;
  }

  Future<void> _initialize() async {
    await directory.create(recursive: true);
    _policy = await _store.readPolicy() ?? _policy;
    _entries
      ..clear()
      ..addEntries((await _store.readEntries())
          .map((entry) => MapEntry(entry.identityKey, entry)));
    await reconcile();
  }

  Future<void> reconcile() async {
    final stale = <AudioCacheEntry>[];
    for (final entry in _entries.values) {
      final file = File(entry.filePath);
      if (!await file.exists() || await file.length() <= 0) stale.add(entry);
    }
    await _removeEntries(stale, deleteFiles: false);
    final indexedPaths = <String>{
      for (final entry in _entries.values) entry.filePath,
      for (final entry in _entries.values) '${entry.filePath}.mime',
    };
    await for (final entity
        in directory.list(recursive: true, followLinks: false)) {
      if (entity is File &&
          (entity.path.endsWith('.part') ||
              !indexedPaths.contains(entity.path))) {
        await _deleteFile(entity.path);
      }
    }
    await prune();
  }

  Future<void> updatePolicy(AudioCachePolicy policy) async {
    _policy = policy;
    await _store.writePolicy(policy);
    await prune();
  }

  Future<AudioCacheEntry?> findEligible(
    ProviderTrackRef ref,
    AudioQuality requested,
  ) async {
    final entry = _entries[_identityKey(ref)];
    if (entry == null || !entry.quality.meetsOrExceeds(requested)) return null;
    final file = File(entry.filePath);
    if (!await file.exists() || await file.length() <= 0) {
      await _removeEntries([entry], deleteFiles: false);
      return null;
    }
    await touch(entry);
    return _entries[entry.identityKey];
  }

  Future<AudioCacheEntry?> findBestFallback(ProviderTrackRef ref) async {
    final entry = _entries[_identityKey(ref)];
    if (entry == null) return null;
    final file = File(entry.filePath);
    if (!await file.exists() || await file.length() <= 0) {
      await _removeEntries([entry], deleteFiles: false);
      return null;
    }
    await touch(entry);
    return _entries[entry.identityKey];
  }

  Future<void> touch(AudioCacheEntry entry) async {
    final updated = entry.copyWith(lastAccessedAt: DateTime.now().toUtc());
    _entries[updated.identityKey] = updated;
    await _store.upsertEntry(updated);
  }

  Future<File> fileFor(
      ProviderTrackRef ref, AudioQuality quality, Uri remoteUri) async {
    final extension = _safeExtension(remoteUri);
    final providerDirectory = Directory(
        path.join(directory.path, _safeSegment(ref.providerId.value)));
    await providerDirectory.create(recursive: true);
    return File(path.join(
      providerDirectory.path,
      '${_fnv1a(_identityKey(ref))}_${quality.name}.$extension',
    ));
  }

  Future<void> complete({
    required ProviderTrackRef ref,
    required AudioQuality quality,
    required File file,
  }) async {
    if (!await file.exists()) return;
    final size = await file.length();
    if (size <= 0 || size > _policy.maxBytes) {
      await _deleteFile(file.path);
      await _deleteFile('${file.path}.mime');
      return;
    }
    final old = _entries[_identityKey(ref)];
    if (old != null && old.quality.meetsOrExceeds(quality)) {
      if (old.filePath != file.path) {
        await _deleteFile(file.path);
        await _deleteFile('${file.path}.mime');
      }
      return;
    }
    final now = DateTime.now().toUtc();
    final entry = AudioCacheEntry(
      providerId: ref.providerId,
      trackId: ref.trackId,
      quality: quality,
      filePath: file.path,
      fileSize: size,
      completedAt: now,
      lastAccessedAt: now,
    );
    _entries[entry.identityKey] = entry;
    await _store.upsertEntry(entry);
    if (old != null && old.filePath != file.path) await _deleteEntryFile(old);
    await prune();
  }

  void markInUse(String filePath) => _inUsePaths.add(filePath);

  Future<void> releaseInUse(String? filePath) async {
    if (filePath == null) return;
    _inUsePaths.remove(filePath);
    if (_pendingDeletion.remove(filePath)) {
      await _deleteFile(filePath);
      await _deleteFile('$filePath.mime');
    }
  }

  Future<void> prune() async {
    var usage = totalBytes;
    if (usage <= _policy.maxBytes) return;
    final ordered = _entries.values.toList()
      ..sort(
          (left, right) => left.lastAccessedAt.compareTo(right.lastAccessedAt));
    final remove = <AudioCacheEntry>[];
    for (final entry in ordered) {
      if (usage <= _policy.maxBytes) break;
      if (_inUsePaths.contains(entry.filePath)) continue;
      usage -= entry.fileSize;
      remove.add(entry);
    }
    await _removeEntries(remove);
  }

  Future<void> clear({ProviderId? providerId}) async {
    final targets = _entries.values
        .where((entry) => providerId == null || entry.providerId == providerId)
        .toList(growable: false);
    await _removeEntries(targets);
  }

  Future<void> _removeEntries(
    Iterable<AudioCacheEntry> entries, {
    bool deleteFiles = true,
  }) async {
    final list = entries.toList(growable: false);
    if (list.isEmpty) return;
    for (final entry in list) {
      _entries.remove(entry.identityKey);
      if (deleteFiles) await _deleteEntryFile(entry);
    }
    await _store.removeEntries(list);
  }

  Future<void> _deleteEntryFile(AudioCacheEntry entry) async {
    if (_inUsePaths.contains(entry.filePath)) {
      _pendingDeletion.add(entry.filePath);
      return;
    }
    await _deleteFile(entry.filePath);
    await _deleteFile('${entry.filePath}.mime');
  }

  Future<void> _deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Cache cleanup is intentionally best-effort.
    }
  }

  String _identityKey(ProviderTrackRef ref) =>
      '${ref.providerId.value}:${ref.trackId}';

  String _safeExtension(Uri uri) {
    final extension =
        path.extension(uri.path).replaceFirst('.', '').toLowerCase();
    return RegExp(r'^[a-z0-9]{1,8}$').hasMatch(extension) ? extension : 'audio';
  }

  String _safeSegment(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');

  String _fnv1a(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
