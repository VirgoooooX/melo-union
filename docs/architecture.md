# MeloUnion 架构与技术设计

## 1. 产品定义

MeloUnion 是一个 Windows + Android 双端统一音乐客户端。核心目标不是迁移歌单，而是把两个远端动态歌单做成一个可播放、可管理的虚拟联合视图：

```text
网易云「我喜欢的音乐」 ─┐
                        ├─→ 虚拟歌单「全部喜欢」
QQ 音乐「我喜欢」      ─┘
```

两个远端歌单仍由原平台管理。App 只读取、合并、缓存和展示；用户在 App 内点 ♥ 时，必须按歌曲的原始来源写回对应平台。

另有一套独立的本地自定义歌单，可混放 QQ 与网易云歌曲的引用。

## 2. 目标与边界

### 必做

- QQ 音乐、网易云音乐账号接入。
- 读取两家的「我喜欢」。
- 虚拟「全部喜欢」：统一查看、搜索、排序、随机播放。
- 按来源平台收藏 / 取消收藏。
- 本地自定义歌单：创建、重命名、排序、混合来源歌曲。
- Windows 与 Android 的播放队列、循环、随机、后台播放与媒体控制。
- 单曲下载、下载队列、恢复与本地优先播放。
- 登录过期、网络异常、平台能力缺失的可解释降级。

### 首版非目标

- 评论、社交、MV、播客、电台、直播。
- 自动跨平台换源。
- 跨设备同步本地歌单。
- 歌词逐字高亮与音效。
- 服务端托管账号 Cookie、播放票据或下载票据。

## 3. 总体分层

```text
┌──────────────────────────────────────────────┐
│ Flutter Presentation                          │
│ 页面、组件、响应式布局、ViewModel / Riverpod  │
└──────────────────────┬───────────────────────┘
                       │
┌──────────────────────▼───────────────────────┐
│ Application Services                          │
│ UnifiedFavorites / FavoriteMutation /         │
│ LocalPlaylist / Playback / Download           │
└───────────────┬────────────────┬─────────────┘
                │                │
┌───────────────▼───────┐ ┌──────▼─────────────┐
│ Provider Adapters     │ │ Local Data          │
│ NeteaseProvider       │ │ Drift / SQLite      │
│ QQMusicProvider       │ │ Secure Storage      │
│ FakeProvider          │ │ Cache / Outbox      │
└───────────────┬───────┘ └────────────────────┘
                │
┌───────────────▼──────────────────────────────┐
│ Platform Bridges                              │
│ Android: Kotlin Media3 + MediaSessionService  │
│ Windows: audio engine + SMTC native plugin    │
└──────────────────────────────────────────────┘
```

### 层间规则

1. Flutter 页面不得直接请求 QQ 或网易云接口。
2. 页面不得直接读写 SQLite。
3. 平台协议、Cookie、请求签名只能存在于各自 Provider 包中。
4. 播放器只接受标准化的 `PlaybackTicket`，不理解 QQ 或网易云协议。
5. 本地歌单只保存 `ProviderTrackRef`，不复制远端歌曲或歌单数据。

## 4. 模块职责

### `provider_contract`

定义平台无关的统一能力：

```dart
enum ProviderId { netease, qqMusic }

class ProviderTrackRef {
  final ProviderId provider;
  final String trackId;
  final Map<String, String> extraIds;
}

abstract interface class MusicProvider {
  ProviderId get id;

  Future<AccountProfile> getProfile();
  Future<FavoriteSnapshot> pullFavorites({String? cursor, bool forceRefresh = false});
  Future<List<SourceTrack>> getDailyRecommendations();
  Future<SearchPage> search({required String keyword, String? cursor});

  Future<FavoriteMutationResult> setFavorite({
    required ProviderTrackRef track,
    required bool liked,
  });

  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  });

  Future<DownloadTicket?> createDownloadTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  });
}
```

