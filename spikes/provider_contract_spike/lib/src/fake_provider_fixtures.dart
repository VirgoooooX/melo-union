import 'provider_contract.dart';

enum FakeProviderKind { accountFull, accountReadOnly, catalogSupplemental }

final class FakeMusicProvider implements MusicProvider {
  FakeMusicProvider._({
    required this.descriptor,
    required this.kind,
    required List<ProviderTrack> seedTracks,
    required bool authenticated,
    ProviderAccountProfile? profile,
  }) : _tracks = {for (final track in seedTracks) track.ref.trackId: track},
       _isAuthenticated = authenticated,
       _profile = profile;

  factory FakeMusicProvider.accountFull({
    ProviderId? id,
    String displayName = 'Alpha Music',
    bool authenticated = true,
  }) {
    final providerId = id ?? ProviderId('alpha_music');
    return FakeMusicProvider._(
      descriptor: ProviderDescriptor(
        id: providerId,
        displayName: displayName,
        capabilities: const {
          ProviderCapability.authenticate,
          ProviderCapability.readFavorites,
          ProviderCapability.writeFavorites,
          ProviderCapability.readUserPlaylists,
          ProviderCapability.readDailyRecommendations,
          ProviderCapability.search,
          ProviderCapability.resolvePlayback,
        },
      ),
      kind: FakeProviderKind.accountFull,
      seedTracks: [
        ProviderTrack(
          ref: ProviderTrackRef(
            providerId: providerId,
            trackId: 'fav_a1',
            extraIds: const {'album_id': 'alpha_album_1'},
          ),
          title: 'Alpha Favorite',
          artist: 'Fixture Artist',
          isFavorited: true,
        ),
        ProviderTrack(
          ref: ProviderTrackRef(
            providerId: providerId,
            trackId: 'mix_a2',
            extraIds: const {'album_id': 'alpha_album_2'},
          ),
          title: 'Alpha Mix',
          artist: 'Fixture Artist',
          isFavorited: false,
        ),
      ],
      authenticated: authenticated,
      profile: ProviderAccountProfile(
        accountId: '${providerId.value}_account',
        displayName: '$displayName User',
      ),
    );
  }

  factory FakeMusicProvider.accountReadOnly({
    ProviderId? id,
    String displayName = 'Beta Library',
    bool authenticated = true,
  }) {
    final providerId = id ?? ProviderId('beta_library');
    return FakeMusicProvider._(
      descriptor: ProviderDescriptor(
        id: providerId,
        displayName: displayName,
        capabilities: const {
          ProviderCapability.authenticate,
          ProviderCapability.readFavorites,
          ProviderCapability.readUserPlaylists,
          ProviderCapability.search,
          ProviderCapability.resolvePlayback,
        },
      ),
      kind: FakeProviderKind.accountReadOnly,
      seedTracks: [
        ProviderTrack(
          ref: ProviderTrackRef(
            providerId: providerId,
            trackId: 'fav_b1',
            extraIds: const {'catalog_id': 'beta_catalog_1'},
          ),
          title: 'Beta Favorite',
          artist: 'Archive Artist',
          isFavorited: true,
        ),
        ProviderTrack(
          ref: ProviderTrackRef(
            providerId: providerId,
            trackId: 'mix_b2',
            extraIds: const {'catalog_id': 'beta_catalog_2'},
          ),
          title: 'Beta Session',
          artist: 'Archive Artist',
          isFavorited: false,
        ),
      ],
      authenticated: authenticated,
      profile: ProviderAccountProfile(
        accountId: '${providerId.value}_account',
        displayName: '$displayName User',
      ),
    );
  }

  factory FakeMusicProvider.catalogSupplemental({
    ProviderId? id,
    String displayName = 'Catalog Extra',
    bool authenticated = false,
  }) {
    final providerId = id ?? ProviderId('catalog_extra');
    return FakeMusicProvider._(
      descriptor: ProviderDescriptor(
        id: providerId,
        displayName: displayName,
        capabilities: const {
          ProviderCapability.search,
          ProviderCapability.resolvePlayback,
          ProviderCapability.artwork,
          ProviderCapability.lyrics,
        },
        status: ProviderStatus.experimental,
      ),
      kind: FakeProviderKind.catalogSupplemental,
      seedTracks: [
        ProviderTrack(
          ref: ProviderTrackRef(
            providerId: providerId,
            trackId: 'cat_c1',
            extraIds: const {'artwork_key': 'catalog_art_1'},
          ),
          title: 'Catalog Result',
          artist: 'Reference Artist',
          isFavorited: false,
        ),
        ProviderTrack(
          ref: ProviderTrackRef(
            providerId: providerId,
            trackId: 'cat_c2',
            extraIds: const {'artwork_key': 'catalog_art_2'},
          ),
          title: 'Catalog B-Side',
          artist: 'Reference Artist',
          isFavorited: false,
        ),
      ],
      authenticated: authenticated,
    );
  }

  @override
  final ProviderDescriptor descriptor;

  final FakeProviderKind kind;
  final Map<String, ProviderTrack> _tracks;
  bool _isAuthenticated;
  final ProviderAccountProfile? _profile;

  void setAuthenticated(bool value) {
    _isAuthenticated = value;
  }

  @override
  bool get isAuthenticated => _isAuthenticated;

  @override
  Future<ProviderAccountProfile?> getProfile() async {
    if (!_requiresAuthentication) {
      return null;
    }
    if (!_isAuthenticated) {
      throw AuthenticationRequiredException(
        '${descriptor.displayName} is not logged in.',
      );
    }
    return _profile;
  }

  @override
  Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false}) async {
    _requireCapability(ProviderCapability.readFavorites);
    _requireAuthenticatedIfNeeded();
    return FavoriteSnapshot(
      providerId: descriptor.id,
      tracks: _tracks.values.where((track) => track.isFavorited).toList(),
    );
  }

  @override
  Future<void> setFavorite({
    required ProviderTrackRef track,
    required bool liked,
  }) async {
    _requireCapability(ProviderCapability.writeFavorites);
    _requireAuthenticatedIfNeeded();

    final existing = _tracks[track.trackId];
    if (existing == null) {
      throw StateError('Unknown fake track: ${track.trackId}');
    }
    _tracks[track.trackId] = existing.copyWith(isFavorited: liked);
  }

  @override
  Future<List<ProviderTrack>> search(String query) async {
    _requireCapability(ProviderCapability.search);
    final normalized = query.trim().toLowerCase();
    return _tracks.values
        .where(
          (track) =>
              track.title.toLowerCase().contains(normalized) ||
              track.artist.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  @override
  Future<Uri> createPlaybackTicket(ProviderTrackRef track) async {
    _requireCapability(ProviderCapability.resolvePlayback);
    if (!_tracks.containsKey(track.trackId)) {
      throw StateError('Unknown fake track: ${track.trackId}');
    }
    return Uri.parse('provider://${descriptor.id.value}/play/${track.trackId}');
  }

  bool get _requiresAuthentication =>
      descriptor.supports(ProviderCapability.authenticate);

  void _requireAuthenticatedIfNeeded() {
    if (_requiresAuthentication && !_isAuthenticated) {
      throw AuthenticationRequiredException(
        '${descriptor.displayName} is not logged in.',
      );
    }
  }

  void _requireCapability(ProviderCapability capability) {
    if (!descriptor.supports(capability)) {
      throw CapabilityUnavailableException(
        '${descriptor.displayName} does not support $capability.',
      );
    }
  }
}
