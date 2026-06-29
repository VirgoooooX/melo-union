# 06 · 现有 Flutter 骨架的设计接入计划

仓库已经包含 Phase 1–5 的 Flutter MVP 骨架、Provider Contract、Domain 与 Fake Provider。设计落地应在不破坏这些能力验证逻辑的前提下，逐步替换视觉 Shell 和页面组件。

## 1. 本次已完成

- 设计方向从概念图收敛为 `docs/design/` 的可开发规格。
- 定义浅色默认 Token、一级导航、Provider Tabs、全宽播放条和跨端布局规则。
- 增加 `app/lib/src/design/` 的 Token 与 Theme 基线。
- 不改动真实 Provider 接入边界；不因为 UI 改造伪造登录、收藏或播放能力。

## 2. 当前代码与目标视觉的差异

当前 `app/lib/src/app.dart` 使用深色 Theme 作为 MVP 骨架视觉。批准设计稿采用浅色音乐库界面，因此下一步应由 Theme 和可复用组件驱动视觉迁移，而不是在每个页面散落改色。

## 3. 推荐实施顺序

### Step 1：Theme 与 Token

- 引入 `MeloTheme.light()` 作为 `ThemeMode.light` 默认主题。
- 页面中逐步清理硬编码深色 `Color(...)`。
- 所有间距、圆角、来源色、状态色从 `MeloTokens` 获取。

### Step 2：Desktop Shell

实现或替换以下组件：

```text
DesktopPrimarySidebar
DesktopContentScaffold
ProviderTabs
NowPlayingPane
DesktopPlayerBar
```

验收：桌面窗口下左侧只有一级导航；内容区没有重复的大标题；底部播放条全宽贯通。

### Step 3：页面 Mock UI

先使用既有 Fake Provider 和 Mock 数据完成：

```text
FavoritesPage
PlaylistsPage
RecommendationsPage
```

验收：Tabs 可以切换不同 Provider；页面依然通过 capabilities 决定显示；不应出现 QQ/网易云硬编码的业务分支。

### Step 4：Mobile Shell

实现：

```text
MobileScaffold
MobileProviderTabs
MobileMiniPlayer
MobileBottomNavigation
FullPlayerPage
```

验收：喜欢、歌单、推荐三页与 Windows 语义一致；移动端无正文大标题；Mini Player 与 Bottom Navigation 不重叠。

### Step 5：完整状态

接入 Skeleton、空态、未登录 Banner、局部 Provider 错误、收藏乐观更新、队列抽屉和下载状态机视觉。

### Step 6：真数据回归

Provider Spike 通过后，逐条验证：

- 从官方客户端新增喜欢 → App 刷新后出现。
- App 点 ♥ → 正确平台官方客户端可见。
- 只读 Provider 的心形禁用且有原因。
- 远端 Provider 故障时，全部喜欢保留其他来源。
- 播放 URL 失效时播放器不会静默卡死。

## 4. 建议的目录演进

```text
app/lib/src/
├─ design/
│  ├─ melo_tokens.dart
│  └─ melo_theme.dart
├─ presentation/
│  ├─ shell/
│  │  ├─ desktop_shell.dart
│  │  └─ mobile_shell.dart
│  ├─ components/
│  │  ├─ provider_tabs.dart
│  │  ├─ source_tag.dart
│  │  ├─ song_row.dart
│  │  ├─ playlist_card.dart
│  │  ├─ favorite_button.dart
│  │  ├─ now_playing_pane.dart
│  │  └─ player_bar.dart
│  └─ pages/
│     ├─ favorites_page.dart
│     ├─ playlists_page.dart
│     └─ recommendations_page.dart
└─ ... existing domain/application/data wiring
```

现有文件不必一次性搬家；先新建组件、逐页迁移，完成一页再删除旧 UI。

## 5. Do / Don't

### Do

- 先用 Fake Provider 验证视觉与交互，再接真实协议。
- 所有来源显示、Tabs 和禁用状态都通过 capability 与 descriptor 驱动。
- 用 Storybook 类页面或 Widget Test 覆盖关键组件状态。
- 每次 UI 改动均验证 Windows 宽屏、窄窗和 Android 手机。

### Don't

- 不为复刻视觉稿而修改 Provider Contract 的领域语义。
- 不把 Provider 名称写死在 Sidebar 或 Page 判断中。
- 不直接把 AI 概念图当作像素级唯一规范；本目录 Token 优先。
- 不在 Theme 迁移时顺手改登录、播放、下载等未验证协议逻辑。
