import 'package:provider_contract/provider_contract.dart';

import 'local_playlist_models.dart';

final class ResolvedPlaylistItem {
  const ResolvedPlaylistItem({
    required this.title,
    required this.artists,
    required this.providerName,
    required this.sourceAvailable,
    this.unavailableReason,
  });

  final String title;
  final List<String> artists;
  final String providerName;
  final bool sourceAvailable;
  final String? unavailableReason;
}

final class PlaylistReferenceResolver {
  const PlaylistReferenceResolver(this.registry);

  final StaticProviderRegistry registry;

  ResolvedPlaylistItem resolve(LocalPlaylistItem item) {
    final entry = registry.entryOf(item.trackRef.providerId);
    if (entry == null) {
      return ResolvedPlaylistItem(
        title: item.cachedTitle,
        artists: item.cachedArtists,
        providerName: item.cachedProviderName,
        sourceAvailable: false,
        unavailableReason: 'Source provider is unavailable.',
      );
    }
    return ResolvedPlaylistItem(
      title: item.cachedTitle,
      artists: item.cachedArtists,
      providerName: entry.descriptor.displayName,
      sourceAvailable: entry.isEnabled,
      unavailableReason: entry.isEnabled
          ? null
          : 'Source provider is disabled, cached metadata is shown.',
    );
  }
}
