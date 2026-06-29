import 'package:provider_contract/provider_contract.dart';

final class ProviderSearchResults {
  const ProviderSearchResults({
    required this.provider,
    required this.tracks,
  });

  final ProviderDescriptor provider;
  final List<SourceTrack> tracks;
}

final class CapabilityAwareSearchService {
  const CapabilityAwareSearchService();

  Future<List<ProviderSearchResults>> searchEverywhere({
    required StaticProviderRegistry registry,
    required String query,
  }) async {
    final groups = <ProviderSearchResults>[];
    for (final entry in registry.allEntries()) {
      if (!entry.isEnabled ||
          !entry.descriptor.supports(ProviderCapability.search)) {
        continue;
      }
      final tracks = await entry.provider.search(query);
      groups.add(
        ProviderSearchResults(
          provider: entry.descriptor,
          tracks: List.unmodifiable(tracks),
        ),
      );
    }
    return List.unmodifiable(groups);
  }
}
