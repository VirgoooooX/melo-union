import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melo_union_app/src/app.dart';
import 'package:melo_union_app/src/bootstrap/demo_repository.dart';
import 'package:melo_union_app/src/fakes/fake_music_provider.dart';
import 'package:provider_contract/provider_contract.dart';

void main() {
  testWidgets('phase 1-5 app shell renders usable navigation', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 900);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(const ProviderScope(child: MeloUnionApp()));
    await tester.pumpAndSettle();

    expect(find.text('全部喜欢'), findsWidgets);
    expect(find.text('推荐'), findsWidgets);
    expect(find.text('歌单'), findsWidgets);
    expect(find.text('下载'), findsWidgets);
    expect(find.text('设置'), findsWidgets);

    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();

    expect(find.text('管理音乐来源、播放行为与应用偏好。'), findsOneWidget);
    expect(find.text('备份与恢复'), findsOneWidget);

    await tester.tap(find.text('播放设置'));
    await tester.pumpAndSettle();

    expect(find.text('记住播放队列'), findsOneWidget);
    expect(find.text('启动后恢复播放进度'), findsOneWidget);
  });

  testWidgets('mobile shell uses single-column music UI and opens player',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    final providerId = ProviderId('aurora_stream');
    final repository = DemoRepository.seeded(
      additionalProviders: [
        FakeMusicProvider(
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
          seedTracks: [
            SourceTrack(
              ref: ProviderTrackRef(providerId: providerId, trackId: 'song_1'),
              title: 'Test Song',
              artists: const ['Melo Artist'],
              album: 'Mobile Smoke',
              duration: const Duration(minutes: 3, seconds: 12),
              isFavorited: true,
            ),
          ],
        ),
      ],
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

    expect(find.text('推荐'), findsOneWidget);
    expect(find.text('喜欢'), findsOneWidget);
    expect(find.text('搜索'), findsOneWidget);
    expect(find.text('歌单'), findsOneWidget);
    expect(find.text('我的'), findsOneWidget);
    expect(find.text('歌曲'), findsNothing);

    await tester.tap(find.text('我的'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('播放恢复'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('播放恢复'), findsOneWidget);
    expect(find.text('启动后恢复播放进度'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('备份与恢复'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    expect(find.text('备份与恢复'), findsOneWidget);
    await tester.tap(find.text('喜欢'));
    await tester.pumpAndSettle();

    expect(find.text('Test Song'), findsWidgets);
    await tester.tap(find.text('Test Song').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('正在播放'), findsOneWidget);
  });
}
