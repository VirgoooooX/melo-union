# Provider Contract Spike

这个目录实现了 MeloUnion Phase 0 的独立 Provider Registry / capability spike。它是一个纯 Dart package，不包含 Flutter UI，也不接入真实平台协议。

## 运行方式

在本目录执行：

```bash
dart pub get
dart test
```

如果本机 `dart` 不在 PATH，可以直接调用 Dart SDK 的绝对路径执行同样命令。

## 已覆盖的 Phase 0 清单

- `ProviderId` 使用稳定字符串键，并校验为小写 ASCII 下划线格式。
- `ProviderDescriptor`、`ProviderCapability`、`ProviderStatus`、`MusicProvider` 最小契约与 `StaticProviderRegistry` 已实现。
- `ProviderTrackRef` 保留 `providerId + trackId + extraIds`，用于承载平台专有但不泄漏到领域层的 ID。
- 提供了 A 类完整账号型、B 类只读账号型、C 类目录/补充型 fake fixtures，支持启用/禁用和已登录/未登录模拟。
- “全部喜欢” eligibility 仅基于 `enabled + authenticated + readFavorites`。
- `writeFavorites` 缺失时返回禁用原因。
- 搜索、播放和本地歌单来源解析全部基于 provider capability / track reference，不依赖 QQ 或网易云硬编码。
- 禁用 provider 后，历史本地歌单仍能显示缓存元数据，并提示来源当前不可用。

## 未实现内容

- 未接入任何真实 Provider，也不伪造 Cookie、token、账号 ID、播放 URL 或下载 URL。
- 未实现真实登录、真实收藏写回、每日推荐、下载票据或网络请求。
- 未实现官方客户端验证闭环；这部分应由后续 `provider_netease_spike`、`provider_qq_spike` 等真实 spike 完成。
