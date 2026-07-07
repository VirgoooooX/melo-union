import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melo_union_app/src/app.dart';
import 'package:melo_union_app/src/bootstrap/demo_repository.dart';
import 'package:melo_union_app/src/fakes/fake_music_provider.dart';
import 'package:provider_contract/provider_contract.dart';

void main() {
  testWidgets('Favorites List updates and sorting do not throw assertions', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final providerId = ProviderId('aurora_stream');

    final songA = SourceTrack(
      ref: ProviderTrackRef(providerId: providerId, trackId: 'song_a'),
      title: 'Alpha Song',
      artists: const ['Melo Artist A'],
      album: 'Album A',
      duration: const Duration(minutes: 4, seconds: 05),
      isFavorited: true,
    );

    final songB = SourceTrack(
      ref: ProviderTrackRef(providerId: providerId, trackId: 'song_b'),
      title: 'Beta Song',
      artists: const ['Melo Artist B'],
      album: 'Album B',
      duration: const Duration(minutes: 3, seconds: 12),
      isFavorited: true,
    );

    final songC = SourceTrack(
      ref: ProviderTrackRef(providerId: providerId, trackId: 'song_c'),
      title: 'Charlie Song',
      artists: const ['Melo Artist C'],
      album: 'Album C',
      duration: const Duration(minutes: 2, seconds: 45),
      isFavorited: false, // Initially not favorited
    );

    final provider = FakeMusicProvider(
      descriptor: ProviderDescriptor(
        id: providerId,
        displayName: 'Aurora Stream',
        capabilities: const {
          ProviderCapability.readFavorites,
          ProviderCapability.writeFavorites,
          ProviderCapability.resolvePlayback,
          ProviderCapability.search,
        },
        status: ProviderStatus.experimental,
        shortDescription: 'Widget test provider',
      ),
      profile: null,
      seedTracks: [songA, songB, songC],
    );

    final repository = DemoRepository.seeded(
      additionalProviders: [provider],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          demoRepositoryProvider.overrideWith((ref) => repository),
        ],
        child: const MeloUnionApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to All Favorites page
    expect(find.text('全部喜欢'), findsWidgets);
    await tester.tap(find.text('全部喜欢').last);
    await tester.pumpAndSettle();

    // Verify initial items exist in the default list
    expect(find.text('Beta Song'), findsWidgets);
    expect(find.text('Alpha Song'), findsWidgets);
    expect(find.text('Charlie Song'), findsNothing);

    // Test sorting by tapping on the sort icon
    final sortButtonFinder = find.byTooltip('排序');
    expect(sortButtonFinder, findsWidgets);
    await tester.tap(sortButtonFinder.last);
    await tester.pumpAndSettle();

    // Tap '歌曲名称' to sort by title
    await tester.tap(find.text('歌曲名称'));
    await tester.pumpAndSettle();

    // Verify no assertion error was thrown and items are sorted (Alpha Song first, then Beta Song)
    final listFinder = find.byType(AnimatedList);
    final alphaInList = find.descendant(of: listFinder, matching: find.text('Alpha Song'));
    final betaInList = find.descendant(of: listFinder, matching: find.text('Beta Song'));
    
    final alphaPos = tester.getTopLeft(alphaInList);
    final betaPos = tester.getTopLeft(betaInList);
    expect(alphaPos.dy < betaPos.dy, isTrue);

    // Test addition of Charlie Song
    await repository.toggleFavorite(track: songC, liked: true);
    await tester.pumpAndSettle();

    // Verify Charlie Song is now visible
    expect(find.text('Charlie Song'), findsWidgets);

    // Test removal of Alpha Song
    await repository.toggleFavorite(track: songA, liked: false);
    await tester.pumpAndSettle();

    // Verify Alpha Song is removed and Charlie / Beta are still there
    expect(find.descendant(of: listFinder, matching: find.text('Alpha Song')), findsNothing);
    expect(find.descendant(of: listFinder, matching: find.text('Beta Song')), findsWidgets);
    expect(find.descendant(of: listFinder, matching: find.text('Charlie Song')), findsWidgets);
  });
}
