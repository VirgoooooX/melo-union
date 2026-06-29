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
    expect(find.text('下载'), findsWidgets);

    await tester.tap(find.text('下载').first);
    await tester.pumpAndSettle();

    expect(find.text('离线下载与本地媒体'), findsOneWidget);
  });
}