Provider 通过 `ProviderCapabilities` 显式报告能力，不可默认假设“能播放、能下载、能写收藏”。

### `music_domain`

不依赖 Flutter、Dio、SQLite 或任一平台协议的核心逻辑：

- `UnifiedTrack` 合并。
- 标准化标题、歌手和时长。
- 去重匹配与置信度。
- 收藏目标选择。
- 本地歌单排序规则。
- 下载状态机。

### `music_data`

包含 Drift 数据库、Secure Storage、缓存、Repository 实现和 Outbox 持久化。

### Platform Bridges

负责操作系统特性：Android 后台媒体服务、Windows SMTC、文件选择、下载目录和媒体通知。

## 5. 关键模型

### 原始来源歌曲

```dart
class SourceTrack {
  final ProviderTrackRef ref;
  final String title;
  final List<String> artists;
  final String? album;
  final String? albumId;
  final String? isrc;
  final Duration duration;
  final Uri? artwork;
  final bool isFavorited;
  final bool isPlayable;
  final bool isDownloadable;
}
```

### 聚合歌曲

```dart
class UnifiedTrack {
  final String unifiedId;
  final List<SourceTrack> variants;
  final ProviderTrackRef defaultVariant;
  final double mergeConfidence;
  final bool isUserMerged;
}
```

一首 `UnifiedTrack` 可以有一个或多个 `SourceTrack`。收藏状态永远存在于每个 variant 上，而不是单一 `favorite: bool`。

### 三个不可混淆的引用

```text
originRef          歌曲从哪个平台条目进入当前上下文
playbackRef        当前实际使用哪个来源播放
favoriteTargetRef  点击 ♥ 时应该写回哪个来源
```

播放换源不能改变收藏目标。

## 6. 虚拟「全部喜欢」

### 刷新流程

```text
进入页面 / 用户下拉刷新
  ↓
并行拉取网易云与 QQ 的 favorites 快照
  ↓
写入 remote_favorite_snapshots
  ↓
标准化元数据
  ↓
自动匹配 + 手动合并/拆分规则
  ↓
生成 UnifiedTrack 列表
```

### 去重策略

优先级：

1. ISRC 完全一致。
2. 平台明确提供的同曲关系。
3. 标准化歌名 + 主歌手集合一致 + 时长误差 ≤ 2 秒。
4. 用户手动合并。
5. 其余保留为独立歌曲。

不可因名称近似而合并：Live、Remix、DJ、伴奏、翻唱、纯音乐、不同语言版、不同录音室版。

### 用户覆盖规则

```text
merge_override  强制将两条来源视为同一首
split_override  强制将两条来源分开显示
hidden_tracks   在“全部喜欢”中隐藏某个聚合结果
```

## 7. 收藏写回与 Outbox

### 规则

- 网易云推荐、搜索或本地歌单中的网易云歌：写回网易云。
- QQ 推荐、搜索或本地歌单中的 QQ 歌：写回 QQ。
- 「全部喜欢」中单来源歌曲：直接操作该来源。
- 双来源聚合歌曲：显示两个独立开关，禁止不加提示地一次取消两边。

### 乐观更新

```text
用户点 ♥
  ↓
UI 立刻显示目标状态
  ↓
写入 favorite_mutation_outbox
  ↓
调用对应 Provider.setFavorite
  ├─ 成功：标记 completed，局部刷新快照
  └─ 失败：回滚 UI，按错误类型提示
```

错误分类：

- 网络暂时失败：可退避重试。
- 登录过期：停止重试并要求重新登录。
- 权限或账户限制：停止重试并展示能力说明。
- 平台明确拒绝：回滚。

## 8. 本地自定义歌单

本地歌单与远端喜欢独立。

```text
local_playlists
└─ local_playlist_items
   └─ provider + trackId + extraIds + sortKey
```

操作语义：

