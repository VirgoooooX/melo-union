# MeloUnion 酷狗音乐 Provider 接入计划与开发指导

## 1. 项目目标与边界

目标是为 MeloUnion 新增一个完整的 `KugouMusicProvider`，接入以下能力：

```text
酷狗登录
→ 账号资料 / VIP 状态
→ 我喜欢读取
→ 全部喜欢聚合
→ 收藏 / 取消收藏写回
→ 用户歌单与歌单曲目
→ 搜索 / 推荐 / 榜单 / 歌词
→ 应用内播放
→ 下载到本地音乐库
```

Provider 的“全链路”定义是：**所有播放与下载都仅使用酷狗针对当前登录账号、当前歌曲、当前权益返回的临时媒体授权。**

明确不做：

* 绕过会员、版权、地区或试听限制。
* 解密、导出或持久化受保护媒体。
* 云端代理用户 Cookie、Token 或媒体流。
* 缓存可播放 URL 作为长期资源。
* 把用户会话写入 Drift、日志、崩溃报告或导出文件。

酷狗存在可用的完整客户端参考：其公开功能说明覆盖登录持久化、在线播放、收藏当前歌曲及在线歌单增删改；其媒体解析会基于当前会话即时取得播放地址。
但 MeloUnion 应采用独立实现，不直接搬运第三方客户端的协议代码、签名材料或加密逻辑。

---

## 2. 与当前 MeloUnion 架构的对应关系

当前 `MusicProvider` 已经为酷狗准备好了核心入口：

```dart
Future<ProviderAccountProfile?> getProfile();
Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false});
Future<void> setFavorite({
  required ProviderTrackRef track,
  required bool liked,
});
Future<List<SourceTrack>> search(String query);
Future<List<ProviderPlaylist>> getUserPlaylists();
Future<List<SourceTrack>> getPlaylistTracks(String playlistId);
Future<PlaybackTicket> createPlaybackTicket(...);
Future<DownloadTicket> createDownloadTicket(...);
Future<String?> getLyrics(ProviderTrackRef track);
```

因此原则是：

```text
provider_contract：尽量不改
music_domain：尽量不改
music_data：沿用既有快照与下载记录机制
provider_kugou：承载全部酷狗协议、会话、映射与错误处理
app：只增加 Provider 注册、登录入口、Provider 状态展示
```

`ProviderTrackRef.extraIds` 已经可以保存酷狗一首歌跨接口所需的辅助标识。

酷狗 Track Ref 约定如下：

```text
trackId                 = hash
extraIds.albumId        = album_id
extraIds.albumAudioId   = album_audio_id
extraIds.mixSongId      = mixsongid
extraIds.favoriteFileId = 仅“我喜欢”歌单内曲目才有
extraIds.qualityHints   = 可选，本地解析缓存提示
```

其中最重要的是 `favoriteFileId`：

* 收藏读取时必须保存。
* 取消收藏时优先使用。
* 搜索结果通常没有它；用户取消收藏前若缺失，应先刷新“我喜欢”远端条目，不能猜测或伪造。

---

## 3. 新 Provider 包结构

新增独立 package：

```text
packages/provider_kugou/
├─ pubspec.yaml
├─ lib/
│  ├─ provider_kugou.dart
│  └─ src/
│     ├─ kugou_music_provider.dart
│     ├─ kugou_descriptor.dart
│     │
│     ├─ auth/
│     │  ├─ kugou_auth_service.dart
│     │  ├─ kugou_qr_login_service.dart
│     │  ├─ kugou_session.dart
│     │  ├─ kugou_session_manager.dart
│     │  └─ kugou_secure_session_store.dart
│     │
│     ├─ api/
│     │  ├─ kugou_api_client.dart
│     │  ├─ kugou_account_api.dart
│     │  ├─ kugou_library_api.dart
│     │  ├─ kugou_catalog_api.dart
│     │  ├─ kugou_media_api.dart
│     │  └─ kugou_lyrics_api.dart
│     │
│     ├─ mapper/
│     │  ├─ kugou_track_mapper.dart
│     │  ├─ kugou_playlist_mapper.dart
│     │  └─ kugou_profile_mapper.dart
│     │
│     ├─ model/
│     │  ├─ kugou_remote_track.dart
│     │  ├─ kugou_remote_playlist.dart
│     │  ├─ kugou_media_resolution.dart
│     │  └─ kugou_api_failure.dart
│     │
│     └─ support/
│        ├─ kugou_pagination.dart
│        ├─ kugou_request_gate.dart
│        └─ kugou_redacted_logger.dart
└─ test/
   ├─ auth/
   ├─ mapper/
   ├─ provider/
   └─ fixtures/
```

