import 'package:provider_contract_spike/provider_contract_spike.dart';
import 'package:test/test.dart';

void main() {
  group('Capability-aware services', () {
    late FakeMusicProvider alpha;
    late FakeMusicProvider beta;
    late FakeMusicProvider catalog;
    late StaticProviderRegistry registry;
    late ProviderCapabilityMatrix matrix;

    setUp(() {
      alpha = FakeMusicProvider.accountFull();
      beta = FakeMusicProvider.accountReadOnly();
      catalog = FakeMusicProvider.catalogSupplemental();
      registry = StaticProviderRegistry([alpha, beta, catalog]);
      matrix = const ProviderCapabilityMatrix();
    });

    test(
      'eligible favorites providers include only enabled + authenticated + readFavorites',
      () {
        final eligible = matrix
            .eligibleFavoritesProviders(registry)
            .map((provider) => provider.descriptor.id.value)
            .toList();

        expect(eligible, containsAll(<String>['alpha_music', 'beta_library']));
        expect(eligible, isNot(contains('catalog_extra')));

        beta.setAuthenticated(false);
        registry.setEnabled(alpha.descriptor.id, false);

        final afterChanges = matrix
            .eligibleFavoritesProviders(registry)
            .map((provider) => provider.descriptor.id.value)
            .toList();

        expect(afterChanges, isEmpty);
      },
    );

    test(
      'read-only favorites return a disabled reason when writeFavorites is unavailable',
      () {
        final availability = matrix.favoriteWriteAvailability(
          registry,
          beta.descriptor.id,
        );

        expect(availability.isEnabled, isFalse);
        expect(availability.reason, contains('writeFavorites'));
      },
    );

    test('B/C providers do not break all favorites aggregation', () async {
      final eligible = matrix.eligibleFavoritesProviders(registry);
      final snapshots = await Future.wait(
        eligible.map((provider) => provider.pullFavorites()),
      );

      expect(
        snapshots.map((snapshot) => snapshot.providerId.value),
        contains('alpha_music'),
      );
      expect(
        snapshots.map((snapshot) => snapshot.providerId.value),
        contains('beta_library'),
      );
      expect(
        snapshots.map((snapshot) => snapshot.providerId.value),
        isNot(contains('catalog_extra')),
      );
    });

    test(
      'search is capability-driven and does not hardcode launch providers',
      () async {
        final service = SearchService(registry);

        final results = await service.searchEverywhere('favorite');

        expect(
          results.keys.map((id) => id.value),
          containsAll(<String>['alpha_music', 'beta_library', 'catalog_extra']),
        );
        expect(
          results[ProviderId('alpha_music')]?.single.title,
          'Alpha Favorite',
        );
        expect(
          results[ProviderId('beta_library')]?.single.title,
          'Beta Favorite',
        );
      },
    );

    test(
      'playback is resolved from the track reference provider instead of hardcoded provider names',
      () async {
        final playback = PlaybackService(registry);

        final catalogTicket = await playback.createPlaybackTicket(
          ProviderTrackRef(
            providerId: ProviderId('catalog_extra'),
            trackId: 'cat_c1',
          ),
        );

        expect(
          catalogTicket.toString(),
          'provider://catalog_extra/play/cat_c1',
        );
      },
    );

    test(
      'local playlist history remains displayable when a provider is disabled',
      () {
        final resolver = LocalPlaylistReferenceResolver(registry);
        final entry = LocalPlaylistEntry(
          trackRef: ProviderTrackRef(
            providerId: ProviderId('beta_library'),
            trackId: 'fav_b1',
            extraIds: const {'catalog_id': 'beta_catalog_1'},
          ),
          cachedTitle: 'Saved Beta Favorite',
          cachedArtist: 'Archive Artist',
        );

        registry.setEnabled(beta.descriptor.id, false);

        final view = resolver.resolve(entry);

        expect(view.title, 'Saved Beta Favorite');
        expect(view.providerName, 'Beta Library');
        expect(view.sourceAvailable, isFalse);
        expect(view.unavailableReason, contains('unavailable'));
      },
    );
  });
}
