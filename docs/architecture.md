# MeloUnion 架构与技术设计

## 1. 产品定义

MeloUnion 是一个 Windows + Android 双端、**可扩展多 Provider** 的统一音乐客户端。

首发完整账号体验以网易云音乐与 QQ 音乐为目标，但核心架构不得把它们写死为唯二来源。每个音乐平台都是一个随 App 版本编译并注册的 Provider；Provider 可以具备不同能力：完整账号读写、只读账号、公开目录或元数据补充。

```text
网易云「我喜欢的音乐」 ─┐
QQ 音乐「我喜欢」      ├─→ 虚拟歌单「全部喜欢」
未来其他可读收藏 Provider ─┘
```

「全部喜欢」不是第三份云端歌单，而是本地计算出的联合视图。它只包含**已启用、已登录且声明 `canReadFavorites`** 的 Provider 的喜欢歌曲。

每一首歌始终保留原始平台身份；用户在 App 内点 ♥ 时，只能写回该歌曲的来源平台，且只有该 Provider 声明 `canWriteFavorites` 时才允许操作。

另有一套独立的本地自定义歌单，可混放任意 Provider 的歌曲引用。

## 2. 目标与边界

### 必做

- Provider Registry 与能力矩阵。
- 首发接入网易云音乐、QQ 音乐账号体验。
- 读取已启用 Provider 的「我喜欢」。
- 虚拟「全部喜欢」：统一查看、搜索、排序、随机播放。
- 按来源平台收藏 / 取消收藏。
- 本地自定义歌单：创建、重命名、排序、混合来源歌曲。
- Windows 与 Android 的播放队列、循环、随机、后台播放与媒体控制。
- 单曲下载、下载队列、恢复与本地优先播放。
- 登录过期、网络异常、能力缺失的可解释降级。

### 首版非目标

- 评论、社交、MV、播客、电台、直播。
- 自动跨平台换源。
- 跨设备同步本地歌单。
- 歌词逐字高亮与音效。
- 服务端托管账号 Cookie、播放票据或下载票据。
- 从网络动态下载、执行或热加载第三方 Provider 插件。

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
┌───────────────▼───────────┐ ┌──▼──────────────┐
│ Provider Registry          │ │ Local Data      │
│ MusicProvider adapters     │ │ Drift / SQLite  │
│ capability-aware routing   │ │ Secure Storage  │
└───────────────┬───────────┘ │ Cache / Outbox  │
                │             └─────────────────┘
┌───────────────▼──────────────────────────────┐
│ Platform Bridges                              │
│ Android: Kotlin Media3 + MediaSessionService  │
│ Windows: audio engine + SMTC native plugin    │
└──────────────────────────────────────────────┘
```

### 层间规则

1. Flutter 页面不得直接请求任一音乐平台接口。
2. 页面不得直接读写 SQLite。
3. 平台协议、Cookie、请求签名只能存在于对应 Provider 包中。
4. UI 不得用 `switch(provider == qq/netease)` 判断业务能力；必须读取 `ProviderCapabilities`。
5. 播放器只接受标准化 `PlaybackTicket`，不理解平台协议。
6. 本地歌单只保存 `ProviderTrackRef`，不复制远端歌曲或歌单数据。
7. 新增 Provider 不允许修改 `music_domain` 的平台特判逻辑；最多新增适配包、注册项、测试夹具与展示配置。

## 4. Provider 可扩展架构

### 4.1 Provider ID：不使用硬编码枚举

Provider ID 必须是稳定字符串键，而不是只包含 QQ / 网易云的 Dart `enum`：

```dart
@immutable
class ProviderId {
  final String value;
  const ProviderId(this.value);

  @override
  bool operator ==(Object other) =>
      other is ProviderId && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

const neteaseProviderId = ProviderId('netease');
const qqMusicProviderId = ProviderId('qq_music');
// 后续：ProviderId('kugou')、ProviderId('kuwo')、ProviderId('local') …
```

约束：

- `value` 使用小写 ASCII、下划线分隔。
- 一经发布不得改名；数据库、同步日志、本地歌单都依赖它。
- Provider 展示名、图标、登录方式不放入 ID，而放入 descriptor。

### 4.2 Provider Descriptor 与能力矩阵

```dart
enum ProviderCapability {
  authenticate,
  readFavorites,
  writeFavorites,
  readUserPlaylists,
  readDailyRecommendations,
  search,
  resolvePlayback,
  resolveDownload,
  lyrics,
  artwork,
}

class ProviderDescriptor {
  final ProviderId id;
  final String displayName;
  final String iconAsset;
  final Set<ProviderCapability> capabilities;
  final bool isExperimental;
}
```

能力必须拆分，不能把“已接入”误解成“所有功能都支持”。

| Provider 类别 | 常见能力 | 在「全部喜欢」中的行为 |
|---|---|---|
| 完整账号型 | 登录、读/写喜欢、我的歌单、搜索、播放、下载 | `canReadFavorites` 时纳入；可写回则显示 ♥ |
| 只读账号型 | 登录、读取喜欢/歌单、搜索、播放 | `canReadFavorites` 时纳入；♥ 禁用并解释原因 |
| 目录/补充型 | 搜索、歌词、封面、公共歌单、元数据 | 不纳入；可作为详情或搜索补充 |
| 本地媒体 Provider | 扫描、播放本地文件 | 不纳入远端喜欢；可加入本地歌单 |

### 4.3 Provider Registry

```dart
abstract interface class ProviderRegistry {
  Iterable<MusicProvider> get registered;
  Iterable<MusicProvider> get enabled;