`provider_kugou.dart` 只导出公开对象：

```dart
export 'src/kugou_music_provider.dart';
export 'src/auth/kugou_auth_service.dart';
export 'src/auth/kugou_session.dart';
```

不要把 API Client、远端响应模型、会话存储实现暴露给 `app`。

---

## 4. Provider 的职责划分

### `KugouMusicProvider`

只负责实现 `MusicProvider` 与编排业务流程：

```text
getProfile              → accountApi
pullFavorites           → libraryApi + pagination + trackMapper
setFavorite             → libraryApi + read-after-write
search                  → catalogApi + trackMapper
getUserPlaylists        → libraryApi + playlistMapper
getPlaylistTracks       → libraryApi + trackMapper
createPlaybackTicket    → mediaApi
createDownloadTicket    → mediaApi
getLyrics               → lyricsApi
```

Provider 不应该直接：

* 拼装复杂请求参数。
* 处理二维码图片字节。
* 保存 Token。
* 直接调用 Secure Storage。
* 在业务日志中记录响应原文。

### `KugouSessionManager`

职责：

```text
- 从安全存储恢复会话
- 保持稳定的设备身份字段
- 单飞刷新会话，避免并发请求同时刷新
- 判断会话是否过期
- 认证失败后清除失效状态
- 登出时删除全部敏感数据
```

建议会话结构：

```dart
final class KugouSession {
  const KugouSession({
    required this.userId,
    required this.token,
    required this.deviceId,
    required this.mid,
    required this.deviceFingerprint,
    this.vipToken,
    this.vipType,
    this.refreshMetadata,
    this.updatedAt,
  });

  final String userId;
  final String token;
  final String deviceId;
  final String mid;
  final String deviceFingerprint;
  final String? vipToken;
  final String? vipType;
  final Map<String, String>? refreshMetadata;
  final DateTime? updatedAt;
}
```

规则：

* 会话整体只进入现有原生 Secure Storage 桥接层。
* `userId` 虽不属于高敏感密钥，也随会话整体存储，避免出现不一致状态。
* 设备身份首次生成后稳定保存；不能每次启动随机生成。
* 任何请求日志只允许输出 `account=***`、`token=***`、`url=<redacted>`。

---

## 5. 收藏系统设计

### 5.1 “我喜欢”识别

不能依据歌单名称判断，例如“我喜欢”“喜欢的歌曲”。

正确流程：

```text
登录
→ 拉取用户所有云端歌单
→ 基于服务端返回的类型、归属、特殊集合标识识别收藏容器
→ 保存 favoriteCollectionId
→ 拉取该容器的全部曲目
```

本地只缓存识别结果，不把它视为永久不变；每次强制同步都应验证一次。

### 5.2 `pullFavorites`

实现要求：

```text
1. 确保会话可用。
2. 获取或刷新 favoriteCollectionId。
3. 全量分页拉取，直到服务端明确无下一页。
4. 映射为 SourceTrack。
5. 为每首曲目保留 hash、专辑、音轨与收藏项 fileId。
6. 返回 FavoriteSnapshot。
7. 部分分页失败时保留成功结果，并填写 partialFailureReason。
```

映射建议：

```dart
SourceTrack(
  ref: ProviderTrackRef(
    providerId: ProviderId.kugou,
    trackId: remote.hash,
    extraIds: {
      'albumId': remote.albumId,
      'albumAudioId': remote.albumAudioId,
      'mixSongId': remote.mixSongId,
      if (remote.favoriteFileId != null)
        'favoriteFileId': remote.favoriteFileId!,
    },
  ),
  title: remote.title,
  artists: remote.artists,
  duration: remote.duration,
  album: remote.album,
  artwork: remote.artwork,
  isFavorited: true,
  isPlayable: remote.explicitlyBlocked != true,
  isDownloadable: false,
  likedAt: remote.favoriteTime,
  likedAtSource: remote.favoriteTime == null ? 'unknown' : 'sync_detected',
  likedAtPrecision: remote.favoriteTime == null ? 'unknown' : 'approximate',
)
```

### 5.3 `setFavorite`

收藏写回必须采用“远端成功 + 读后验证”：

```text
用户点击喜欢
→ 确认 target 是酷狗来源歌曲
→ 确保当前 Track Ref 具备写入所需标识
→ 远端添加至“我喜欢”
→ 强制刷新收藏容器
→ 确认目标 hash 已存在
→ 才更新本地聚合快照
```

