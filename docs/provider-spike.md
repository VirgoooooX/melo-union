# Provider Spike 验证清单

Provider Spike 不是正式功能开发，而是为了在投入 UI、数据库和跨端播放器前确认关键能力是否可行、稳定且可维护。

## 原则

- 使用单独的测试账号或明确的测试歌单。
- 不把任何 Cookie、二维码登录结果、授权头或真实账号信息提交进 Git。
- 不把非公开协议当作对用户的长期保证。
- 不进行高频轮询、批量滥用请求或绕过平台收费/DRM/地区限制。
- 若某项能力无法通过平台允许且可维护的方式实现，记录能力缺失并设计 UI 降级。

## 项目结构

```text
spikes/
├─ provider_netease_spike/
│  ├─ README.md
│  ├─ lib/
│  └─ test/
├─ provider_qq_spike/
│  ├─ README.md
│  ├─ lib/
│  └─ test/
├─ android_player_spike/
└─ windows_player_spike/
```

## Provider 测试矩阵

| 能力 | 网易云 | QQ | 记录内容 |
|---|---:|---:|---|
| 登录 |  |  | 登录方式、过期行为 |
| 账号信息 |  |  | 稳定 ID、昵称、头像 |
| 我喜欢读取 |  |  | 分页、排序、更新时间 |
| 收藏写入 |  |  | 成功/失败语义 |
| 取消收藏 |  |  | 官方端验证结果 |
| 每日推荐 |  |  | 是否依赖会员/地区 |
| 搜索 |  |  | 曲目唯一标识、songMid 等额外 ID |
| 播放票据 |  |  | 有效期、headers、错误码 |
| 下载票据 |  |  | 是否可用、Range 支持 |
| 歌词/封面 |  |  | 编码、缓存策略 |

## 最小测试伪代码

```dart
Future<void> providerContractSmokeTest(MusicProvider provider) async {
  final profile = await provider.getProfile();
  assert(profile.accountId.isNotEmpty);

  final favorites = await provider.pullFavorites(forceRefresh: true);
  assert(favorites.tracks.isNotEmpty || favorites.tracks.isEmpty);

  final candidate = await selectSafeTestTrack(provider, favorites);
  final initial = candidate.isFavorited;

  await provider.setFavorite(track: candidate.ref, liked: !initial);
  await verifyInOfficialClientOrFreshProviderRead(candidate.ref, !initial);

  await provider.setFavorite(track: candidate.ref, liked: initial);
  await verifyInOfficialClientOrFreshProviderRead(candidate.ref, initial);

  final ticket = await provider.createPlaybackTicket(
    track: candidate.ref,
    quality: AudioQuality.standard,
  );
  assert(ticket.mediaUrl.hasScheme);
}
```

## 必须记录的失败模式

```text
AuthExpiredException
RateLimitedException
CapabilityUnavailableException
GeoRestrictedException
SubscriptionRequiredException
PlaybackTicketExpiredException
ProviderProtocolChangedException
NetworkException
```

不要把所有失败包装成同一个“请求失败”。UI 是否可理解，依赖于错误分类是否精确。

## Go / No-Go 判定

以下任何一项失败时，不进入 Phase 2：

1. 无法稳定读到两边的「我喜欢」。
2. 无法让 App 内 ♥ 的结果可靠反映到官方客户端。
3. 播放资源无法在当前账号允许范围内稳定获取。
4. 登录态无法安全保存和清理。
5. Android 后台播放无法通过 MediaSessionService 基础验证。
