# Provider Spike 验证清单

Provider Spike 不是正式功能开发，而是为了在投入 UI、数据库和跨端播放器前确认每个 Provider 的能力是否可行、稳定且可维护。

首发 Spike 针对网易云与 QQ；同一份流程必须可复用于后续任何平台。Provider 的目标不是“接得越多越好”，而是准确声明能力、稳定降级、不会污染核心架构。

## 原则

- 使用单独的测试账号或明确的测试歌单。
- 不把任何 Cookie、二维码登录结果、授权头或真实账号信息提交进 Git。
- 不把非公开协议当作对用户的长期保证。
- 不进行高频轮询、批量滥用请求或绕过平台收费/DRM/地区限制。
- 若某项能力无法通过平台允许且可维护的方式实现，记录能力缺失并设计 UI 降级。
- 不把 QQ、网易云的字段、分支或错误码泄露到 Provider Contract、Domain 或 UI。
- 不从网络下载可执行 Provider 插件；每个 Provider 随 App 版本编译、测试和发布。

## Provider 分类与接入承诺

| 类别 | 最低能力 | 「全部喜欢」 | ♥ 操作 | 示例用途 |
|---|---|---|---|---|
| A：完整账号型 | 登录 + `readFavorites` + `writeFavorites` | 纳入 | 可写回 | 首发 QQ、网易云目标 |
| B：只读账号型 | 登录 + `readFavorites` | 纳入 | 禁用并解释 | 只读音乐库 |
| C：目录/补充型 | 搜索、歌词、封面等任意能力 | 不纳入 | 不适用 | 元数据/目录补充 |
| D：本地媒体型 | 扫描、播放本地文件 | 不纳入远端喜欢 | 不适用 | 本地媒体库 |

每个 Provider 必须在 `ProviderDescriptor` 中声明实际能力；不得因 UI 统一而虚假标记“支持收藏”或“支持下载”。

## 项目结构

```text
spikes/
├─ provider_contract_spike/
│  ├─ registry_test.dart
│  └─ capability_ui_matrix_test.dart
├─ provider_netease_spike/
│  ├─ README.md
│  ├─ lib/
│  └─ test/
├─ provider_qq_spike/
│  ├─ README.md
│  ├─ lib/
│  └─ test/
├─ provider_<future_platform>_spike/
│  ├─ README.md
│  ├─ lib/
│  └─ test/
├─ android_player_spike/
└─ windows_player_spike/
```

## Registry Spike

在任何真实平台接入前，先验证：

- [ ] `ProviderId` 是稳定字符串键，不是仅含首发平台的 enum。
- [ ] 可注册、查找、启用、禁用多个 Provider。
- [ ] UI 仅根据 capabilities 决定入口与按钮状态。
- [ ] 一个 Fake A 类、B 类、C 类 Provider 同时存在时，全部喜欢、搜索、本地歌单与播放队列逻辑正确。
- [ ] 禁用/卸载一个 Provider 后，历史本地歌单条目不丢失，并能显示“来源当前不可用”。

## Provider 测试矩阵

使用一张文档或 JSON 测试报告记录每个 Provider，不再固定为“网易云 / QQ 两列”。

| 能力 | 是否声明 | 是否通过 | 记录内容 |
|---|---:|---:|---|
| 登录 |  |  | 登录方式、失效行为、清理流程 |
| 账号信息 |  |  | 稳定 ID、昵称、头像 |
| 我喜欢读取 |  |  | 分页、排序、更新时间、增量策略 |
| 收藏写入 |  |  | 成功/失败语义、官方端验证 |
| 取消收藏 |  |  | 官方端验证、可恢复性 |
| 用户歌单读取 |  |  | 自建/收藏/私有歌单边界 |
| 每日推荐 |  |  | 是否依赖会员/地区 |
| 搜索 |  |  | 曲目唯一标识、额外 ID |
| 播放票据 |  |  | 有效期、headers、错误码 |
| 下载票据 |  |  | 是否可用、Range 支持 |
| 歌词/封面 |  |  | 编码、缓存策略 |
| 速率限制 |  |  | 触发条件、退避建议 |
| 协议变动 |  |  | 检测、错误映射、禁用策略 |

## 最小测试伪代码

```dart
Future<void> providerContractSmokeTest(MusicProvider provider) async {
  final capabilities = provider.descriptor.capabilities;

  if (capabilities.contains(ProviderCapability.authenticate)) {
    final profile = await provider.getProfile();
    assert(profile != null && profile.accountId.isNotEmpty);
  }

  if (capabilities.contains(ProviderCapability.readFavorites)) {
    final favorites = await provider.pullFavorites(forceRefresh: true);
    assert(favorites.tracks.isNotEmpty || favorites.tracks.isEmpty);

    if (capabilities.contains(ProviderCapability.writeFavorites)) {
      final candidate = await selectSafeTestTrack(provider, favorites);
      final initial = candidate.isFavorited;

      await provider.setFavorite(track: candidate.ref, liked: !initial);
      await verifyInOfficialClientOrFreshProviderRead(candidate.ref, !initial);

      await provider.setFavorite(track: candidate.ref, liked: initial);
      await verifyInOfficialClientOrFreshProviderRead(candidate.ref, initial);
    }
  }

  if (capabilities.contains(ProviderCapability.resolvePlayback)) {
    final track = await selectPlayableTestTrack(provider);
    final ticket = await provider.createPlaybackTicket(
      track: track.ref,
      quality: AudioQuality.standard,
    );
    assert(ticket.mediaUrl.hasScheme);
  }
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
ProviderDisabledException
NetworkException
```

不要把所有失败包装成同一个“请求失败”。UI 是否可理解，依赖于错误分类是否精确。

## Go / No-Go 判定

### 首发版本

以下任何一项失败时，不进入 QQ/网易云正式功能开发：

1. 无法稳定读到目标平台的「我喜欢」。
2. 无法让 App 内 ♥ 的结果可靠反映到官方客户端。
3. 播放资源无法在当前账号允许范围内稳定获取。
4. 登录态无法安全保存和清理。
5. Android 后台播放无法通过 MediaSessionService 基础验证。
6. Registry 或 UI 仍存在“只有 QQ / 网易云”的硬编码分支。

### 新增后续 Provider

新增 Provider 不应阻塞已有 Provider。只要它未通过自身声明能力的验证，就必须保持 disabled/experimental，不得进入稳定默认配置。