取消收藏：

```text
用户点击取消喜欢
→ 优先取 favoriteFileId
→ 缺失时刷新收藏容器，重新定位该 hash
→ 发起移除
→ 强制刷新收藏容器
→ 确认目标 hash 已不存在
→ 才更新本地聚合快照
```

禁止仅凭接口 HTTP 成功就修改本地收藏状态。

---

## 6. 播放与下载设计

酷狗媒体能力应完全围绕现有 Ticket 模型。`PlaybackTicket` 和 `DownloadTicket` 本身已经支持临时 URL、请求头、过期时间、曲目引用、音质、文件扩展名和大小。

### 6.1 统一媒体解析器

```dart
abstract interface class KugouMediaResolver {
  Future<KugouMediaResolution> resolve({
    required ProviderTrackRef track,
    required AudioQuality requestedQuality,
    required KugouMediaUse use,
  });
}
```

```text
KugouMediaUse.playback
KugouMediaUse.download
```

解析顺序：

```text
Track Ref
→ 当前会话
→ 曲目权益 / 可用音质检查
→ 请求临时媒体授权
→ 选择明确可用的音质
→ 得到直连媒体 URL
→ 解析有效期、扩展名、大小、所需 Header
→ 生成 Ticket
```

### 6.2 音质策略

MeloUnion 不应静默降级。

```text
用户请求无损
├─ 服务端明确授权无损：返回 lossless Ticket
├─ 仅高品质可用：抛出 QualityUnavailable
└─ 会员 / 版权限制：抛出 EntitlementRequired 或 MediaUnavailable
```

后续可增加“允许自动降级音质”设置；在此之前，保持用户意图明确。

### 6.3 Ticket 生命周期

```text
- Ticket 不写入数据库。
- 播放前若 near-expiry，重新解析。
- 下载开始前重新解析。
- 下载中收到 401 / 403 / URL 失效，允许重新解析一次。
- 重新解析后若 ETag、大小或扩展名变化，停止断点续传并改为重新开始。
- 不用猜测 URL 有效期；服务端未返回时采用保守短 TTL。
```

### 6.4 下载边界

下载器只处理：

```text
授权直连 URL
→ 原始 HTTP Range 下载
→ 临时文件
→ 完整性检查
→ 原子移动至最终文件
→ 写入现有本地音乐库记录
```

不处理：

```text
加密媒体解密
格式绕过
会员资源导出
二次分发
```

---

## 7. App 层接入点

不应假设 Composition Root 的具体文件名；在 `app/` 中找到当前创建 `QqMusicProvider`、`NeteaseMusicProvider` 并注册到 `ProviderRegistry` 的位置，按相同方式加入：

```dart
registry.register(
  KugouMusicProvider(
    authService: kugouAuthService,
    accountApi: kugouAccountApi,
    libraryApi: kugouLibraryApi,
    catalogApi: kugouCatalogApi,
    mediaResolver: kugouMediaResolver,
    lyricsApi: kugouLyricsApi,
  ),
);
```

Provider Descriptor：

```text
id: kugou
name: 酷狗音乐
capabilities:
- authenticate
- readFavorites
- writeFavorites
- readUserPlaylists
- readDailyRecommendations
- readCharts
- search
- resolvePlayback
- resolveDownload
- lyrics
- artwork
```

初期 UI 标签建议：

```text
酷狗音乐 · Beta
```

Provider 管理页状态：

```text
未登录
二维码待扫描
已登录
会话刷新中
会话已失效
需要重新登录
部分能力不可用
```

“全部喜欢”中酷狗歌曲必须继续保留来源信息。用户点击爱心时：

```text
聚合曲目
→ 识别当前操作的来源 Track Ref
→ 调用对应 Provider.setFavorite
→ 远端确认
→ 重新聚合快照
```

不要因为一首歌同时来自 QQ、网易云和酷狗，就默认三端一起写入。

---

## 8. 分阶段开发步骤

### KGP-00：建立设计约束与验证账号

产出：

```text
docs/adr/ADR-00xx-kugou-provider.md
docs/providers/kugou-capability-matrix.md
```

内容：

* 允许的能力与明确禁止项。
* 匿名、免费、会员、版权受限歌曲的预期行为。
* 专用测试账号规范。
* Secret 不进入 Git、CI、Issue、日志的规则。
* Live Integration Test 只在开发者本地执行。

验收：

```text
所有团队成员都知道：
“全链路”不等于绕过权益；
“下载”只等于服务器允许的临时媒体下载。
```

