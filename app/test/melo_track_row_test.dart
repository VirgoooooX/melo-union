import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/widgets/melo_track_row.dart';

void main() {
  testWidgets('MeloMobileTrackRow renders correct details and handles tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeloMobileTrackRow(
            index: 1,
            title: 'Mobile Track Title',
            artists: const ['Artist A', 'Artist B'],
            artwork: null,
            duration: const Duration(minutes: 3, seconds: 45),
            onTap: () {
              tapped = true;
            },
            trailing: const Text('Custom Trailing'),
          ),
        ),
      ),
    );

    // Expect details
    expect(find.text('Mobile Track Title'), findsOneWidget);
    expect(find.text('Artist A / Artist B'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Custom Trailing'), findsOneWidget);

    // Tap
    await tester.tap(find.text('Mobile Track Title'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('MeloDesktopTrackRow renders correct details', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MeloDesktopTrackRow(
            index: 5,
            title: 'Desktop Track Title',
            artists: const ['Artist C'],
            artwork: null,
            album: 'Album Name',
            trailing: const Text('Desktop Trailing'),
          ),
        ),
      ),
    );

    // Expect details
    expect(find.text('Desktop Track Title'), findsOneWidget);
    expect(find.text('Artist C'), findsOneWidget);
    expect(find.text('05'), findsOneWidget);
    expect(find.text('Album Name'), findsOneWidget);
  });
}
