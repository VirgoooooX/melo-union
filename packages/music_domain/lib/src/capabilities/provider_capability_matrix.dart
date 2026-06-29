import 'package:provider_contract/provider_contract.dart';

final class FavoriteWriteAvailability {
  const FavoriteWriteAvailability._({
    required this.isEnabled,
    this.reason,
  });

  const FavoriteWriteAvailability.enabled() : this._(isEnabled: true);

  const FavoriteWriteAvailability.disabled(String reason)
      : this._(isEnabled: false, reason: reason);

  final bool isEnabled;
  final String? reason;
}

final class ProviderCapabilityMatrix {
  const ProviderCapabilityMatrix();

  List<ProviderRegistryEntry> eligibleFavoritesEntries(
    StaticProviderRegistry registry,
  ) {
    return registry
        .allEntries()
        .where(
          (entry) =>
              entry.isEnabled &&
              entry.descriptor.supports(ProviderCapability.readFavorites) &&
              (!entry.descriptor.supports(ProviderCapability.authenticate) ||
                  entry.provider.isAuthenticated),
        )
        .toList(growable: false);
  }

  FavoriteWriteAvailability favoriteWriteAvailability(
    StaticProviderRegistry registry,
    ProviderId providerId,
  ) {
    final entry = registry.entryOf(providerId);
    if (entry == null) {
      return const FavoriteWriteAvailability.disabled(
        'Source provider is not registered.',
      );
    }
    if (!entry.isEnabled) {
      return const FavoriteWriteAvailability.disabled(
        'Source provider is disabled.',
      );
    }
    if (entry.descriptor.supports(ProviderCapability.authenticate) &&
        !entry.provider.isAuthenticated) {
      return const FavoriteWriteAvailability.disabled(
        'Provider account is not logged in.',
      );
    }
    if (!entry.descriptor.supports(ProviderCapability.writeFavorites)) {
      return const FavoriteWriteAvailability.disabled(
        'This source exposes favorites in read-only mode.',
      );
    }
    return const FavoriteWriteAvailability.enabled();
  }
}
