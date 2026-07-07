import 'package:provider_contract/provider_contract.dart';
import 'unified_favorites_service.dart';

/// Metadata about when and how a track was marked as liked.
final class LikedAtMetadata {
  const LikedAtMetadata({
    this.likedAt,
    required this.source,
    required this.precision,
  });

  /// UTC timestamp of when the like was recorded (null for imported unknowns).
  final DateTime? likedAt;

  /// Origin of this liked-at value:
  /// - `'app_action'`: recorded by this client when user tapped like
  /// - `'sync_detected'`: first time this track appeared in a pullFavorites diff
  /// - `'unknown'`: imported from external source, no reliable timestamp
  /// - `'qq_import'`: specifically imported from QQ (separate from generic unknown)
  /// - `'kugou_import'`: imported from Kugou without a reliable raw timestamp
  /// - `'kugou_raw'`: Kugou's native `collecttime` field (exact second timestamp)
  /// - `'netease_raw'`: Netease's native `at` field (exact millisecond timestamp)
  final String source;

  /// Precision of the timestamp:
  /// - `'exact'`: known with second-level accuracy
  /// - `'approximate'`: known within a sync window
  /// - `'unknown'`: no timestamp available
  final String precision;

  static const sourceAppAction = 'app_action';
  static const sourceSyncDetected = 'sync_detected';
  static const sourceUnknown = 'unknown';
  static const sourceQqImport = 'qq_import';
  static const sourceKugouImport = 'kugou_import';
  static const sourceKugouRaw = 'kugou_raw';
  static const sourceNeteaseRaw = 'netease_raw';
  static const sourceLocalEstimate = 'local_estimate';

  static const precisionExact = 'exact';
  static const precisionApproximate = 'approximate';
  static const precisionUnknown = 'unknown';
}

final class LikedAtLedgerEntry {
  const LikedAtLedgerEntry({
    required this.ref,
    required this.metadata,
    this.updatedAt,
  });

  final ProviderTrackRef ref;
  final LikedAtMetadata metadata;
  final DateTime? updatedAt;

