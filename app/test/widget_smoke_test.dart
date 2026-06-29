import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:melo_union_app/src/app.dart';

void main() {
  testWidgets('phase 1-5 app shell renders usable navigation', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MeloUnionApp()));
    await tester.pumpAndSettle();

    expect(find.text('全部喜欢'), findsWidgets);
    expect(find.text('推荐'), findsWidgets);
    expect(find.text('歌单'), findsWidgets);
    expect(find.text('搜索'), findsWidgets);
    expect(find.text('设置'), findsWidgets);

    await tester.tap(find.text('设置').last);
    await tester.pumpAndSettle();

    expect(find.text('管理音乐来源、播放行为、下载与应用偏好。'), findsOneWidget);
  });
}
