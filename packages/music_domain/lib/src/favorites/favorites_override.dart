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
  static const sourceNeteaseRaw = 'netease_raw';

  static const precisionExact = 'exact';
  static const precisionApproximate = 'approximate';
  static const precisionUnknown = 'unknown';
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
    likedAtTracking[ref] = metadata;
  }

  /// Retrieves liked-at metadata for a track, if recorded.
  LikedAtMetadata? likedAtFor(ProviderTrackRef ref) => likedAtTracking[ref];

  /// Clears liked-at metadata (e.g. when a track is unliked).
  void removeLikedAt(ProviderTrackRef ref) {
    likedAtTracking.remove(ref);
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
}
