import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:test/test.dart';

import 'support/fake_music_provider.dart';

void main() {
  group('ProviderCapabilityMatrix', () {
    test('eligible favorites providers must be enabled authenticated readers',
        () {
      final registry = StaticProviderRegistry([
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: ProviderId('alpha_music'),
            displayName: 'Alpha Music',
            capabilities: const {
              ProviderCapability.authenticate,
              ProviderCapability.readFavorites,
            },
          ),
          seedTracks: const [],
        ),
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: ProviderId('beta_library'),
            displayName: 'Beta Library',
            capabilities: const {
              ProviderCapability.readFavorites,
            },
          ),
          seedTracks: const [],
        ),
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: ProviderId('catalog_extra'),
            displayName: 'Catalog Extra',
            capabilities: const {ProviderCapability.search},
          ),
          seedTracks: const [],
        ),
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: ProviderId('gamma_stream'),
            displayName: 'Gamma Stream',
            capabilities: const {
              ProviderCapability.authenticate,
              ProviderCapability.readFavorites,
            },
          ),
          seedTracks: const [],
          isAuthenticated: false,
        ),
      ]);
      registry.setEnabled(ProviderId('catalog_extra'), false);

      final matrix = const ProviderCapabilityMatrix();
      final eligible = matrix.eligibleFavoritesEntries(registry);

      expect(
        eligible.map((entry) => entry.descriptor.id.value),
        ['alpha_music', 'beta_library'],
      );
      expect(
        matrix
            .favoriteWriteAvailability(registry, ProviderId('beta_library'))
            .reason,
        'This source exposes favorites in read-only mode.',
      );
    });
  });

  group('UnifiedFavoritesService', () {
    test(
        'merges obvious same-song variants while keeping source states independent',
        () async {
      final alpha = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('alpha_music'),
          displayName: 'Alpha Music',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites,
          },
        ),
        seedTracks: [
          SourceTrack(
            ref: ProviderTrackRef(
              providerId: ProviderId('alpha_music'),
              trackId: 'alpha_midnight',
            ),
            title: 'Midnight Signal',
            artists: const ['Luna Park'],
            duration: const Duration(minutes: 3, seconds: 10),
            isFavorited: true,
          ),
        ],
      );
      final beta = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('beta_library'),
          displayName: 'Beta Library',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites,
          },
        ),
        seedTracks: [
          SourceTrack(
            ref: ProviderTrackRef(
              providerId: ProviderId('beta_library'),
              trackId: 'beta_midnight',
            ),
            title: 'Midnight Signal',
            artists: const ['Luna Park'],
            duration: const Duration(minutes: 3, seconds: 11),
            isFavorited: true,
          ),
          SourceTrack(
            ref: ProviderTrackRef(
              providerId: ProviderId('beta_library'),
              trackId: 'beta_archive',
            ),
            title: 'Archive Tape',
            artists: const ['Signal Room'],
            duration: const Duration(minutes: 4),
            isFavorited: true,
          ),
        ],
      );

      final service = const UnifiedFavoritesService();
      final unified = await service.buildAllFavorites(
        StaticProviderRegistry([alpha, beta]),
      );

      expect(unified, hasLength(2));
      expect(unified.first.title, 'Midnight Signal');
      expect(unified.last.title, 'Archive Tape');
      expect(unified.first.hasMultipleSources, isTrue);
      expect(
        unified.first.variants.map((variant) => variant.ref.providerId.value),
        containsAll(<String>['alpha_music', 'beta_library']),
      );
    });
  });

  group('Local playlists', () {
    test(
        'supports in-memory CRUD and cached metadata survives disabled providers',
        () {
      final track = SourceTrack(
        ref: ProviderTrackRef(
          providerId: ProviderId('alpha_music'),
          trackId: 'alpha_midnight',
        ),
        title: 'Midnight Signal',
        artists: const ['Luna Park'],
        duration: const Duration(minutes: 3, seconds: 10),
        isFavorited: true,
      );

      final repository = InMemoryLocalPlaylistRepository();
      final playlist = repository.createPlaylist('Commute');
      repository.addTrack(playlistId: playlist.id, track: track);
      repository.renamePlaylist(
          playlistId: playlist.id, nextName: 'Night Ride');

      final updated = repository.listPlaylists().single;
      expect(updated.name, 'Night Ride');
      expect(updated.items.single.cachedTitle, 'Midnight Signal');

      final registry = StaticProviderRegistry([
        FakeMusicProvider(
          descriptor: ProviderDescriptor(
            id: ProviderId('alpha_music'),
            displayName: 'Alpha Music',
            capabilities: const {ProviderCapability.search},
          ),
          seedTracks: [track],
        ),
      ]);
      registry.setEnabled(ProviderId('alpha_music'), false);

      final resolved = PlaylistReferenceResolver(registry).resolve(
        updated.items.single,
      );

      expect(resolved.title, 'Midnight Signal');
      expect(resolved.sourceAvailable, isFalse);
      expect(resolved.unavailableReason, contains('cached metadata'));
    });
  });

  group('CapabilityAwareSearchService', () {
    test('routes search only to enabled providers with search capability',
        () async {
      final alpha = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('alpha_music'),
          displayName: 'Alpha Music',
          capabilities: const {ProviderCapability.search},
        ),
        seedTracks: [
          SourceTrack(
            ref: ProviderTrackRef(
              providerId: ProviderId('alpha_music'),
              trackId: 'alpha_midnight',
            ),
            title: 'Midnight Signal',
            artists: const ['Luna Park'],
            duration: const Duration(minutes: 3),
            isFavorited: true,
          ),
        ],
      );
      final beta = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('beta_library'),
          displayName: 'Beta Library',
          capabilities: const {ProviderCapability.readFavorites},
        ),
        seedTracks: const [],
      );

      final registry = StaticProviderRegistry([alpha, beta]);
      final results =
          await const CapabilityAwareSearchService().searchEverywhere(
        registry: registry,
        query: 'midnight',
      );

      expect(results, hasLength(1));
      expect(results.single.provider.id.value, 'alpha_music');
      expect(results.single.tracks.single.title, 'Midnight Signal');
    });
  });

  group('PlaybackQueueState', () {
    test('replaces queue and moves through entries predictably', () {
      final first = SourceTrack(
        ref: ProviderTrackRef(
          providerId: ProviderId('alpha_music'),
          trackId: 'one',
        ),
        title: 'One',
        artists: const ['Alpha'],
        duration: const Duration(minutes: 3),
        isFavorited: false,
      );
      final second = SourceTrack(
        ref: ProviderTrackRef(
          providerId: ProviderId('beta_library'),
          trackId: 'two',
        ),
        title: 'Two',
        artists: const ['Beta'],
        duration: const Duration(minutes: 4),
        isFavorited: true,
      );

      final queue = PlaybackQueueState.empty()
          .replaceWith([first, second])
          .moveNext()
          .movePrevious();

      expect(queue.entries, hasLength(2));
      expect(queue.current?.track.title, 'One');
      expect(queue.entries.map((entry) => entry.entryId).toSet(), hasLength(2));
    });

    test('moves an existing entry next without changing the current entry', () {
      SourceTrack track(String id) => SourceTrack(
            ref: ProviderTrackRef(
              providerId: ProviderId('alpha_music'),
              trackId: id,
            ),
            title: id,
            artists: const ['Alpha'],
            duration: const Duration(minutes: 3),
            isFavorited: false,
          );

      final initial = PlaybackQueueState.empty()
          .replaceWith(['a', 'b', 'c', 'd'].map(track).toList())
          .moveNext()
          .moveNext();
      final currentId = initial.current!.entryId;
      final moved = initial.moveEntryNext(initial.entries.first.entryId);

      expect(moved.entries.map((entry) => entry.track.title),
          ['b', 'c', 'a', 'd']);
      expect(moved.current?.entryId, currentId);
      expect(moved.next?.track.title, 'a');
      expect(moved.moveEntryNext(moved.next!.entryId), same(moved));
    });
  });

  group('PlaybackCoordinator', () {
    final track = SourceTrack(
      ref: ProviderTrackRef(
        providerId: ProviderId('alpha_music'),
        trackId: 'alpha_track_1',
      ),
      title: 'Alpha Track 1',
      artists: const ['Alpha'],
      duration: const Duration(minutes: 3),
      isFavorited: false,
    );

    test('selects track, resolves ticket, and pre-resolves next track',
        () async {
      final nextTrack = SourceTrack(
        ref: ProviderTrackRef(
          providerId: ProviderId('alpha_music'),
          trackId: 'alpha_track_2',
        ),
        title: 'Alpha Track 2',
        artists: const ['Alpha'],
        duration: const Duration(minutes: 4),
        isFavorited: false,
      );

      final provider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('alpha_music'),
          displayName: 'Alpha Music',
          capabilities: const {ProviderCapability.resolvePlayback},
        ),
        seedTracks: [track, nextTrack],
      );
      final registry = StaticProviderRegistry([provider]);
      final coordinator = PlaybackCoordinator(registry: registry);

      coordinator.setQueue([track, nextTrack]);
      await coordinator.selectTrack(track.ref);
      await Future<void>.delayed(Duration.zero);

      expect(coordinator.currentTicket, isNotNull);
      expect(coordinator.currentTicket!.trackRef, track.ref);
      expect(coordinator.nextTicket, isNotNull);
      expect(coordinator.nextTicket!.trackRef, nextTrack.ref);

      // Verify moving next promotes next ticket
      final previousNextTicket = coordinator.nextTicket;
      await coordinator.next();
      expect(coordinator.currentTicket, same(previousNextTicket));
    });

    test('handles disabled provider and capability unavailable', () async {
      final trackDisabled = SourceTrack(
        ref: ProviderTrackRef(
          providerId: ProviderId('disabled_provider'),
          trackId: 'track_1',
        ),
        title: 'Track 1',
        artists: const ['Artist'],
        duration: const Duration(minutes: 3),
        isFavorited: false,
      );
      final trackNoCapability = SourceTrack(
        ref: ProviderTrackRef(
          providerId: ProviderId('no_cap_provider'),
          trackId: 'track_2',
        ),
        title: 'Track 2',
        artists: const ['Artist'],
        duration: const Duration(minutes: 3),
        isFavorited: false,
      );

      final disabledProv = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('disabled_provider'),
          displayName: 'Disabled',
          capabilities: const {ProviderCapability.resolvePlayback},
        ),
        seedTracks: [trackDisabled],
      );
      final noCapProv = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('no_cap_provider'),
          displayName: 'No Cap',
          capabilities: const {}, // No capabilities
        ),
        seedTracks: [trackNoCapability],
      );

      final registry = StaticProviderRegistry([disabledProv, noCapProv]);
      registry.setEnabled(ProviderId('disabled_provider'), false);

      final coordinator = PlaybackCoordinator(registry: registry);
      coordinator.setQueue([trackDisabled, trackNoCapability]);

      // Test disabled provider
      await coordinator.selectTrack(trackDisabled.ref);
      expect(coordinator.currentTicket, isNull);
      expect(coordinator.currentError, isA<ProviderDisabledException>());

      // Test capability unavailable
      await coordinator.selectTrack(trackNoCapability.ref);
      expect(coordinator.currentTicket, isNull);
      expect(coordinator.currentError, isA<CapabilityUnavailableException>());
    });
  });

  group('Favorites Overrides & Safe Pulling', () {
    final trackA = SourceTrack(
      ref: ProviderTrackRef(
        providerId: ProviderId('alpha_music'),
        trackId: 'track_a',
      ),
      title: 'Same Title',
      artists: const ['Same Artist'],
      duration: const Duration(minutes: 3),
      isFavorited: true,
    );
    final trackB = SourceTrack(
      ref: ProviderTrackRef(
        providerId: ProviderId('beta_library'),
        trackId: 'track_b',
      ),
      title: 'Same Title',
      artists: const ['Same Artist'],
      duration: const Duration(minutes: 3),
      isFavorited: true,
    );

    test('supports merge/split/hidden overrides', () async {
      final alpha = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('alpha_music'),
          displayName: 'Alpha Music',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites
          },
        ),
        seedTracks: [trackA],
      );
      final beta = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('beta_library'),
          displayName: 'Beta Library',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites
          },
        ),
        seedTracks: [trackB],
      );
      final registry = StaticProviderRegistry([alpha, beta]);
      final service = const UnifiedFavoritesService();

      // Without overrides, they merge automatically because of title/artist/duration match
      final normalResult = await service.buildAllFavoritesWithResult(registry);
      expect(normalResult.tracks, hasLength(1));
      expect(normalResult.tracks.first.variants, hasLength(2));

      // With split override, they should be separate
      final overrides = FavoritesOverrideRegistry();
      overrides.addSplitOverride(trackA.ref, trackB.ref);
      final splitResult = await service.buildAllFavoritesWithResult(registry,
          overrides: overrides);
      expect(splitResult.tracks, hasLength(2));

      // With hidden override, trackA should be hidden
      final hiddenOverrides = FavoritesOverrideRegistry();
      hiddenOverrides.hideTrack(trackA.ref);
      final hiddenResult = await service.buildAllFavoritesWithResult(registry,
          overrides: hiddenOverrides);
      expect(hiddenResult.tracks, hasLength(1));
      expect(hiddenResult.tracks.first.variants.first.ref, trackB.ref);
    });

    test('safe pull handles failures gracefully per provider', () async {
      final alpha = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('alpha_music'),
          displayName: 'Alpha Music',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites
          },
        ),
        seedTracks: [trackA],
      );
      final beta = _ThrowingFavoritesProvider();

      final registry = StaticProviderRegistry([alpha, beta]);
      final service = const UnifiedFavoritesService();

      final result = await service.buildAllFavoritesWithResult(registry);
      // alpha succeeds, beta fails. alpha's track should still be present.
      expect(result.tracks, hasLength(1));
      expect(result.tracks.first.variants.single.ref, trackA.ref);
      expect(result.failures.containsKey(ProviderId('beta_library')), isTrue);
    });

    test('normalizes QQ liked-at records across changing extra ids', () {
      final qqProviderId = ProviderId('qq_music');
      final refV1 = ProviderTrackRef(
        providerId: qqProviderId,
        trackId: '003QDnvP3ygUkH',
        extraIds: const {
          'song_mid': '003QDnvP3ygUkH',
          'album_mid': '004WLsw812xIlg',
        },
      );
      final refV2 = ProviderTrackRef(
        providerId: qqProviderId,
        trackId: '003QDnvP3ygUkH',
        extraIds: const {
          'song_mid': '003QDnvP3ygUkH',
          'media_mid': '003QDnvP3ygUkH',
          'album_mid': '004WLsw812xIlg',
        },
      );
      final refV3 = ProviderTrackRef(
        providerId: qqProviderId,
        trackId: '003QDnvP3ygUkH',
        extraIds: const {
          'song_id': '590860903',
          'song_type': '0',
          'song_mid': '003QDnvP3ygUkH',
          'media_mid': '003QDnvP3ygUkH',
          'album_mid': '004WLsw812xIlg',
        },
      );

      final ledger = LikedAtLedger();
      final olderEstimate = DateTime.utc(2026, 6, 30, 11);
      final newerEstimate = DateTime.utc(2026, 7, 1, 7);
      final appActionTime = DateTime.utc(2026, 6, 29, 9);

      ledger.record(
        refV1,
        LikedAtMetadata(
          likedAt: olderEstimate,
          source: LikedAtMetadata.sourceQqImport,
          precision: LikedAtMetadata.precisionUnknown,
        ),
      );
      ledger.record(
        refV2,
        LikedAtMetadata(
          likedAt: newerEstimate,
          source: LikedAtMetadata.sourceQqImport,
          precision: LikedAtMetadata.precisionUnknown,
        ),
      );

      expect(ledger.entries, hasLength(1));
      expect(ledger.likedAtFor(refV1)?.likedAt, newerEstimate);
      expect(ledger.likedAtFor(refV3)?.likedAt, newerEstimate);

      ledger.record(
        refV3,
        LikedAtMetadata(
          likedAt: appActionTime,
          source: LikedAtMetadata.sourceAppAction,
          precision: LikedAtMetadata.precisionExact,
        ),
      );

      expect(ledger.entries, hasLength(1));
      expect(ledger.likedAtFor(refV1)?.likedAt, appActionTime);
      expect(
        ledger.likedAtFor(refV2)?.source,
        LikedAtMetadata.sourceAppAction,
      );
    });

    test('normalizes QQ liked-at records by song id before song mid', () {
      final qqProviderId = ProviderId('qq_music');
      final oldRef = ProviderTrackRef(
        providerId: qqProviderId,
        trackId: 'old_song_mid',
        extraIds: const {
          'song_id': '590860903',
          'song_mid': 'old_song_mid',
        },
      );
      final reimportedRef = ProviderTrackRef(
        providerId: qqProviderId,
        trackId: 'new_song_mid',
        extraIds: const {
          'song_id': '590860903',
          'song_mid': 'new_song_mid',
        },
      );
      final existingEstimate = DateTime.utc(2026, 6, 30, 11);

      final ledger = LikedAtLedger()
        ..record(
          oldRef,
          LikedAtMetadata(
            likedAt: existingEstimate,
            source: LikedAtMetadata.sourceQqImport,
            precision: LikedAtMetadata.precisionUnknown,
          ),
        );

      expect(ledger.likedAtFor(reimportedRef)?.likedAt, existingEstimate);

      ledger.record(
        reimportedRef,
        LikedAtMetadata(
          likedAt: DateTime.utc(2026, 7, 1, 7),
          source: LikedAtMetadata.sourceQqImport,
          precision: LikedAtMetadata.precisionUnknown,
        ),
      );

      expect(ledger.entries, hasLength(1));
      expect(ledger.entries.single.ref, reimportedRef);
    });

    test('reuses normalized QQ estimate when current ref shape changes',
        () async {
      final qqProviderId = ProviderId('qq_music');
      final oldRef = ProviderTrackRef(
        providerId: qqProviderId,
        trackId: '003QDnvP3ygUkH',
        extraIds: const {
          'song_mid': '003QDnvP3ygUkH',
          'album_mid': '004WLsw812xIlg',
        },
      );
      final currentRef = ProviderTrackRef(
        providerId: qqProviderId,
        trackId: '003QDnvP3ygUkH',
        extraIds: const {
          'song_id': '590860903',
          'song_type': '0',
          'song_mid': '003QDnvP3ygUkH',
          'media_mid': '003QDnvP3ygUkH',
          'album_mid': '004WLsw812xIlg',
        },
      );
      final existingEstimate = DateTime.utc(2026, 6, 30, 11);
      final ledger = LikedAtLedger()
        ..record(
          oldRef,
          LikedAtMetadata(
            likedAt: existingEstimate,
            source: LikedAtMetadata.sourceQqImport,
            precision: LikedAtMetadata.precisionUnknown,
          ),
        );
      final qqProvider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: qqProviderId,
          displayName: 'QQ Music',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites,
          },
        ),
        seedTracks: [
          SourceTrack(
            ref: currentRef,
            title: 'Borrowed Light',
            artists: const ['Signal Room'],
            duration: const Duration(minutes: 3),
            isFavorited: true,
            likedAtSource: LikedAtMetadata.sourceQqImport,
            likedAtPrecision: LikedAtMetadata.precisionUnknown,
          ),
        ],
      );

      final result =
          await const UnifiedFavoritesService().buildAllFavoritesWithResult(
        StaticProviderRegistry([qqProvider]),
        likedAtLedger: ledger,
      );

      expect(ledger.entries, hasLength(1));
      final variant = result.tracks.single.variants.single;
      expect(variant.ref, currentRef);
      expect(variant.likedAt, existingEstimate);
      expect(variant.likedAtSource, LikedAtMetadata.sourceQqImport);
      expect(variant.likedAtPrecision, LikedAtMetadata.precisionUnknown);
    });

    test('keeps QQ local estimate even when provider includes time', () async {
      final qqProviderId = ProviderId('qq_music');
      final oldRef = ProviderTrackRef(
        providerId: qqProviderId,
        trackId: '003QDnvP3ygUkH',
        extraIds: const {'song_mid': '003QDnvP3ygUkH'},
      );
      final currentRef = ProviderTrackRef(
        providerId: qqProviderId,
        trackId: '003QDnvP3ygUkH',
        extraIds: const {
          'song_id': '590860903',
          'song_mid': '003QDnvP3ygUkH',
        },
      );
      final estimate = DateTime.utc(2026, 6, 30, 11);
      final exact = DateTime.utc(2026, 7, 1, 8);
      final ledger = LikedAtLedger()
        ..record(
          oldRef,
          LikedAtMetadata(
            likedAt: estimate,
            source: LikedAtMetadata.sourceQqImport,
            precision: LikedAtMetadata.precisionUnknown,
          ),
        );
      final qqProvider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: qqProviderId,
          displayName: 'QQ Music',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites,
          },
        ),
        seedTracks: [
          SourceTrack(
            ref: currentRef,
            title: 'Borrowed Light',
            artists: const ['Signal Room'],
            duration: const Duration(minutes: 3),
            isFavorited: true,
            likedAt: exact,
            likedAtSource: LikedAtMetadata.sourceQqImport,
            likedAtPrecision: LikedAtMetadata.precisionExact,
          ),
        ],
      );

      final result =
          await const UnifiedFavoritesService().buildAllFavoritesWithResult(
        StaticProviderRegistry([qqProvider]),
        likedAtLedger: ledger,
      );

      expect(ledger.entries, hasLength(1));
      expect(ledger.likedAtFor(oldRef)?.likedAt, estimate);
      expect(
        ledger.likedAtFor(currentRef)?.precision,
        LikedAtMetadata.precisionUnknown,
      );
      expect(result.tracks.single.variants.single.likedAt, estimate);
    });

    test(
        'does not estimate Kugou imported favorites when raw collecttime is absent',
        () async {
      final kugouProviderId = ProviderId('kugou');
      final ref = ProviderTrackRef(
        providerId: kugouProviderId,
        trackId: 'kugou_hash',
        extraIds: const {'favoriteFileId': '1'},
      );
      final overrides = FavoritesOverrideRegistry();
      final kugouProvider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: kugouProviderId,
          displayName: 'Kugou',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites,
          },
        ),
        seedTracks: [
          SourceTrack(
            ref: ref,
            title: 'Blue Lotus',
            artists: const ['Xu Wei'],
            duration: const Duration(minutes: 4),
            isFavorited: true,
            likedAtSource: LikedAtMetadata.sourceKugouImport,
            likedAtPrecision: LikedAtMetadata.precisionUnknown,
          ),
        ],
      );

      final result =
          await const UnifiedFavoritesService().buildAllFavoritesWithResult(
        StaticProviderRegistry([kugouProvider]),
        overrides: overrides,
      );

      final ledger = LikedAtLedger();
      expect(ledger.likedAtFor(ref), isNull);
      expect(result.tracks.single.variants.single.likedAt, isNull);
    });

    test('uses Kugou raw collecttime without storing it in the local ledger',
        () async {
      final kugouProviderId = ProviderId('kugou');
      final oldRef = ProviderTrackRef(
        providerId: kugouProviderId,
        trackId: 'kugou_hash',
      );
      final currentRef = ProviderTrackRef(
        providerId: kugouProviderId,
        trackId: 'kugou_hash',
        extraIds: const {'favoriteFileId': '1'},
      );
      final estimate = DateTime.utc(2026, 7, 1, 8);
      final raw = DateTime.utc(2026, 7, 6, 12);
      final ledger = LikedAtLedger()
        ..record(
          oldRef,
          LikedAtMetadata(
            likedAt: estimate,
            source: LikedAtMetadata.sourceKugouImport,
            precision: LikedAtMetadata.precisionUnknown,
          ),
        );
      final kugouProvider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: kugouProviderId,
          displayName: 'Kugou',
          capabilities: const {
            ProviderCapability.authenticate,
            ProviderCapability.readFavorites,
          },
        ),
        seedTracks: [
          SourceTrack(
            ref: currentRef,
            title: 'Blue Lotus',
            artists: const ['Xu Wei'],
            duration: const Duration(minutes: 4),
            isFavorited: true,
            likedAt: raw,
            likedAtSource: LikedAtMetadata.sourceKugouRaw,
            likedAtPrecision: LikedAtMetadata.precisionExact,
          ),
        ],
      );

      final result =
          await const UnifiedFavoritesService().buildAllFavoritesWithResult(
        StaticProviderRegistry([kugouProvider]),
        likedAtLedger: ledger,
      );

      expect(ledger.likedAtFor(oldRef)?.likedAt, estimate);
      expect(ledger.likedAtFor(currentRef)?.source,
          LikedAtMetadata.sourceKugouImport);
      expect(result.tracks.single.variants.single.likedAt, raw);
    });
  });

  group('DownloadCoordinator', () {
    final track = SourceTrack(
      ref: ProviderTrackRef(
        providerId: ProviderId('alpha_music'),
        trackId: 'alpha_track_1',
      ),
      title: 'Alpha Track 1',
      artists: const ['Alpha'],
      duration: const Duration(minutes: 3),
      isFavorited: false,
    );

    test('manages queue and requests fresh ticket on start/resume', () async {
      final provider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('alpha_music'),
          displayName: 'Alpha Music',
          capabilities: const {ProviderCapability.resolveDownload},
        ),
        seedTracks: [track],
      );
      final registry = StaticProviderRegistry([provider]);
      final coordinator = DownloadCoordinator(registry: registry);

      coordinator.addTask(track);
      expect(coordinator.allTasks, hasLength(1));
      expect(coordinator.allTasks.first.status, DownloadStatus.queued);

      // Start task resolves ticket
      await coordinator.startTask(track.ref);
      final taskAfterStart = coordinator.getTask(track.ref)!;
      expect(taskAfterStart.status, DownloadStatus.downloading);
      expect(taskAfterStart.ticket, isNotNull);

      final firstTicket = taskAfterStart.ticket!;

      // Pause task clears ticket
      coordinator.pauseTask(track.ref);
      final taskAfterPause = coordinator.getTask(track.ref)!;
      expect(taskAfterPause.status, DownloadStatus.paused);
      expect(taskAfterPause.ticket, isNull);

      // Resume task fetches fresh ticket
      await coordinator.resumeTask(track.ref);
      final taskAfterResume = coordinator.getTask(track.ref)!;
      expect(taskAfterResume.status, DownloadStatus.downloading);
      expect(taskAfterResume.ticket, isNotNull);
      expect(taskAfterResume.ticket, isNot(same(firstTicket)));
    });

    test('supports simulation to completion and local library update',
        () async {
      final provider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('alpha_music'),
          displayName: 'Alpha Music',
          capabilities: const {ProviderCapability.resolveDownload},
        ),
        seedTracks: [track],
      );
      final registry = StaticProviderRegistry([provider]);
      final coordinator = DownloadCoordinator(registry: registry);

      coordinator.addTask(track);
      await coordinator.runSimulationToCompletion(track.ref);

      final completedTask = coordinator.getTask(track.ref)!;
      expect(completedTask.status, DownloadStatus.completed);
      expect(completedTask.progress, 1.0);
      expect(completedTask.ticket, isNull); // ticket is cleared on completion

      expect(coordinator.isAvailableLocally(track.ref), isTrue);
      final localItem = coordinator.getLocalItem(track.ref)!;
      expect(localItem.title, track.title);
      expect(localItem.filePath, startsWith('local://downloads/'));
    });

    test('hydrates persisted task and local library state', () {
      final localItem = LocalMediaItem(
        sourceRef: track.ref,
        title: track.title,
        artists: track.artists,
        duration: track.duration,
        filePath: 'local://downloads/alpha_music/alpha_track_1.mp3',
        fileSize: 1024,
        downloadedAt: DateTime.utc(2026, 6, 29),
      );
      final persistedTask = DownloadTask(
        track: track,
        quality: AudioQuality.standard,
        status: DownloadStatus.completed,
        progress: 1,
        savedFilePath: localItem.filePath,
        createdAt: DateTime.utc(2026, 6, 28),
      );

      final coordinator = DownloadCoordinator(
        registry: StaticProviderRegistry(const []),
        seedTasks: [persistedTask],
        seedLocalItems: [localItem],
      );

      expect(coordinator.isAvailableLocally(track.ref), isTrue);
      expect(coordinator.getTask(track.ref)?.status, DownloadStatus.completed);
      expect(coordinator.getTask(track.ref)?.ticket, isNull);
      expect(coordinator.getLocalItem(track.ref)?.filePath, localItem.filePath);
    });

    test('removes local media and resets task for redownload', () {
      final localItem = LocalMediaItem(
        sourceRef: track.ref,
        title: track.title,
        artists: track.artists,
        duration: track.duration,
        filePath: 'local://downloads/alpha_music/alpha_track_1.mp3',
        fileSize: 1024,
        downloadedAt: DateTime.utc(2026, 6, 29),
      );
      final coordinator = DownloadCoordinator(
        registry: StaticProviderRegistry(const []),
        seedTasks: [
          DownloadTask(
            track: track,
            quality: AudioQuality.standard,
            status: DownloadStatus.completed,
            progress: 1,
            savedFilePath: localItem.filePath,
          ),
        ],
        seedLocalItems: [localItem],
      );

      coordinator.removeLocalItem(track.ref);

      expect(coordinator.isAvailableLocally(track.ref), isFalse);
      expect(coordinator.getTask(track.ref)?.status, DownloadStatus.cancelled);
      expect(coordinator.getTask(track.ref)?.progress, 0);
      expect(coordinator.getTask(track.ref)?.savedFilePath, isNull);
    });

    test('handles capability unavailable and disabled reasons', () async {
      final disabledProvider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('disabled_music'),
          displayName: 'Disabled Music',
          capabilities: const {ProviderCapability.resolveDownload},
        ),
        seedTracks: [
          track.copyWith(
              ref: ProviderTrackRef(
                  providerId: ProviderId('disabled_music'), trackId: '1'))
        ],
      );
      final noDownloadProvider = FakeMusicProvider(
        descriptor: ProviderDescriptor(
          id: ProviderId('no_dl_music'),
          displayName: 'No Download Music',
          capabilities: const {}, // No capabilities
        ),
        seedTracks: [
          track.copyWith(
              ref: ProviderTrackRef(
                  providerId: ProviderId('no_dl_music'), trackId: '1'))
        ],
      );

      final registry =
          StaticProviderRegistry([disabledProvider, noDownloadProvider]);
      registry.setEnabled(ProviderId('disabled_music'), false);

      final coordinator = DownloadCoordinator(registry: registry);

      final disabledTrack = track.copyWith(
          ref: ProviderTrackRef(
              providerId: ProviderId('disabled_music'), trackId: '1'));
      final noDlTrack = track.copyWith(
          ref: ProviderTrackRef(
              providerId: ProviderId('no_dl_music'), trackId: '1'));

      coordinator.addTask(disabledTrack);
      coordinator.addTask(noDlTrack);

      await coordinator.startTask(disabledTrack.ref);
      expect(coordinator.getTask(disabledTrack.ref)!.status,
          DownloadStatus.failed);
      expect(
          coordinator.getTask(disabledTrack.ref)!.error, contains('disabled'));

      await coordinator.startTask(noDlTrack.ref);
      expect(coordinator.getTask(noDlTrack.ref)!.status, DownloadStatus.failed);
      expect(coordinator.getTask(noDlTrack.ref)!.error, contains('downloads'));
    });
  });
}