- `♥ 喜欢`：远端写回。
- `＋ 加入本地歌单`：仅写 SQLite。
- 移除本地歌单：不影响远端喜欢和平台歌单。

排序采用可插入的 `sortKey`，避免频繁重写整个歌单。

## 9. 播放器

### 数据流

```text
歌曲被点击
  ↓
PlaybackCoordinator 选择 playbackRef
  ↓
对应 Provider 创建短期 PlaybackTicket
  ↓
PlatformPlayer 接收 URL / headers / expiresAt
  ↓
开始播放并上报状态
```

`PlaybackTicket` 是短期内存对象，不写入 SQLite，不跨设备同步，不作为歌曲唯一标识。

### 过期处理

- 当前歌曲立即解析。
- 下一首预解析。
- 距离过期不足两分钟时重新解析。
- 401 / 403 时允许自动重解析一次。
- 重解析失败时将该来源标记为当前不可播，保持队列继续推进。

### Android

生产级播放使用 Kotlin 的 Android Media3：

```text
MediaSessionService
├─ ExoPlayer
├─ MediaSession
├─ Audio focus
├─ Playback notification
├─ Lock-screen controls
└─ Bluetooth headset controls
```

Flutter 通过 Pigeon 或 Platform Channel 调用播放命令和接收播放事件。V1 只需前台 Flutter 解析当前和下一首 URL；V2 才实现服务在后台请求 Flutter/Dart 重新解析过期 URL 的链路。

### Windows

先做音频引擎 PoC，确保网络 URL、本地文件、队列和错误处理可靠；系统媒体键、任务栏元数据、音量浮层控制通过 Windows `SystemMediaTransportControls` 原生插件接入。

## 10. 下载

下载与播放共享“按来源获取临时授权资源”的能力，但不是同一任务。

```text
用户点下载
  ↓
Provider.createDownloadTicket
  ↓
DownloadCoordinator
  ↓
平台下载执行器
  ↓
.part 临时文件 → 校验 → 原子改名 → 本地媒体索引
```

状态机：

```text
queued → resolving → downloading → paused/completed/failed/cancelled
```

恢复下载时必须重新请求 DownloadTicket，不可假设旧 URL 仍有效。下载只处理当前账号和平台允许访问的资源。

## 11. 账号与安全

- 登录优先二维码或平台允许的网页授权流程。
- 会话 Cookie、令牌和秘密仅放系统安全存储。
- SQLite、日志、崩溃上报、WebDAV 均不得含登录凭证。
- 禁止把本地 API 暴露到公网。
- 不部署统一的第三方请求代理。
- 退出账号时清理对应安全存储、短期票据和私有缓存。

见 [security.md](security.md)。

## 12. 适配式 UI

### Windows

```text
左栏：全部喜欢、平台入口、本地歌单、下载、设置
中栏：当前页面的列表、搜索结果、歌单详情
右栏：当前播放、队列、歌词、来源与收藏状态
```

### Android

```text
底部导航：首页 / 全部喜欢 / 搜索 / 本地歌单 / 我的
底部迷你播放器 → 全屏播放页
```

歌曲列表必须显式显示来源和收藏状态，避免用户误以为一个 ♥ 同时代表两个平台。

## 13. 测试策略

### 单元测试

- 标题、歌手、时长标准化。
- 同曲匹配与误合并保护。
- merge/split override。
- 收藏目标决策。
- Outbox 状态机与重试。
- 本地歌单排序。
- PlaybackTicket 到期判断。

### Provider 合约测试

所有 Provider 使用同一套用例：

```text
getProfile
pullFavorites
setFavorite(true)
setFavorite(false)
createPlaybackTicket
loginExpired
unauthorized
rateLimited
```

### 真机集成测试

Android：熄屏、蓝牙、来电/音频焦点、网络切换、后台播放、下载恢复。

Windows：媒体键、最小化、输出设备切换、下载目录无权限、URL 过期。
