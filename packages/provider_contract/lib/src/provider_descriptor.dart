import 'provider_capability.dart';
import 'provider_id.dart';

enum ProviderStatus {
  available,
  experimental,
  temporarilyUnavailable,
  deprecated,
  disabled,
}

final class ProviderDescriptor {
  ProviderDescriptor({
    required this.id,
    required this.displayName,
    required Set<ProviderCapability> capabilities,
    this.status = ProviderStatus.available,
    this.shortDescription,
  }) : capabilities = Set.unmodifiable(capabilities);

  final ProviderId id;
  final String displayName;
  final Set<ProviderCapability> capabilities;
  final ProviderStatus status;
  final String? shortDescription;

  bool supports(ProviderCapability capability) =>
      capabilities.contains(capability);
}
