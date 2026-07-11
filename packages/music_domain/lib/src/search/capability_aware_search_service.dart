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
    Duration providerTimeout = const Duration(seconds: 6),
  }) async {
    final eligible = registry.allEntries().where((entry) =>
        entry.isEnabled &&
        entry.descriptor.supports(ProviderCapability.search));
    final groups = await Future.wait([
      for (final entry in eligible)
        () async {
          try {
            final tracks =
                await entry.provider.search(query).timeout(providerTimeout);
            return ProviderSearchResults(
              provider: entry.descriptor,
              tracks: List.unmodifiable(tracks),
            );
          } on Object {
            return ProviderSearchResults(
              provider: entry.descriptor,
              tracks: const [],
            );
          }
        }(),
    ]);
    return List.unmodifiable(groups);
  }
}