  MusicProvider? find(ProviderId id);
  ProviderDescriptor? describe(ProviderId id);
}

class StaticProviderRegistry implements ProviderRegistry {
  StaticProviderRegistry(this._providers);

  final Map<ProviderId, MusicProvider> _providers;

  @override
  Iterable<MusicProvider> get registered => _providers.values;

  @override
  Iterable<MusicProvider> get enabled =>
      _providers.values.where((provider) => provider.isEnabled);

  @override
  MusicProvider? find(ProviderId id) => _providers[id];

  @override
  ProviderDescriptor? describe(ProviderId id) => _providers[id]?.descriptor;
}
```

Registry 是依赖注入容器，不是在线插件市场。新增 Provider 的正确路径是：

```text
新增 provider_<platform> Dart package
→ 实现 MusicProvider
→ 补齐 capability / contract tests / fixtures
→ 在 bootstrap 中注册
→ 随 App 版本编译、测试和发布
```

首版不从网络下载可执行 Dart、动态库或 Provider 脚本，避免供应链风险、凭证泄露和不可控协议代码。

### 4.4 通用 MusicProvider 契约

```dart
abstract interface class MusicProvider {
  ProviderId get id;
  ProviderDescriptor get descriptor;
  bool get isEnabled;

  Future<AccountProfile?> getProfile();
  Future<FavoriteSnapshot> pullFavorites({
    String? cursor,
    bool forceRefresh = false,
  });
  Future<List<SourceTrack>> getDailyRecommendations();
  Future<SearchPage> search({
    required String keyword,
    String? cursor,
  });

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

对于不支持的能力，Provider 应抛出结构化 `CapabilityUnavailableException`，而不是返回空列表伪装成功。

### 4.5 新增平台的 Definition of Done

一个 Provider 只有完成以下内容，才能在稳定版启用：

- `ProviderId`、descriptor、能力矩阵。
- 登录态保存与彻底清理。
- contract test 与脱敏 fixtures。
- 速率限制、登录失效、权限/会员限制、协议变化的错误映射。
- 对已声明能力的真机/官方客户端验证。
- UI 降级：不可写收藏、不可下载、不可读喜欢时都有明确展示。
- 安全评审：无 Cookie 进日志、SQLite、同步或崩溃上报。

详细工作流见 [provider-extensibility.md](provider-extensibility.md)。

## 5. 模块职责

### `provider_contract`

定义 Provider ID、descriptor、capability、统一模型、错误类型、Registry 与 contract tests。

### `provider_<platform>`

一个平台一个 package，内部按认证、收藏、歌单、搜索、播放、下载、歌词拆分；不得泄漏平台专有字段到 UI。平台专有 ID 放入 `ProviderTrackRef.extraIds`。

### `music_domain`

不依赖 Flutter、Dio、SQLite 或平台协议的核心逻辑：

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

## 6. 关键模型

### 原始来源歌曲

```dart
class ProviderTrackRef {
  final ProviderId provider;
  final String trackId;
  final Map<String, String> extraIds;
}

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
originRef          歌曲从哪个 Provider 条目进入当前上下文
playbackRef        当前实际使用哪个 Provider 播放
favoriteTargetRef  点击 ♥ 时应该写回哪个 Provider
```

播放换源不能改变收藏目标。

## 7. 虚拟「全部喜欢」

### 参与 Provider 的条件

```text
eligibleFavoriteProviders =
  ProviderRegistry.enabled
  ∩ 已登录账号
  ∩ capability(readFavorites)
```

因此首发的 QQ 与网易云都会参与；以后任何通过验证的新 Provider 也可自动参与，无需改 `UnifiedFavoritesService`。

### 刷新流程

```text
进入页面 / 用户下拉刷新
  ↓
查找 eligibleFavoriteProviders
  ↓
并行拉取每个平台的 favorites 快照
  ↓
写入 remote_favorite_snapshots
  ↓
标准化元数据
  ↓
自动匹配 + 手动合并/拆分规则
  ↓
生成 UnifiedTrack 列表
```

单一 Provider 失败不得阻塞其他 Provider 的结果；页面应显示“部分来源未刷新”的来源级状态。

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

## 8. 收藏写回与 Outbox

### 规则

- 所有 Provider 的规则一致：`favoriteTargetRef` 指向哪个来源，就只调用该 Provider。
- 只有具备 `writeFavorites` 的 Provider 才显示可交互 ♥。
- 「全部喜欢」中单来源歌曲：直接操作该来源。
- 多来源聚合歌曲：显示每个来源独立开关；不加提示地一次取消多个来源是禁止行为。
- 只读 Provider 的已有喜欢可展示，但取消/新增按钮必须禁用并解释原因。

### 乐观更新

```text
用户点 ♥
  ↓
UI 立刻显示目标状态
  ↓
写入 favorite_mutation_outbox
  ↓
按 ProviderId 路由到 ProviderRegistry.find(...).setFavorite
  ├─ 成功：标记 completed，局部刷新该来源快照
  └─ 失败：回滚 UI，按错误类型提示
```

错误分类：网络暂时失败、登录过期、权限/账户限制、能力缺失、平台明确拒绝、协议变化。不得把所有失败包装成同一个“请求失败”。

## 9. 本地自定义歌单

本地歌单与远端喜欢独立。

```text
local_playlists
└─ local_playlist_items
   └─ providerId + trackId + extraIds + sortKey
```

操作语义：

- `♥ 喜欢`：若 Provider 支持，远端写回。
- `＋ 加入本地歌单`：仅写 SQLite。
- 移除本地歌单：不影响远端喜欢和平台歌单。

排序采用可插入的 `sortKey`，避免频繁重写整个歌单。

## 10. 播放器

### 数据流

```text
歌曲被点击
  ↓
PlaybackCoordinator 选择 playbackRef
  ↓
ProviderRegistry.find(playbackRef.provider)
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

## 11. 下载

下载与播放共享“按来源获取临时授权资源”的能力，但不是同一任务。

```text
用户点下载
  ↓
ProviderRegistry.find(track.provider).createDownloadTicket
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

恢复下载时必须重新请求 DownloadTicket，不可假设旧 URL 仍有效。Provider 无下载能力或用户无对应权限时，下载按钮应明确禁用或显示原因。

## 12. 账号与安全

- 登录优先二维码或平台允许的网页授权流程。
- 会话 Cookie、令牌和秘密仅放系统安全存储，并按 `ProviderId + accountId` 隔离。
- SQLite、日志、崩溃上报、WebDAV 均不得含登录凭证。
- 禁止把本地 API 暴露到公网。
- 不部署统一的第三方请求代理。
- 退出账号时清理对应 Provider 的安全存储、短期票据和私有缓存。
- 不从网络加载未知 Provider 代码或配置脚本。

见 [security.md](security.md)。

## 13. 适配式 UI

### Windows

```text
左栏：全部喜欢、已启用 Provider、本地歌单、下载、设置
中栏：当前页面的列表、搜索结果、歌单详情
右栏：当前播放、队列、歌词、来源与收藏状态
```

### Android

```text
底部导航：首页 / 全部喜欢 / 搜索 / 本地歌单 / 我的
底部迷你播放器 → 全屏播放页
```

歌曲列表必须显式显示来源和收藏状态。Provider 无写收藏能力时，界面必须显示禁用原因，不得隐藏真实能力差异。

## 14. 测试策略

### 单元测试

- 标题、歌手、时长标准化。
- 同曲匹配与误合并保护。
- merge/split override。
- 收藏目标决策。
- Outbox 状态机与重试。
- 本地歌单排序。
- PlaybackTicket 到期判断。
- Provider Registry 与 capability-aware UI 路由。

### Provider 合约测试

所有 Provider 使用同一套能力感知的用例：

```text
getProfile
capabilities
pullFavorites                  # 仅 readFavorites = true 时必测
setFavorite(true/false)        # 仅 writeFavorites = true 时必测
createPlaybackTicket           # 仅 resolvePlayback = true 时必测
createDownloadTicket           # 仅 resolveDownload = true 时必测
loginExpired
unauthorized
rateLimited
```

### 真机集成测试

Android：熄屏、蓝牙、来电/音频焦点、网络切换、后台播放、下载恢复。

Windows：媒体键、最小化、输出设备切换、下载目录无权限、URL 过期。