### KGP-01：创建 package 与 Provider 注册

改动：

```text
packages/provider_kugou/pubspec.yaml
packages/provider_kugou/lib/provider_kugou.dart
packages/provider_kugou/lib/src/kugou_music_provider.dart
packages/provider_contract/lib/src/provider_id.dart
app/pubspec.yaml
app/ 中 ProviderRegistry 的 Composition Root
```

实现：

* 新增 `ProviderId.kugou`。
* 新增 Descriptor。
* 空实现先抛 `UnsupportedProviderOperation`。
* 注册后在 Provider 管理页可见，但不开放登录按钮以外的功能。

验收：

```text
flutter analyze
flutter test
Melo bootstrap
Windows / Android 均能识别“Kugou Music · Beta”
```

### KGP-02：认证与安全会话

> **重要·2026-07-06：** 已验证网页 Cookie 无法用于 Android 网关。Kugou 的
> 移动端 API（`gateway.kugou.com`、`cloudlist.service.kugou.com`）只接受
> 来自 QR 扫码登录等移动端认证流程的会话 token，不认浏览器 Cookie 中提取的
> `KuGooPwd`/`KuGooToken`。Web Cookie 导入作为认证方式已被标记为不可用。改动：

```text
auth/kugou_qr_login_service.dart
auth/kugou_session.dart
auth/kugou_session_manager.dart
auth/kugou_secure_session_store.dart
```

实现：

* 二维码创建、轮询、确认、取消、超时。
* Secure Storage 保存会话。
* 冷启动恢复登录状态。
* 单飞 Token 刷新。
* 认证失败后统一抛 `ProviderAuthenticationExpired`。
* 登出清除会话、设备信息、内存缓存。

验收：

```text
扫码后重启应用仍为已登录。
会话失效后不会无限重试。
登出后不再能读取个人歌单。
日志中不存在 Cookie、Token、完整 URL。
```

### KGP-03：账号资料、歌单、收藏夹发现

改动：

```text
api/kugou_account_api.dart
api/kugou_library_api.dart
mapper/kugou_profile_mapper.dart
mapper/kugou_playlist_mapper.dart
```

实现：

* `getProfile()`
* VIP 状态读取，仅用于 UI 展示与音质权限提示。
* `getUserPlaylists()`
* 特殊收藏容器发现与缓存。
* 歌单分页与去重。

验收：

```text
账号昵称、头像、账号 ID 正确。
用户创建歌单与收藏歌单可列出。
“我喜欢”识别不依赖中文标题。
```

### KGP-04：收藏读取并接入 All Liked

改动：

```text
pullFavorites()
mapper/kugou_track_mapper.dart
KugouFavoriteSync tests
```

实现：

* 全量分页读取。
* 映射所有关键 Track Ref 字段。
* 接入既有 UnifiedFavoritesService。
* 支持强制刷新。
* 失败时返回 partialFailureReason，不删除旧快照。

验收：

```text
官方客户端收藏的歌曲会出现在 MeloUnion 全部喜欢。
多页收藏不会漏歌或重复。
歌曲与现有 QQ / 网易云曲目可正常进入聚合匹配。
```

### KGP-05：收藏写回

改动：

```text
setFavorite()
favoriteCollectionResolver
read-after-write verification
```

实现：

* 加入“我喜欢”。
* 从“我喜欢”移除。
* 失败时回滚 UI 乐观状态。
* 每次写入后强制读取远端确认。
* 网络重试只允许幂等安全的操作。

验收：

```text
MeloUnion 收藏一首歌，官方酷狗刷新后可见。
MeloUnion 取消收藏，官方酷狗刷新后消失。
服务端成功但读后验证失败时，UI 显示“同步待确认”，不伪造成功。
```

### KGP-06：搜索、歌单曲目、推荐、榜单、歌词

改动：

```text
api/kugou_catalog_api.dart
api/kugou_lyrics_api.dart
getDailyRecommendations()
getRecommendedPlaylists()
getChartPlaylists()
search()
getPlaylistTracks()
getLyrics()
```

实现：

* 搜索结果和歌单曲目共用 Track Mapper。
* 歌词优先返回当前项目已有播放器可接受的文本格式。
* 搜索结果仅标记“疑似可播放”；实际播放权限以 Ticket 解析为准。
* 推荐、榜单失败不影响收藏同步。

验收：

```text
搜索结果可播放、可收藏、可加入播放队列。
歌词不会因解析失败影响歌曲播放。
推荐与榜单失败时可单独重试。
```

### KGP-07：应用内播放

改动：

