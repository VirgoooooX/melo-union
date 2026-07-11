import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/widgets/melo_track_row.dart';

void main() {
  Widget row({required bool downloaded, required bool cached}) {
    return MaterialApp(
      home: Scaffold(
        body: MeloMobileTrackRow(
          index: 1,
          title: 'Track',
          artists: const ['Artist'],
          artwork: null,
          duration: const Duration(minutes: 3),
          isDownloaded: downloaded,
          isCached: cached,
        ),
      ),
    );
  }

  testWidgets('shows the cache indicator for an effective cache',
      (tester) async {
    await tester.pumpWidget(row(downloaded: false, cached: true));

    expect(find.byIcon(Icons.cached_rounded), findsOneWidget);
    expect(find.bySemanticsLabel('已缓存，可离线播放；缓存可能被自动清理'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_circle_down_rounded), findsNothing);
  });

  testWidgets('download indicator takes precedence over cache', (tester) async {
    await tester.pumpWidget(row(downloaded: true, cached: true));

    expect(find.byIcon(Icons.arrow_circle_down_rounded), findsOneWidget);
    expect(find.byIcon(Icons.cached_rounded), findsNothing);
  });
}