  LikedAtLedgerEntry copyWith({
    ProviderTrackRef? ref,
    LikedAtMetadata? metadata,
    DateTime? updatedAt,
  }) {
    return LikedAtLedgerEntry(
      ref: ref ?? this.ref,
      metadata: metadata ?? this.metadata,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class LikedAtLedger {
  LikedAtLedger({
    Iterable<LikedAtLedgerEntry> entries = const [],
  }) {
    for (final entry in entries) {
      record(entry.ref, entry.metadata, updatedAt: entry.updatedAt);
    }
  }

  final Map<String, LikedAtLedgerEntry> _entries = {};

  List<LikedAtLedgerEntry> get entries => List.unmodifiable(_entries.values);

  bool get isEmpty => _entries.isEmpty;

  void record(
    ProviderTrackRef ref,
    LikedAtMetadata metadata, {
    DateTime? updatedAt,
  }) {
    final identityKeys = FavoritesOverrideRegistry.likedAtIdentityKeys(ref);
    var preferredRef = ref;
    var preferredMetadata = metadata;
    DateTime? preferredUpdatedAt = updatedAt;
    final matchedKeys = <String>[];

    for (final entry in _entries.entries) {
      if (!FavoritesOverrideRegistry.sharesLikedAtIdentity(
        identityKeys,
        FavoritesOverrideRegistry.likedAtIdentityKeys(entry.value.ref),
      )) {
        continue;
      }
      matchedKeys.add(entry.key);
      final preferred = FavoritesOverrideRegistry.preferLikedAtEntry(
        leftRef: preferredRef,
        leftMetadata: preferredMetadata,
        rightRef: entry.value.ref,
        rightMetadata: entry.value.metadata,
      );
      final existingWon = preferred.$1 == entry.value.ref &&
          identical(preferred.$2, entry.value.metadata);
      preferredRef = preferred.$1;
      preferredMetadata = preferred.$2;
      preferredUpdatedAt = existingWon ? entry.value.updatedAt : updatedAt;
    }

    for (final key in matchedKeys) {
      _entries.remove(key);
    }
    _entries[_preferredIdentityKey(preferredRef)] = LikedAtLedgerEntry(
      ref: preferredRef,
      metadata: preferredMetadata,
      updatedAt: preferredUpdatedAt,
    );
  }

  LikedAtMetadata? likedAtFor(ProviderTrackRef ref) {
    return entryFor(ref)?.metadata;
  }

  LikedAtLedgerEntry? entryFor(ProviderTrackRef ref) {
    final identityKeys = FavoritesOverrideRegistry.likedAtIdentityKeys(ref);
    LikedAtLedgerEntry? preferredEntry;
    for (final entry in _entries.values) {
      if (!FavoritesOverrideRegistry.sharesLikedAtIdentity(
        identityKeys,
        FavoritesOverrideRegistry.likedAtIdentityKeys(entry.ref),
      )) {
        continue;
      }
      if (preferredEntry == null) {
        preferredEntry = entry;
        continue;
      }
      final preferred = FavoritesOverrideRegistry.preferLikedAtEntry(
        leftRef: preferredEntry.ref,
        leftMetadata: preferredEntry.metadata,
        rightRef: entry.ref,
        rightMetadata: entry.metadata,
      );
      preferredEntry =
          preferred.$1 == preferredEntry.ref ? preferredEntry : entry;
    }
    return preferredEntry;
  }

  void remove(ProviderTrackRef ref) {
    final identityKeys = FavoritesOverrideRegistry.likedAtIdentityKeys(ref);
    _entries.removeWhere(
      (_, entry) => FavoritesOverrideRegistry.sharesLikedAtIdentity(
        identityKeys,
        FavoritesOverrideRegistry.likedAtIdentityKeys(entry.ref),
      ),
    );
  }

  void seedFromLegacy(FavoritesOverrideRegistry registry) {
    for (final entry in registry.likedAtTracking.entries) {
      record(entry.key, entry.value);
    }
  }

  static String _preferredIdentityKey(ProviderTrackRef ref) {
    final keys = FavoritesOverrideRegistry.likedAtIdentityKeys(ref).toList()
      ..sort();
    final songIdKey = keys.where((key) => key.contains(':song_id:'));
    if (songIdKey.isNotEmpty) return songIdKey.first;
    return keys.first;
  }
}

final class UnifiedFavoritesResult {
  const UnifiedFavoritesResult({
    required this.tracks,
    required this.failures,
  });

  final List<UnifiedFavoriteTrack> tracks;
  final Map<ProviderId, String> failures;
}

class FavoritesOverrideRegistry {
  final Set<Set<ProviderTrackRef>> mergeOverrides = {};
  final Set<Set<ProviderTrackRef>> splitOverrides = {};
  final Set<ProviderTrackRef> hiddenTracks = {};

  /// Per-track liked-at metadata.
  ///
  /// - **app_action**: recorded when user taps like via this client → exact
  /// - **sync_detected**: first seen in a pullFavorites diff → approximate
  /// - **qq_import / unknown**: bulk import, no reliable timestamp → no timestamp
  final Map<ProviderTrackRef, LikedAtMetadata> likedAtTracking = {};

  void addMergeOverride(ProviderTrackRef a, ProviderTrackRef b) {
    Set<ProviderTrackRef>? targetSet;
    for (final set in mergeOverrides) {
      if (set.contains(a) || set.contains(b)) {
        targetSet = set;
        break;
      }
    }
    if (targetSet != null) {
      targetSet.add(a);
      targetSet.add(b);
    } else {
      mergeOverrides.add({a, b});
    }
  }

  void addSplitOverride(ProviderTrackRef a, ProviderTrackRef b) {
    Set<ProviderTrackRef>? targetSet;
    for (final set in splitOverrides) {
      if (set.contains(a) || set.contains(b)) {
        targetSet = set;
        break;
      }
    }
    if (targetSet != null) {
      targetSet.add(a);
      targetSet.add(b);
    } else {
      splitOverrides.add({a, b});
    }
  }

  void hideTrack(ProviderTrackRef trackRef) {
    hiddenTracks.add(trackRef);
  }

  /// Records liked-at metadata for a track (app-action or sync-detected).
  void recordLikedAt(ProviderTrackRef ref, LikedAtMetadata metadata) {
    final identityKeys = likedAtIdentityKeys(ref);
    var preferredRef = ref;
    var preferredMetadata = metadata;
    final equivalentRefs = <ProviderTrackRef>[];

    for (final entry in likedAtTracking.entries) {
      if (!sharesLikedAtIdentity(
          identityKeys, likedAtIdentityKeys(entry.key))) {
        continue;
      }
      equivalentRefs.add(entry.key);
      final preferred = preferLikedAtEntry(
        leftRef: preferredRef,
        leftMetadata: preferredMetadata,
        rightRef: entry.key,
        rightMetadata: entry.value,
      );
      preferredRef = preferred.$1;
      preferredMetadata = preferred.$2;
    }

    for (final existingRef in equivalentRefs) {
      likedAtTracking.remove(existingRef);
    }
    likedAtTracking[preferredRef] = preferredMetadata;
  }

  /// Retrieves liked-at metadata for a track, if recorded.
  LikedAtMetadata? likedAtFor(ProviderTrackRef ref) {
    final exact = likedAtTracking[ref];
    if (exact != null) {
      return exact;
    }

    final identityKeys = likedAtIdentityKeys(ref);
    ProviderTrackRef? preferredRef;
    LikedAtMetadata? preferredMetadata;
    for (final entry in likedAtTracking.entries) {
      if (!sharesLikedAtIdentity(
          identityKeys, likedAtIdentityKeys(entry.key))) {
        continue;
      }
      if (preferredMetadata == null) {
        preferredRef = entry.key;
        preferredMetadata = entry.value;
        continue;
      }
      final preferred = preferLikedAtEntry(
        leftRef: preferredRef!,
        leftMetadata: preferredMetadata,
        rightRef: entry.key,
        rightMetadata: entry.value,
      );
      preferredRef = preferred.$1;
      preferredMetadata = preferred.$2;
    }
    return preferredMetadata;
  }

  /// Collapses duplicate liked-at records that refer to the same stable track.
  void normalizeLikedAtTracking() {
    final entries = likedAtTracking.entries.toList(growable: false);
    likedAtTracking.clear();
    for (final entry in entries) {
      recordLikedAt(entry.key, entry.value);
    }
  }

  /// Clears liked-at metadata (e.g. when a track is unliked).
  void removeLikedAt(ProviderTrackRef ref) {
    final identityKeys = likedAtIdentityKeys(ref);
    likedAtTracking.removeWhere(
      (storedRef, _) =>
          sharesLikedAtIdentity(identityKeys, likedAtIdentityKeys(storedRef)),
    );
  }

  bool shouldSplit(ProviderTrackRef a, ProviderTrackRef b) {
    for (final set in splitOverrides) {
      if (set.contains(a) && set.contains(b)) {
        return true;
      }
    }
    return false;
  }

  bool shouldMerge(ProviderTrackRef a, ProviderTrackRef b) {
    for (final set in mergeOverrides) {
      if (set.contains(a) && set.contains(b)) {
        return true;
      }
    }
    return false;
  }

  static String likedAtIdentityKey(ProviderTrackRef ref) {
    return likedAtIdentityKeys(ref).first;
  }

  static Set<String> likedAtIdentityKeys(ProviderTrackRef ref) {
    if (ref.providerId.value == 'qq_music') {
      final result = <String>{};
      final songId = ref.extraIds['song_id']?.trim();
      if (songId != null && songId.isNotEmpty) {
        result.add('${ref.providerId.value}:song_id:$songId');
      }
      final songMid = ref.extraIds['song_mid']?.trim();
      if (songMid != null && songMid.isNotEmpty) {
        result.add('${ref.providerId.value}:song_mid:$songMid');
      }
      final trackId = ref.trackId.trim();
      if (trackId.isNotEmpty) {
        result.add('${ref.providerId.value}:track_id:$trackId');
      }
      if (result.isNotEmpty) {
        return result;
      }
    }
    if (ref.providerId.value == 'kugou') {
      final trackId = ref.trackId.trim();
      if (trackId.isNotEmpty) {
        return {'${ref.providerId.value}:track_id:$trackId'};
      }
    }
    return {'${ref.providerId.value}:${ref.trackId}:${_extraIdsKey(ref)}'};
  }

  static bool sharesLikedAtIdentity(Set<String> left, Set<String> right) {
    if (left.length < right.length) {
      return left.any(right.contains);
    }
    return right.any(left.contains);
  }

  static (ProviderTrackRef, LikedAtMetadata) preferLikedAtEntry({
    required ProviderTrackRef leftRef,
    required LikedAtMetadata leftMetadata,
    required ProviderTrackRef rightRef,
    required LikedAtMetadata rightMetadata,
  }) {
    final leftScore = metadataPriority(leftMetadata);
    final rightScore = metadataPriority(rightMetadata);
    if (leftScore != rightScore) {
      return leftScore > rightScore
          ? (leftRef, leftMetadata)
          : (rightRef, rightMetadata);
    }

    final leftLikedAt = leftMetadata.likedAt;
    final rightLikedAt = rightMetadata.likedAt;
    if (leftLikedAt != null && rightLikedAt != null) {
      final comparison = leftLikedAt.compareTo(rightLikedAt);
      if (comparison != 0) {
        return comparison > 0
            ? (leftRef, leftMetadata)
            : (rightRef, rightMetadata);
      }
    } else if (leftLikedAt != null) {
      return (leftRef, leftMetadata);
    } else if (rightLikedAt != null) {
      return (rightRef, rightMetadata);
    }

    final leftDetailScore = _refDetailScore(leftRef);
    final rightDetailScore = _refDetailScore(rightRef);
    if (leftDetailScore != rightDetailScore) {
      return leftDetailScore > rightDetailScore
          ? (leftRef, leftMetadata)
          : (rightRef, rightMetadata);
    }

    return (leftRef, leftMetadata);
  }

  static int metadataPriority(LikedAtMetadata metadata) {
    final hasTime = metadata.likedAt != null;
    if (metadata.source == LikedAtMetadata.sourceAppAction && hasTime) {
      return 500;
    }
    if (metadata.precision == LikedAtMetadata.precisionExact && hasTime) {
      if (metadata.source == LikedAtMetadata.sourceQqImport ||
          metadata.source == LikedAtMetadata.sourceKugouRaw) {
        return 400;
      }
      return 350;
    }
    if (metadata.precision == LikedAtMetadata.precisionApproximate && hasTime) {
      return 250;
    }
    if (metadata.source == LikedAtMetadata.sourceLocalEstimate && hasTime) {
      return 200;
    }
    if (hasTime) {
      return 100;
    }
    return 0;
  }

  static int _refDetailScore(ProviderTrackRef ref) {
    final nonEmptyExtras =
        ref.extraIds.values.where((value) => value.trim().isNotEmpty).length;
    return ref.trackId.trim().isEmpty ? nonEmptyExtras : nonEmptyExtras + 1;
  }

  static String _extraIdsKey(ProviderTrackRef ref) {
    final entries = ref.extraIds.entries.toList(growable: false)
      ..sort((left, right) => left.key.compareTo(right.key));
    return entries.map((entry) => '${entry.key}=${entry.value}').join('&');
  }
}