final class _ThrowingFavoritesProvider implements MusicProvider {
  @override
  final ProviderDescriptor descriptor = ProviderDescriptor(
    id: ProviderId('beta_library'),
    displayName: 'Beta Library',
    capabilities: const {ProviderCapability.readFavorites},
  );

  @override
  bool get isAuthenticated => true;

  @override
  Future<ProviderAccountProfile?> getProfile() async => null;

  @override
  Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false}) async {
    throw Exception('Simulated failure');
  }

  @override
  Future<List<SourceTrack>> search(String query) async => [];

  @override
  Future<void> setFavorite(
      {required ProviderTrackRef track, required bool liked}) async {}

  @override
  Future<List<SourceTrack>> getDailyRecommendations() async => [];

  @override
  Future<List<ProviderPlaylist>> getRecommendedPlaylists({
    int limit = 12,
  }) async =>
      [];

  @override
  Future<List<ProviderPlaylist>> getChartPlaylists({
    int limit = 20,
  }) async =>
      [];

  @override
  Future<List<ProviderPlaylist>> getUserPlaylists() async => [];

  @override
  Future<List<SourceTrack>> getPlaylistTracks(String playlistId) async => [];

  @override
  Future<PlaybackTicket> createPlaybackTicket(
      {required ProviderTrackRef track, required AudioQuality quality}) async {
    throw UnimplementedError();
  }

  @override
  Future<DownloadTicket> createDownloadTicket(
      {required ProviderTrackRef track, required AudioQuality quality}) async {
    throw UnimplementedError();
  }

  @override
  Future<String?> getLyrics(ProviderTrackRef track) async {
    throw UnimplementedError();
  }
}
