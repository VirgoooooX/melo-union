import 'package:provider_contract/provider_contract.dart';
import 'package:test/test.dart';

import 'support/fake_music_provider.dart';

void main() {
  group('ProviderId', () {
    test('uses a stable lowercase underscore key', () {
      final providerId = ProviderId('alpha_music');

      expect(providerId.value, 'alpha_music');
      expect(() => ProviderId('AlphaMusic'), throwsArgumentError);
      expect(() => ProviderId('alpha-music'), throwsArgumentError);
      expect(() => ProviderId('alpha__music'), throwsArgumentError);
    });
  });

  group('ProviderTrackRef', () {
    test('keeps extra IDs as part of equality and hashing', () {
      final first = ProviderTrackRef(
        providerId: ProviderId('alpha_music'),
        trackId: 'track_1',
        extraIds: const {'album_id': 'album_1', 'quality_id': 'std'},
      );
      final second = ProviderTrackRef(
        providerId: ProviderId('alpha_music'),
        trackId: 'track_1',
        extraIds: const {'quality_id': 'std', 'album_id': 'album_1'},
      );
      final third = ProviderTrackRef(
        providerId: ProviderId('alpha_music'),
        trackId: 'track_1',
        extraIds: const {'album_id': 'album_2', 'quality_id': 'std'},
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first, isNot(third));
      expect(
        () => first.extraIds['album_id'] = 'changed',
        throwsUnsupportedError,
      );
    });
  });

  group('StaticProviderRegistry', () {
    test('registers and toggles providers without platform enums', () {
      final alpha = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('alpha_music'),
          displayName: 'Alpha Music',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites,
            ProviderCapability.writeFavorites,
            ProviderCapability.search,
          },
        ),
        kind: FakeProviderKind.fullAccount,
        seedTracks: [
          SourceTrack(
            ref: ProviderTrackRef(
              providerId: ProviderId('alpha_music'),
              trackId: 'alpha_1',
            ),
            title: 'Alpha Song',
            artists: const ['Fixture'],
            duration: const Duration(minutes: 3),
            isFavorited: true,
          ),
        ],
        profile: const ProviderAccountProfile(
          accountId: 'alpha_001',
          displayName: 'Alpha User',
        ),
      );
      final beta = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('beta_library'),
          displayName: 'Beta Library',
          capabilities: const {
            ProviderCapability.readFavorites,
            ProviderCapability.search,
          },
        ),
        kind: FakeProviderKind.readOnlyAccount,
        seedTracks: const [],
      );

      final registry = StaticProviderRegistry([alpha]);
      registry.register(beta, enabled: false);

      expect(registry.find(alpha.descriptor.id), same(alpha));
      expect(
          registry.describe(beta.descriptor.id)?.displayName, 'Beta Library');
      expect(registry.isEnabled(beta.descriptor.id), isFalse);

      registry.setEnabled(beta.descriptor.id, true);

      expect(registry.isEnabled(beta.descriptor.id), isTrue);
      expect(
        registry.allEntries().map((entry) => entry.descriptor.id.value),
        containsAll(<String>['alpha_music', 'beta_library']),
      );
    });
  });

  group('Structured exceptions', () {
    test('read-only providers reject writeFavorites with capability metadata',
        () {
      final provider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('beta_library'),
          displayName: 'Beta Library',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites,
          },
        ),
        kind: FakeProviderKind.readOnlyAccount,
        seedTracks: [
          SourceTrack(
            ref: ProviderTrackRef(
              providerId: ProviderId('beta_library'),
              trackId: 'beta_1',
            ),
            title: 'Beta Song',
            artists: const ['Archive Artist'],
            duration: const Duration(minutes: 4),
            isFavorited: true,
          ),
        ],
        profile: const ProviderAccountProfile(
          accountId: 'beta_001',
          displayName: 'Beta User',
        ),
      );

      expect(
        () => provider.setFavorite(
          track: ProviderTrackRef(
            providerId: ProviderId('beta_library'),
            trackId: 'beta_1',
          ),
          liked: false,
        ),
        throwsA(
          isA<CapabilityUnavailableException>()
              .having(
                  (error) => error.providerId.value, 'provider', 'beta_library')
              .having((error) => error.capability, 'capability',
                  ProviderCapability.writeFavorites),
        ),
      );
    });

    test('authenticated providers surface auth errors structurally', () {
      final provider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('alpha_music'),
          displayName: 'Alpha Music',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites,
          },
        ),
        kind: FakeProviderKind.fullAccount,
        seedTracks: const [],
        isAuthenticated: false,
        profile: const ProviderAccountProfile(
          accountId: 'alpha_001',
          displayName: 'Alpha User',
        ),
      );

      expect(
        provider.pullFavorites(),
        throwsA(
          isA<AuthenticationRequiredException>().having(
            (error) => error.providerId.value,
            'provider',
            'alpha_music',
          ),
        ),
      );
    });
  });

  group('PlaybackTicket & DownloadTicket', () {
    final trackRef = ProviderTrackRef(
      providerId: ProviderId('alpha_music'),
      trackId: 'track_1',
    );

    test('expiration helpers work correctly', () {
      final now = DateTime.now().toUtc();
      final expiredTicket = PlaybackTicket(
        mediaUri: Uri.parse('provider://alpha/1'),
        headers: const {},
        expiresAt: now.subtract(const Duration(minutes: 1)),
        trackRef: trackRef,
        quality: AudioQuality.standard,
      );
      final validTicket = PlaybackTicket(
        mediaUri: Uri.parse('provider://alpha/1'),
        headers: const {},
        expiresAt: now.add(const Duration(hours: 1)),
        trackRef: trackRef,
        quality: AudioQuality.standard,
      );

      expect(expiredTicket.isExpired, isTrue);
      expect(expiredTicket.isNearExpiry(), isTrue);
      expect(validTicket.isExpired, isFalse);
      expect(validTicket.isNearExpiry(const Duration(minutes: 5)), isFalse);
      expect(validTicket.isNearExpiry(const Duration(minutes: 65)), isTrue);
    });

    test('FakeMusicProvider handles tickets and recommendations capabilities',
        () async {
      final provider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('alpha_music'),
          displayName: 'Alpha Music',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readDailyRecommendations,
            ProviderCapability.resolvePlayback,
          },
        ),
        kind: FakeProviderKind.fullAccount,
        seedTracks: [
          SourceTrack(
            ref: trackRef,
            title: 'Track One',
            artists: const ['Alpha'],
            duration: const Duration(minutes: 3),
            isFavorited: false,
          ),
        ],
        profile: const ProviderAccountProfile(
          accountId: 'alpha_001',
          displayName: 'Alpha User',
        ),
      );

      // daily recommendations support
      final recs = await provider.getDailyRecommendations();
      expect(recs.length, 1);
      expect(recs.first.ref.trackId, 'track_1');

      // playback ticket support
      final ticket = await provider.createPlaybackTicket(
        track: trackRef,
        quality: AudioQuality.high,
      );
      expect(ticket.trackRef, trackRef);
      expect(ticket.quality, AudioQuality.high);
      expect(ticket.isExpired, isFalse);

      // download ticket capability unavailable check
      expect(
        () => provider.createDownloadTicket(
            track: trackRef, quality: AudioQuality.high),
        throwsA(
          isA<CapabilityUnavailableException>().having(
            (error) => error.capability,
            'capability',
            ProviderCapability.resolveDownload,
          ),
        ),
      );
    });
  });
}
