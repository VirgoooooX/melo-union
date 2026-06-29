import 'music_provider.dart';
import 'provider_descriptor.dart';
import 'provider_id.dart';

final class ProviderRegistryEntry {
  const ProviderRegistryEntry({
    required this.provider,
    required this.isEnabled,
  });

  final MusicProvider provider;
  final bool isEnabled;

  ProviderDescriptor get descriptor => provider.descriptor;

  ProviderRegistryEntry copyWith({
    MusicProvider? provider,
    bool? isEnabled,
  }) {
    return ProviderRegistryEntry(
      provider: provider ?? this.provider,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

final class StaticProviderRegistry {
  StaticProviderRegistry([Iterable<MusicProvider> providers = const []]) {
    for (final provider in providers) {
      register(provider);
    }
  }

  final Map<ProviderId, ProviderRegistryEntry> _entries = {};

  void register(MusicProvider provider, {bool enabled = true}) {
    _entries[provider.descriptor.id] = ProviderRegistryEntry(
      provider: provider,
      isEnabled: enabled,
    );
  }

  ProviderRegistryEntry? entryOf(ProviderId id) => _entries[id];

  MusicProvider? find(ProviderId id) => _entries[id]?.provider;

  ProviderDescriptor? describe(ProviderId id) => _entries[id]?.descriptor;

  List<ProviderRegistryEntry> allEntries() =>
      List.unmodifiable(_entries.values.toList(growable: false));

  List<ProviderRegistryEntry> enabledEntries() => List.unmodifiable(
        _entries.values
            .where((entry) => entry.isEnabled)
            .toList(growable: false),
      );

  void setEnabled(ProviderId id, bool enabled) {
    final existing = _entries[id];
    if (existing == null) {
      throw StateError('Provider not registered: $id');
    }
    _entries[id] = existing.copyWith(isEnabled: enabled);
  }

  bool isEnabled(ProviderId id) => _entries[id]?.isEnabled ?? false;
}
