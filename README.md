# MeloUnion

> Windows + Android 的**可扩展多平台**统一音乐客户端。

MeloUnion 首发目标是接入网易云音乐与 QQ 音乐；架构不把任何平台写死。每个音乐来源都是一个可注册的 Provider，后续可按平台能力逐步接入更多服务。

当前核心体验是：将所有已启用、已登录且支持读取收藏的平台，聚合成一个**虚拟歌单**；同时保留每首歌的原始平台身份。收藏/取消收藏永远写回对应平台。本地自定义歌单可混放任意 Provider 的歌曲引用，下载、播放队列和本地媒体管理独立于收藏逻辑。

## Phase 1-5 MVP 运行说明

当前仓库已包含 `app/`、`packages/provider_contract/`、`packages/music_domain/` 与 `packages/music_data/` 的 Phase 1-5 MVP 源码骨架。Provider / 播放 / 下载仍使用 fake provider；Android 已接入 Media3 `MediaSessionService` 桥接骨架，下载/本地歌单/覆盖规则已有 JSON 快照与 Drift/SQLite 仓储边界，但 fake provider 只返回 `provider://...` 票据 URI，真实音频播放仍依赖后续正式 Provider 解析。具备 Flutter / Dart SDK 后可按下列顺序验证：

- `cd packages/provider_contract && dart test`
- `cd packages/music_domain && dart test`
- `cd packages/music_data && dart test`
- `cd app && flutter pub get && flutter test`

## 核心体验

```text
网易云「我喜欢的音乐」 ─┐
QQ 音乐「我喜欢」      ├─→ 「全部喜欢」虚拟歌单 → 统一浏览 / 搜索 / 随机播放
未来其他支持收藏的平台 ─┘

本地自定义歌单
├─ 通勤
├─ 睡前
└─ 精选
```

- 在网易云每日推荐中点 ♥：写回网易云「我喜欢的音乐」。
- 在 QQ 音乐搜索结果中点 ♥：写回 QQ 音乐「我喜欢」。
- 在未来接入的平台中点 ♥：仅在该平台声明支持写收藏时写回该平台。
- 在本地歌单中点 ♥：按歌曲保存的原始来源写回对应平台。
- 「全部喜欢」是一个聚合视图，不会创建第三份云端歌单。
- 同一首歌多平台都喜欢时，界面可合并展示；底层仍保留每个来源的独立记录与收藏状态。
- 下载与收藏无绑定：下载不等于喜欢，喜欢不等于下载。

## 平台扩展模型

每个平台实现同一份 `MusicProvider` 契约，并由 `ProviderRegistry` 注册。上层只面向统一模型与能力矩阵工作：

```text
UI / 本地歌单 / 全部喜欢 / 播放队列
                    ↓
          ProviderRegistry + Capabilities
                    ↓
网易云 Provider / QQ Provider / 酷狗 Provider / 酷我 Provider / …
```

平台按能力分级：

- **完整账号型**：登录、读/写喜欢、我的歌单、搜索、播放、下载。
- **只读账号型**：可读取喜欢或歌单，但不能写回收藏。
- **目录/补充型**：搜索、歌词、封面或备用元数据，不参与「全部喜欢」。

「全部喜欢」的定义是：

```text
所有已启用 + 已登录 + canReadFavorites = true 的 Provider 的喜欢歌曲并集
```

新 Provider 需要随 App 版本编译发布；首版不允许从网络动态下载可执行 Provider 插件，以避免供应链、会话凭证与审核风险。

详细设计见 [docs/architecture.md](docs/architecture.md) 与 [Provider 可扩展性设计](docs/provider-extensibility.md)。

## 技术路线

- **主应用**：Flutter / Dart
- **目标平台**：Windows、Android
- **状态与导航**：Riverpod、go_router
- **本地数据**：Drift + SQLite
- **敏感登录态**：系统安全存储（不进 SQLite、不进同步）
- **网络与平台适配**：Dio + 可替换的 Provider Adapter
- **Android 播放**：Kotlin、Android Media3、`MediaSessionService`
- **Windows 播放与系统媒体控制**：先做 Dart 音频引擎验证；SMTC 以 Windows 原生插件接入

## 当前状态

`mvp-skeleton` — Phase 1-5 的可运行骨架已通过本机构建/测试；尚未接入任何真实平台账号或协议实现。

第一条工程原则：先完成 Provider Spike，再实现正式 UI。

```text
登录 → 读取我喜欢 → 点 ♥ 写回 → 官方客户端验证 → 解析可播放资源
```

若其中任一项不能通过平台允许、稳定且可维护的方式实现，必须在进入正式功能开发前降级或调整范围。

## 文档索引

- [架构与技术设计](docs/architecture.md)
- [Provider 可扩展性设计](docs/provider-extensibility.md)
- [开发路线图与验收门槛](docs/roadmap.md)
- [Phase 1-5 MVP 当前状态](docs/mvp-phase1-5-status.md)
- [Provider Spike 验证清单](docs/provider-spike.md)
- [安全、隐私与数据边界](docs/security.md)
- [架构决策：为何选 Flutter](docs/adr/0001-flutter-first.md)

## 目录规划

```text
melo-union/
├─ app/                         # Flutter 主应用（含 Android / Windows / Web runner）
├─ packages/
│  ├─ music_domain/             # 实体、值对象、用例与仓储接口
│  ├─ music_data/               # Drift、缓存、安全存储、仓储实现
│  ├─ provider_contract/        # 平台无关的契约、ID、能力模型、Registry
│  ├─ provider_netease/         # 网易云适配器
│  ├─ provider_qq/              # QQ 音乐适配器
│  ├─ provider_<platform>/      # 后续平台适配器（随版本编译）
│  ├─ playback_bridge/          # 播放器跨层桥接契约
│  └─ download_bridge/          # 下载跨层桥接契约
├─ docs/
└─ tooling/
```

## 非目标

第一版不做评论、社交、MV、播客、电台、音效、自动换源、跨设备同步本地歌单、歌词逐字动效、云端代理服务或在线下载 Provider 插件。

不设计 DRM 绕过、会员权益绕过、地区限制绕过，也不将账号 Cookie 或临时播放链接上传到 NAS、WebDAV 或第三方服务。
