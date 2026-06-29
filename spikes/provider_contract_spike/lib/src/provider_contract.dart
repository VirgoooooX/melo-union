enum ProviderCapability {
  authenticate,
  readFavorites,
  writeFavorites,
  readUserPlaylists,
  readDailyRecommendations,
  search,
  resolvePlayback,
  resolveDownload,
  lyrics,
  artwork,
}

enum ProviderStatus {
  available,
  experimental,
  temporarilyUnavailable,
  deprecated,
  disabled,
}

final class ProviderId {
  ProviderId(String value) : value = _validate(value);

  final String value;

  static final RegExp _pattern = RegExp(r'^[a-z]+(?:_[a-z]+)*$');

  static String _validate(String value) {
    if (!_pattern.hasMatch(value)) {
      throw ArgumentError.value(
        value,
        'value',
        'ProviderId must use lowercase ASCII segments joined by underscores.',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) => other is ProviderId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class ProviderDescriptor {
  ProviderDescriptor({
    required this.id,
    required this.displayName,
    required Set<ProviderCapability> capabilities,
    this.status = ProviderStatus.available,
  }) : capabilities = Set.unmodifiable(capabilities);

  final ProviderId id;
  final String displayName;
  final Set<ProviderCapability> capabilities;
  final ProviderStatus status;

  bool supports(ProviderCapability capability) =>
      capabilities.contains(capability);
}

final class ProviderAccountProfile {
  const ProviderAccountProfile({
    required this.accountId,
    required this.displayName,
  });

  final String accountId;
  final String displayName;
}

final class ProviderTrackRef {
  ProviderTrackRef({
    required this.providerId,
    required this.trackId,
    Map<String, String> extraIds = const {},
  }) : extraIds = Map.unmodifiable(extraIds);

  final ProviderId providerId;
  final String trackId;
  final Map<String, String> extraIds;

  @override
  bool operator ==(Object other) {
    return other is ProviderTrackRef &&
        other.providerId == providerId &&
        other.trackId == trackId &&
        _stringMapEquals(other.extraIds, extraIds);
  }

  @override
  int get hashCode =>
      Object.hash(providerId, trackId, _stringMapHash(extraIds));
}

bool _stringMapEquals(Map<String, String> left, Map<String, String> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (final entry in left.entries) {
    if (right[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _stringMapHash(Map<String, String> values) {
  final keys = values.keys.toList(growable: false)..sort();
  return Object.hashAll(keys.map((key) => Object.hash(key, values[key])));
}

final class ProviderTrack {
  const ProviderTrack({
    required this.ref,
    required this.title,
    required this.artist,
    required this.isFavorited,
  });

  final ProviderTrackRef ref;
  final String title;
  final String artist;
  final bool isFavorited;

  ProviderTrack copyWith({
    ProviderTrackRef? ref,
    String? title,
    String? artist,
    bool? isFavorited,
  }) {
    return ProviderTrack(
      ref: ref ?? this.ref,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }
}

final class FavoriteSnapshot {
  FavoriteSnapshot({
    required this.providerId,
    required List<ProviderTrack> tracks,
  }) : tracks = List.unmodifiable(tracks);

  final ProviderId providerId;
  final List<ProviderTrack> tracks;
}

class ProviderException implements Exception {
  const ProviderException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class CapabilityUnavailableException extends ProviderException {
  const CapabilityUnavailableException(super.message);
}

final class AuthenticationRequiredException extends ProviderException {
  const AuthenticationRequiredException(super.message);
}

abstract interface class MusicProvider {
  ProviderDescriptor get descriptor;

  bool get isAuthenticated;

  Future<ProviderAccountProfile?> getProfile();

  Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false});

  Future<void> setFavorite({
    required ProviderTrackRef track,
    required bool liked,
  });

  Future<List<ProviderTrack>> search(String query);

  Future<Uri> createPlaybackTicket(ProviderTrackRef track);
}

final class ProviderRegistryEntry {
  const ProviderRegistryEntry({
    required this.provider,
    required this.isEnabled,
  });

  final MusicProvider provider;
  final bool isEnabled;

  ProviderDescriptor get descriptor => provider.descriptor;

  ProviderRegistryEntry copyWith({MusicProvider? provider, bool? isEnabled}) {
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

  MusicProvider? lookup(ProviderId id) => _entries[id]?.provider;

  ProviderDescriptor? descriptorOf(ProviderId id) => _entries[id]?.descriptor;

  ProviderRegistryEntry? entryOf(ProviderId id) => _entries[id];

  List<ProviderRegistryEntry> allEntries() =>
      List.unmodifiable(_entries.values.toList(growable: false));

  List<MusicProvider> allProviders() => List.unmodifiable(
    _entries.values.map((entry) => entry.provider).toList(growable: false),
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
