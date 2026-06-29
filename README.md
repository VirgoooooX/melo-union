# MeloUnion

> Windows + Android 的双平台统一音乐客户端。
>
> 将网易云音乐「我喜欢的音乐」与 QQ 音乐「我喜欢」聚合成一个**虚拟歌单**，同时保留每首歌的原始平台身份；收藏/取消收藏永远写回对应平台。本地自定义歌单可以混放两家歌曲引用，下载、播放队列和本地媒体管理独立于收藏逻辑。

## 核心体验

```text
网易云「我喜欢的音乐」 ─┐
                        ├─→ 「全部喜欢」虚拟歌单 → 统一浏览 / 搜索 / 随机播放
QQ 音乐「我喜欢」      ─┘

本地自定义歌单
├─ 通勤
├─ 睡前
└─ 精选
```

- 在网易云每日推荐中点 ♥：写回网易云「我喜欢的音乐」。
- 在 QQ 音乐搜索结果中点 ♥：写回 QQ 音乐「我喜欢」。
- 在本地歌单中点 ♥：按歌曲保存的原始来源写回对应平台。
- 「全部喜欢」只是一层聚合视图，不会创建第三份云端歌单。
- 同一首歌两边都喜欢时，界面可合并展示，但底层保留两条远端记录。
- 下载与收藏无绑定：下载不等于喜欢，喜欢不等于下载。

## 技术路线

- **主应用**：Flutter / Dart
- **目标平台**：Windows、Android
- **状态与导航**：Riverpod、go_router
- **本地数据**：Drift + SQLite
- **敏感登录态**：系统安全存储（不进 SQLite、不进同步）
- **网络与平台适配**：Dio + 可替换的 Provider Adapter
- **Android 播放**：Kotlin、Android Media3、`MediaSessionService`
- **Windows 播放与系统媒体控制**：先做 Dart 音频引擎验证；SMTC 以 Windows 原生插件接入

详细设计见 [docs/architecture.md](docs/architecture.md)。

## 当前状态

`planning` — 尚未接入任何平台账号或协议实现。

第一条工程原则：先完成 Provider Spike，再实现正式 UI。

```text
登录 → 读取我喜欢 → 点 ♥ 写回 → 官方客户端验证 → 解析可播放资源
```

若其中任一项不能通过平台允许、稳定且可维护的方式实现，必须在进入正式功能开发前降级或调整范围。

## 文档索引

- [架构与技术设计](docs/architecture.md)
- [开发路线图与验收门槛](docs/roadmap.md)
- [Provider Spike 验证清单](docs/provider-spike.md)
- [安全、隐私与数据边界](docs/security.md)
- [架构决策：为何选 Flutter](docs/adr/0001-flutter-first.md)

## 目录规划

```text
melo-union/
├─ app/                         # Flutter 主应用（后续 flutter create 生成）
├─ packages/
│  ├─ music_domain/             # 实体、值对象、用例与仓储接口
│  ├─ music_data/               # Drift、缓存、安全存储、仓储实现
│  ├─ provider_contract/        # 音乐平台统一契约
│  ├─ provider_netease/         # 网易云适配器
│  ├─ provider_qq/              # QQ 音乐适配器
│  ├─ playback_bridge/          # 播放器跨层桥接契约
│  └─ download_bridge/          # 下载跨层桥接契约
├─ docs/
└─ tooling/
```

## 非目标

第一版不做评论、社交、MV、播客、电台、音效、自动换源、跨设备同步本地歌单、歌词逐字动效或云端代理服务。

不设计 DRM 绕过、会员权益绕过、地区限制绕过，也不将账号 Cookie 或临时播放链接上传到 NAS、WebDAV 或第三方服务。
