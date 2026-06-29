# Provider 可扩展性设计

本文件定义 MeloUnion 如何从 QQ 音乐、网易云音乐扩展到更多音乐来源，而不让平台特判扩散到 UI、虚拟歌单、播放器和本地歌单核心。

## 1. 目标

新增一个 Provider 时，预期只新增或修改：

```text
packages/provider_<platform>/
packages/provider_contract/ 的通用能力或模型（仅当确有跨平台共性）
tooling/fixtures/<platform>/
spikes/provider_<platform>_spike/
App bootstrap 的 Provider 注册项
```

不应修改：

```text
UnifiedFavoritesService 的平台分支
LocalPlaylistService 的平台分支
PlaybackCoordinator 的平台分支
页面中针对 QQ / 网易云的 if/switch
SQLite 表结构中固定的 QQ / 网易云字段
```

## 2. Provider 生命周期

```text
设计能力矩阵
  ↓
Provider Spike
  ↓
实现适配包
  ↓
Contract tests + fixtures
  ↓
Experimental 注册
  ↓
真实账号与真机验证
  ↓
Stable 默认启用
  ↓
协议失效时降级 / 暂停 / 弃用
```

### 状态

| 状态 | 含义 | UI 行为 |
|---|---|---|
| `available` | 已验证并稳定支持 | 可在设置中启用 |
| `experimental` | 可用但协议稳定性不足 | 默认关闭或明确标注实验性 |
| `temporarilyUnavailable` | 上游变动、维护中 | 保留历史数据，禁用实时操作 |
| `deprecated` | 不再维护 | 引导用户移除/迁移；本地历史条目保留 |
| `disabled` | 用户手动关闭 | 不参与刷新和全部喜欢 |

## 3. 能力矩阵，而非平台名单

MeloUnion 不维护“支持哪些平台就展示哪些固定按钮”的逻辑。每个 Provider 声明能力：

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
```

### UI 路由规则

```text
canReadFavorites
→ 在“全部喜欢”刷新任务中参与

canWriteFavorites
→ 显示可交互的 ♥；否则禁用并解释

canReadUserPlaylists
→ 显示“我的歌单”入口

canReadDailyRecommendations
→ 显示“每日推荐”入口

canSearch
→ 纳入统一搜索来源筛选

canResolvePlayback
→ 可成为当前播放来源

canResolveDownload
→ 显示下载入口
```

所有判断都通过 `ProviderDescriptor.capabilities` 完成。

## 4. Provider 目录模板

```text
packages/provider_<platform>/
├─ lib/
│  ├─ provider_<platform>.dart         # MusicProvider 实现与装配
│  ├─ descriptor.dart                  # ID、展示信息、能力声明
│  ├─ auth/
│  │  ├─ auth_repository.dart
│  │  └─ session_store.dart
│  ├─ api/
│  │  ├─ client.dart
│  │  ├─ request_models.dart
│  │  └─ response_models.dart
│  ├─ mapper/
│  │  └─ track_mapper.dart
│  ├─ features/
│  │  ├─ favorites.dart
│  │  ├─ playlists.dart
│  │  ├─ search.dart
│  │  ├─ playback.dart
│  │  ├─ download.dart
│  │  └─ lyrics.dart
│  └─ errors.dart
├─ test/
│  ├─ contract/
│  ├─ mapper/
│  └─ fixtures/
└─ README.md
```

## 5. ID 与数据兼容性

### Provider ID

- 使用稳定字符串，例如 `netease`、`qq_music`、`kugou`。
- 一经发布不可改名。
- 不使用展示名作 ID；展示名可本地化、可改变，ID 不可以。

### Track ID

`ProviderTrackRef` 至少包含：

```dart
class ProviderTrackRef {
  final ProviderId provider;
  final String trackId;
  final Map<String, String> extraIds;
}
```

- `trackId` 是该 Provider 的主歌曲 ID。
- `extraIds` 保存必要的平台专有 ID，例如 songMid、albumMid、音质/版权标识。
- 不把平台专有字段提到统一 Domain 实体中，除非至少两个 Provider 都需要相同语义。

### Provider 被禁用或移除

本地歌单不得丢失条目。应显示缓存的歌名/歌手/封面和“来源当前不可用”，并允许用户：

- 保留条目；
- 删除条目；
- 手动替换为另一来源版本；
- 重新启用 Provider 后恢复。

## 6. 「全部喜欢」的扩展规则

```text
全部喜欢 =
  所有 enabled + authenticated + readFavorites Provider 的喜欢歌曲并集
  - hidden rules
  + merge/split overrides
```

新增 Provider 后无需改合并主流程；只需让它正确返回 `FavoriteSnapshot` 与标准化 `SourceTrack`。

同曲合并保持保守：ISRC、明确同曲关系、标题/主歌手/时长匹配、用户手动规则依次使用。宁可显示重复，不可错误合并 Remix、Live、翻唱或不同版本。

## 7. 收藏与播放的来源一致性

每个歌曲上下文保留三套引用：

```text
originRef          从哪个 Provider 条目进入页面
playbackRef        当前从哪个 Provider 获取播放资源
favoriteTargetRef  点 ♥ 要写回哪个 Provider
```

默认 `favoriteTargetRef = originRef`。播放换源不影响收藏目标。

对于聚合歌曲：

- 单来源：直接切换该来源收藏。
- 多来源：展示每个 Provider 独立开关。
- 只读来源：只显示状态，禁止写回。

## 8. Contract Test 要求

每个 Provider 必须运行同一套能力感知测试：

```text
getProfile
capabilities
pullFavorites                  # capability: readFavorites
setFavorite(true/false)        # capability: writeFavorites
getDailyRecommendations        # capability: readDailyRecommendations
search                          # capability: search
createPlaybackTicket           # capability: resolvePlayback
createDownloadTicket           # capability: resolveDownload
loginExpired
unauthorized
rateLimited
protocolChanged
```

测试夹具必须脱敏，不可包含真实 Cookie、token、播放 URL、下载 URL、私人歌单或账号 ID。

## 9. 新 Provider 接入清单

```text
[ ] 选择 Provider ID、展示名、图标与状态
[ ] 完成能力矩阵，不虚报能力
[ ] 实现认证和会话清理
[ ] 实现统一模型 mapper
[ ] 实现每个已声明能力
[ ] 映射结构化错误
[ ] 通过 contract tests
[ ] 创建脱敏 fixtures
[ ] 进行官方客户端/真实账户验证（若涉及写回）
[ ] 验证登录失效、限流、网络失败、协议变化
[ ] 在 Registry 以 experimental 或 available 注册
[ ] 验证 UI 不需要平台名称特判
[ ] 安全检查：凭证不进入日志、SQLite、同步或崩溃上报
```

## 10. 为什么不做远程热插拔 Provider

远程下载 Provider 代码看似方便，但这个项目涉及账号会话与请求签名，风险远高于收益：

- 下载的代码可能读取或外传凭证。
- 第三方协议适配可被恶意替换。
- Android、Windows 的签名、审核、崩溃定位和版本兼容更复杂。
- 用户无法判断插件来源是否可信。

因此 V1–V2 只允许**内置、随版本编译并发布的 Provider**。未来即便支持外部扩展，也必须重新设计沙箱、签名、权限和审计体系，不能简单加载脚本。
