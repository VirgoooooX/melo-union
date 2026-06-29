import 'package:provider_contract_spike/provider_contract_spike.dart';
import 'package:test/test.dart';

void main() {
  group('ProviderId', () {
    test('uses a stable string key and is not an enum', () {
      const rawId = 'alpha_music';
      final providerId = ProviderId(rawId);

      expect(providerId.value, rawId);
      expect(providerId.runtimeType.toString(), isNot('ProviderIdEnum'));
    });

    test('rejects invalid identifiers', () {
      expect(() => ProviderId('AlphaMusic'), throwsArgumentError);
      expect(() => ProviderId('alpha-music'), throwsArgumentError);
      expect(() => ProviderId('alpha__music'), throwsArgumentError);
      expect(() => ProviderId('alpha1'), throwsArgumentError);
    });
  });

  group('ProviderTrackRef', () {
    test('preserves provider-specific extra IDs as part of the stable ref', () {
      final baseRef = ProviderTrackRef(
        providerId: ProviderId('alpha_music'),
        trackId: 'track_1',
        extraIds: const {'album_id': 'album_1', 'quality_id': 'standard'},
      );
      final sameRefDifferentOrder = ProviderTrackRef(
        providerId: ProviderId('alpha_music'),
        trackId: 'track_1',
        extraIds: const {'quality_id': 'standard', 'album_id': 'album_1'},
      );
      final differentPlatformVariant = ProviderTrackRef(
        providerId: ProviderId('alpha_music'),
        trackId: 'track_1',
        extraIds: const {'album_id': 'album_2', 'quality_id': 'standard'},
      );

      expect(baseRef, sameRefDifferentOrder);
      expect(baseRef.hashCode, sameRefDifferentOrder.hashCode);
      expect(baseRef, isNot(differentPlatformVariant));
      expect(baseRef.extraIds['album_id'], 'album_1');
      expect(
        () => baseRef.extraIds['album_id'] = 'changed',
        throwsUnsupportedError,
      );
    });
  });

  group('StaticProviderRegistry', () {
    test(
      'registers providers, looks them up, exposes descriptors, and toggles enabled state',
      () {
        final registry = StaticProviderRegistry();
        final alpha = FakeMusicProvider.accountFull();
        final beta = FakeMusicProvider.accountReadOnly();

        registry.register(alpha);
        registry.register(beta, enabled: false);

        expect(registry.lookup(alpha.descriptor.id), same(alpha));
        expect(
          registry.descriptorOf(beta.descriptor.id)?.displayName,
          'Beta Library',
        );
        expect(registry.isEnabled(alpha.descriptor.id), isTrue);
        expect(registry.isEnabled(beta.descriptor.id), isFalse);

        registry.setEnabled(beta.descriptor.id, true);

        expect(registry.isEnabled(beta.descriptor.id), isTrue);
        expect(
          registry.allEntries().map((entry) => entry.descriptor.id.value),
          containsAll(<String>['alpha_music', 'beta_library']),
        );
      },
    );

    test(
      'fake A/B/C providers expose the expected capabilities and auth behavior',
      () async {
        final alpha = FakeMusicProvider.accountFull();
        final beta = FakeMusicProvider.accountReadOnly();
        final catalog = FakeMusicProvider.catalogSupplemental();

        expect(
          alpha.descriptor.capabilities,
          contains(ProviderCapability.writeFavorites),
        );
        expect(
          beta.descriptor.capabilities,
          isNot(contains(ProviderCapability.writeFavorites)),
        );
        expect(
          catalog.descriptor.capabilities,
          isNot(contains(ProviderCapability.readFavorites)),
        );

        expect(await alpha.getProfile(), isNotNull);
        expect(await beta.getProfile(), isNotNull);
        expect(await catalog.getProfile(), isNull);

        catalog.setAuthenticated(true);
        expect(catalog.isAuthenticated, isTrue);
      },
    );

    test(
      'A provider can mutate favorites while B provider remains read-only',
      () async {
        final alpha = FakeMusicProvider.accountFull();
        final beta = FakeMusicProvider.accountReadOnly();

        final alphaInitial = await alpha.pullFavorites();
        expect(
          alphaInitial.tracks.map((track) => track.ref.trackId),
          contains('fav_a1'),
        );
        expect(
          alphaInitial.tracks.map((track) => track.ref.trackId),
          isNot(contains('mix_a2')),
        );

        await alpha.setFavorite(
          track: ProviderTrackRef(
            providerId: ProviderId('alpha_music'),
            trackId: 'mix_a2',
          ),
          liked: true,
        );

        final alphaUpdated = await alpha.pullFavorites();
        expect(
          alphaUpdated.tracks.map((track) => track.ref.trackId),
          contains('mix_a2'),
        );

        expect(
          () => beta.setFavorite(
            track: ProviderTrackRef(
              providerId: ProviderId('beta_library'),
              trackId: 'mix_b2',
            ),
            liked: true,
          ),
          throwsA(isA<CapabilityUnavailableException>()),
        );
      },
    );

    test('authenticated state gates favorites for account providers', () async {
      final alpha = FakeMusicProvider.accountFull(authenticated: false);

      expect(alpha.isAuthenticated, isFalse);
      expect(
        alpha.pullFavorites(),
        throwsA(isA<AuthenticationRequiredException>()),
      );

      alpha.setAuthenticated(true);

      final snapshot = await alpha.pullFavorites();
      expect(snapshot.providerId.value, 'alpha_music');
    });
  });
}
