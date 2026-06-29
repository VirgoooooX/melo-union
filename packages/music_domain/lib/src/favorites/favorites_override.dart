import 'package:provider_contract/provider_contract.dart';
import 'unified_favorites_service.dart';

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
