# 开发路线图与验收门槛

> 原则：先验证最难、最不确定的部分；不要先做皮肤、歌词和下载页。Provider 体系必须从第一天按“可扩展、能力驱动”实现，而不是先把 QQ / 网易云写死再返工。

## Provider 分级

| 级别 | 定义 | 典型能力 | 是否进入「全部喜欢」 |
|---|---|---|---|
| A：完整账号型 | 可读写用户音乐库 | 登录、读/写喜欢、歌单、搜索、播放、下载 | `readFavorites = true` 时进入 |
| B：只读账号型 | 可读取但不能回写 | 登录、读喜欢/歌单、搜索、播放 | `readFavorites = true` 时进入；♥ 禁用 |
| C：目录/补充型 | 不代表用户音乐库 | 搜索、歌词、封面、公开目录 | 不进入 |
| D：本地媒体型 | 本地文件与扫描 | 扫描、播放、导入 | 不进入远端喜欢 |

首发目标是网易云与 QQ 两个 A 类 Provider；后续平台按自身能力分级，不能为了“支持数量”伪造完整能力。

## Phase 0 — Provider Registry、Provider 与播放器 Spike（Go / No-Go）

### 目标

确认 Provider Registry、两个首发平台和双端播放器可通过可维护方式完成。

### 交付物

```text
spikes/
├─ provider_contract_spike/
├─ provider_netease_spike/
├─ provider_qq_spike/
├─ android_player_spike/
└─ windows_player_spike/
```

### Provider Registry 必须验证

- [ ] `ProviderId` 为稳定字符串键，不使用仅含首发平台的枚举。
- [ ] Provider 可注册、启用、禁用、查找与展示 descriptor。
- [ ] UI 根据 capability 展示功能，不存在 QQ/网易云特判。
- [ ] 一个 B/C 类 FakeProvider 不会破坏全部喜欢、搜索、本地歌单或播放队列。

### 每个 A/B 类 Provider 必须验证

- [ ] 登录或允许的会话获取。
- [ ] 获取当前账号信息。
- [ ] 若声明支持：拉取「我喜欢」。
- [ ] 若声明支持：拉取每日推荐。
- [ ] 若声明支持写喜欢：在测试歌曲上执行喜欢。
- [ ] 若支持写喜欢：官方客户端验证歌曲真实进入「我喜欢」。
- [ ] 若支持写喜欢：取消喜欢并在官方客户端验证。
- [ ] 若声明支持：解析当前账号允许的播放资源。
- [ ] 若声明支持：解析当前账号允许的下载资源。
- [ ] 登录过期时能识别并提示重新登录。

### 通过条件

- 首发的网易云与 QQ 均完成“读取 → 写回 → 官方端验证”闭环。
- Registry 能承载至少一个非首发 FakeProvider，且上层无平台硬编码。
- 任何关键能力不稳定或不被平台允许时，先将该能力从 descriptor 移除并设计 UI 降级，不进入正式 UI 开发。

---

## Phase 1 — Flutter 骨架与假数据

### 范围

- Flutter Windows + Android 工程。
- Riverpod、go_router、Drift、安全存储封装。
- Provider Registry、ProviderDescriptor、ProviderCapabilities。
- FakeProvider：完整账号型、只读账号型、目录/补充型各至少一个。
- Windows 三栏与 Android 底部导航。
- 虚拟全部喜欢的模拟数据。
- 本地歌单 CRUD。

### 验收

- [ ] 两个平台项目都能启动。
- [ ] 模拟网易云、QQ、第三方只读 Provider、双来源同曲能正确展示。
- [ ] 只有 `readFavorites = true` 的 Provider 进入全部喜欢。
- [ ] 不支持 `writeFavorites` 的来源显示禁用的 ♥ 与原因。
- [ ] 本地歌单可混合加入任意 Provider 的歌曲引用。
- [ ] 同一聚合歌曲能展示独立来源收藏状态。

---

## Phase 2 — 单平台完整闭环

### 范围

优先接入一个 A 类真实 Provider。实现：登录、我喜欢、搜索、推荐、收藏写回、播放、加入本地歌单、单曲下载。

### 验收

- [ ] App 点 ♥ 后，官方客户端可见。
- [ ] 官方客户端的收藏变化，App 刷新后可见。
- [ ] 播放失败、登录失效、网络失败、能力缺失均有可理解的反馈。
- [ ] 下载与喜欢互不影响。
- [ ] Provider 不可用时不影响 FakeProvider、本地歌单与播放器基础功能。

---

## Phase 3 — 首发第二平台与虚拟「全部喜欢」

### 范围

- 第二个 A 类 Provider。
- 所有 eligible Provider 喜欢列表的快照、缓存、刷新。
- 去重与置信度。
- 手动合并 / 拆分。
- 多来源歌曲的收藏开关面板。
- 部分 Provider 刷新失败时的来源级状态。

### 验收

- [ ] 全部喜欢可显示所有 eligible Provider 的合集，而不是写死两家。
- [ ] 同曲多来源不误取消。
- [ ] 用户手动拆分和合并能持久化。
- [ ] 一个 Provider 故障时，其他 Provider 仍可正常展示与播放。

---

## Phase 4 — 生产级媒体体验

### Android

- [ ] Media3 + MediaSessionService。
- [ ] 通知栏、锁屏、蓝牙耳机。
- [ ] 音频焦点处理。
- [ ] 后台场景下下一首资源刷新。

### Windows

- [ ] 系统媒体键。
- [ ] SMTC 元数据。
- [ ] 最小化继续播放。
- [ ] 输出设备变化处理。

---

## Phase 5 — 下载与本地媒体库

- [ ] 单曲、歌单批量下载。
- [ ] 暂停、恢复、失败重试。
- [ ] Windows 下载目录选择。
- [ ] Android 存储权限与媒体目录。
- [ ] 本地文件优先播放。
- [ ] 已下载标记、清理与重新下载。
- [ ] Provider 无下载能力或当前账号无权限时明确降级。

---

## Phase 6 — 第三方 Provider 接入流程固化

### 范围

- [ ] Provider 模板 package。
- [ ] 统一 contract-test runner。
- [ ] descriptor 与 capability 审核清单。
- [ ] 平台接入开发文档。
- [ ] Provider 独立启用 / 禁用开关。
- [ ] Provider 版本兼容与弃用策略。

### 验收

- [ ] 新增一个只读或目录型 Provider 时，不修改核心领域层和页面业务逻辑。
- [ ] 新 Provider 的能力不足时，UI 正确降级。
- [ ] 关闭一个 Provider 后，历史本地歌单仍能显示其歌曲元数据，并提示来源不可用。

---

## Phase 7 — 可选跨设备元数据同步

只同步：本地歌单、排序、隐藏规则、手动合并/拆分、播放历史和应用设置。

不同步：Cookie、令牌、临时播放 URL、临时下载 URL、音频文件。

推荐使用加密 WebDAV 操作日志，而不是直接同步 SQLite 数据库文件。

## 发布门槛

- [ ] 不在日志、数据库、同步文件或崩溃信息中泄露会话凭证。
- [ ] 双端登录失效可以正确恢复。
- [ ] Android 熄屏至少 30 分钟可稳定播放队列。
- [ ] Windows 媒体键与最小化播放稳定。
- [ ] 首发 Provider 的收藏写回可在官方客户端抽检验证。
- [ ] 下载恢复不会依赖过期 URL。
- [ ] 任一 Provider 的禁用、失效或能力缺失不会导致应用崩溃或阻塞其他来源。
