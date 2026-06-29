# MeloUnion Design Layer

`melo_tokens.dart` 和 `melo_theme.dart` 是设计规范对应的 Flutter 入口。

推荐的接线方式：

```dart
import 'design/melo_theme.dart';

return MaterialApp.router(
  themeMode: ThemeMode.light,
  theme: MeloTheme.light(),
  routerConfig: router,
);
```

页面实现中优先使用：

```dart
MeloColors.primary600
MeloColors.canvas
MeloSpacing.md
MeloRadii.lg
MeloDimensions.desktopPlayerBarHeight
```

不要在页面里散落 `Color(0xFF...)`、裸露间距常量或 Provider 平台特判。完整规格在 `docs/design/`。
