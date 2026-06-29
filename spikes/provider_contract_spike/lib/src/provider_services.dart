import 'provider_contract.dart';

final class FavoriteWriteAvailability {
  const FavoriteWriteAvailability._({required this.isEnabled, this.reason});

  const FavoriteWriteAvailability.enabled() : this._(isEnabled: true);

  const FavoriteWriteAvailability.disabled(String reason)
    : this._(isEnabled: false, reason: reason);

  final bool isEnabled;
  final String? reason;
}

final class LocalPlaylistEntry {
  const LocalPlaylistEntry({
    required this.trackRef,
    required this.cachedTitle,
    required this.cachedArtist,
  });

  final ProviderTrackRef trackRef;
  final String cachedTitle;
  final String cachedArtist;
}

final class LocalPlaylistEntryView {
  const LocalPlaylistEntryView({
    required this.title,
    required this.artist,
    required this.providerName,
    required this.sourceAvailable,
    this.unavailableReason,
  });

  final String title;
  final String artist;
  final String providerName;
  final bool sourceAvailable;
  final String? unavailableReason;
}

final class ProviderCapabilityMatrix {
  const ProviderCapabilityMatrix();

  List<MusicProvider> eligibleFavoritesProviders(
    StaticProviderRegistry registry,
  ) {
    return registry
        .allEntries()
        .where(
          (entry) =>
              entry.isEnabled &&
              entry.provider.isAuthenticated &&
              entry.descriptor.supports(ProviderCapability.readFavorites),
        )
        .map((entry) => entry.provider)
        .toList(growable: false);
  }

  FavoriteWriteAvailability favoriteWriteAvailability(
    StaticProviderRegistry registry,
    ProviderId providerId,
  ) {
    final entry = registry.entryOf(providerId);
    if (entry == null) {
      return const FavoriteWriteAvailability.disabled(
        'Provider is not registered.',
      );
    }
    if (!entry.isEnabled) {
      return const FavoriteWriteAvailability.disabled('Provider is disabled.');
    }
    if (!entry.provider.isAuthenticated &&
        entry.descriptor.supports(ProviderCapability.authenticate)) {
      return const FavoriteWriteAvailability.disabled(
        'Provider is not authenticated.',
      );
    }
    if (!entry.descriptor.supports(ProviderCapability.writeFavorites)) {
      return const FavoriteWriteAvailability.disabled(
        'Favorite action is disabled because writeFavorites is unavailable.',
      );
    }
    return const FavoriteWriteAvailability.enabled();
  }
}

final class SearchService {
  const SearchService(this.registry);

  final StaticProviderRegistry registry;

  Future<Map<ProviderId, List<ProviderTrack>>> searchEverywhere(
    String query,
  ) async {
    final results = <ProviderId, List<ProviderTrack>>{};

    for (final entry in registry.allEntries()) {
      if (!entry.isEnabled ||
          !entry.descriptor.supports(ProviderCapability.search)) {
        continue;
      }
      results[entry.descriptor.id] = await entry.provider.search(query);
    }
    return results;
  }
}

final class PlaybackService {
  const PlaybackService(this.registry);

  final StaticProviderRegistry registry;

  Future<Uri> createPlaybackTicket(ProviderTrackRef trackRef) async {
    final entry = registry.entryOf(trackRef.providerId);
    if (entry == null || !entry.isEnabled) {
      throw StateError(
        'Provider unavailable for playback: ${trackRef.providerId}',
      );
    }
    if (!entry.descriptor.supports(ProviderCapability.resolvePlayback)) {
      throw CapabilityUnavailableException(
        'Playback is unavailable for provider ${trackRef.providerId}.',
      );
    }
    return entry.provider.createPlaybackTicket(trackRef);
  }
}

final class LocalPlaylistReferenceResolver {
  const LocalPlaylistReferenceResolver(this.registry);

  final StaticProviderRegistry registry;

  LocalPlaylistEntryView resolve(LocalPlaylistEntry entry) {
    final providerEntry = registry.entryOf(entry.trackRef.providerId);
    if (providerEntry == null) {
      return LocalPlaylistEntryView(
        title: entry.cachedTitle,
        artist: entry.cachedArtist,
        providerName: entry.trackRef.providerId.value,
        sourceAvailable: false,
        unavailableReason: 'Source provider is unavailable.',
      );
    }

    return LocalPlaylistEntryView(
      title: entry.cachedTitle,
      artist: entry.cachedArtist,
      providerName: providerEntry.descriptor.displayName,
      sourceAvailable: providerEntry.isEnabled,
      unavailableReason: providerEntry.isEnabled
          ? null
          : 'Source provider is unavailable.',
    );
  }
}