```text
api/kugou_media_api.dart
kugou_media_resolution.dart
createPlaybackTicket()
播放器错误映射
```

实现：

* 先检查当前账号对目标音质的权益。
* 临时 URL 映射为 `PlaybackTicket`。
* 使用 `headers` 支持必要请求头。
* 解析失败转换为可读错误：会员要求、版权限制、地区限制、会话失效、短时限流。
* 播放前检查 Ticket 是否临近过期。

验收：

```text
免费可播放歌曲可正常播放。
会员高音质歌曲只对具备权益的账号可播放。
URL 过期后自动重新解析一次。
没有权限时显示原因，不尝试替代音源或绕过。
```

### KGP-08：下载

改动：

```text
createDownloadTicket()
下载任务错误恢复
文件扩展名与元数据处理
```

实现：

* 下载前独立解析 Ticket。
* 写入临时文件后再原子落盘。
* 403/过期时重新解析一次。
* 文件大小与 Range 行为异常时终止任务。
* 成功后交给现有本地音乐库索引。

验收：

```text
可下载歌曲进入现有下载页。
暂停/恢复与过期 Ticket 的行为正确。
无权下载时明确失败，不产生损坏文件。
下载记录不包含会话密钥或永久媒体 URL。
```

### KGP-09：自动化测试、人工验收与发布门禁

单元测试：

```text
- Track Ref 映射
- 收藏夹识别
- 分页终止条件
- 收藏写入幂等判断
- Ticket 过期判断
- 敏感字段脱敏
- 认证失效错误映射
```

Fixture 原则：

```text
- 只保存脱敏 JSON。
- 删除所有 token、cookie、签名、可用媒体 URL。
- 用占位符代替账号和曲目私有信息。
```

人工 Live Test：

```text
- 免费账号
- 具备会员权益账号
- 无版权或地区受限歌曲
- 登录后冷启动
- 会话失效
- 收藏读写双向验证
- 播放 URL 失效
- 下载中 Ticket 失效
```

CI 规则：

```text
- CI 只运行 mock / fixture 测试。
- CI 不登录真实酷狗账号。
- CI 不调用真实媒体接口。
- Live Test 通过本地环境变量显式启用。
```

---

## 9. 关键风险与处理策略

| 风险        | 策略                               |
| --------- | -------------------------------- |
| 非公开协议变化   | 所有协议封装在 `provider_kugou`，不污染领域层。 |
| 二维码登录异常   | 明确超时、取消、重新扫码状态；不无限轮询。            |
| Token 失效  | 单飞刷新；失败后降级为“需要重新登录”。             |
| 收藏夹识别变化   | 每次强制同步重新验证服务端特殊集合标识。             |
| 曲目字段不足    | Track Ref 保留 hash、专辑、音轨、歌单条目 ID。 |
| URL 很快过期  | 永不落库；播放和下载时即时解析。                 |
| 会员/版权限制   | 显式失败，不降级绕过。                      |
| 下载断点续传失效  | URL 刷新后先校验资源一致性，不一致则重新下载。        |
| 第三方参考代码风险 | 行为参考、Clean Room 重写、保留必要许可证声明。    |

---

## 10. 最终验收标准

酷狗 Provider 只有同时满足以下条件，才能从 Beta 升级为正式可用：

```text
[ ] 二维码登录稳定，重启后能恢复会话
[ ] 账号资料和用户歌单正确
[ ] “我喜欢”能完整读取、分页不漏
[ ] 收藏 / 取消收藏可写回并经远端验证
[ ] 全部喜欢聚合后不破坏 QQ / 网易云现有逻辑
[ ] 免费可播放资源可拿到有效 PlaybackTicket
[ ] 授权可下载资源可拿到有效 DownloadTicket
[ ] 会员、版权、地区限制都能正确失败
[ ] 会话、URL、下载错误都有可恢复路径
[ ] 没有 Secret、永久媒体 URL、隐私数据进入日志或仓库
[ ] 单元测试与脱敏 Fixture 覆盖主流程
```

## 11. 推荐执行顺序

```text
KGP-00
→ KGP-01
→ KGP-02
→ KGP-03
→ KGP-04
→ KGP-05
→ KGP-07
→ KGP-08
→ KGP-06
→ KGP-09
```

其中真正的决策门槛是：

```text
KGP-05 收藏读写双向验证通过
+
KGP-07 播放 Ticket 在真实登录态下稳定工作
```

这两个门槛通过后，酷狗才算是 MeloUnion 的全链路 Provider；此前均保持 Beta 标识。
