# Phase 1-5 MVP Status

最后验证日期：2026-06-29

本文件记录当前仓库中已经落地并通过本机验证的 Phase 1-5 MVP 骨架，以及仍不能伪装完成的真实平台缺口。

## 已落地

- Flutter 主应用：桌面宽屏三栏、窄屏/移动端底部导航、全部喜欢、推荐/搜索、本地歌单、下载、Provider 设置页面。
- Provider 契约：`provider_contract` 定义 Provider ID、能力矩阵、曲目引用、播放票据、下载票据、错误模型与 Registry。
- Domain 状态机：`music_domain` 覆盖全部喜欢聚合、本地歌单引用解析、播放队列/预取票据、下载队列和本地媒体条目。
- 本地数据边界：`music_data` 提供平台无关 JSON 快照编解码，可保存本地歌单、下载队列、本地媒体库和手动合并/拆分/隐藏规则；IO 存储单独放在 `music_data_io.dart`，避免污染 Flutter web build。
- Fake Provider：应用内置 3 个能力不同的 Provider，用于验证 UI 不按具体平台写死，而是读取 descriptor/capability。
- 播放桥：Flutter `MethodChannel` 将当前播放票据同步到 Android 原生层；Android runner 注册 Media3 `MediaSessionService` 与 ExoPlayer 队列。
- 下载骨架：支持创建、暂停、恢复、取消、模拟进度、完成后写入本地媒体库条目、从持久化快照恢复任务/本地媒体条目，以及清理后重新下载。

## 已验证

```powershell
cd packages/provider_contract; dart test
cd packages/music_domain; dart test
cd packages/music_data; dart analyze
cd packages/music_data; dart test
cd spikes/provider_contract_spike; dart test
cd app; flutter analyze
cd app; flutter test
cd app; flutter build apk --debug
cd app; flutter build web --debug
cd app; flutter build windows --debug
```

验证结果：

- `provider_contract` 测试通过。
- `music_domain` 测试通过。
- `music_data` analyzer 无问题，JSON 快照和 IO store 测试通过。
- Provider contract spike 测试通过。
- Flutter analyzer 无问题。
- Flutter widget/bridge tests 通过。
- Android debug APK 构建通过，输出位于 `app/build/app/outputs/flutter-apk/app-debug.apk`。
- Web debug build 通过，输出位于 `app/build/web`。
- Windows debug build 通过，输出位于 `app/build/windows/x64/runner/Debug/MeloUnion.exe`。

## 尚未完成

- 真实网易云/QQ Provider：当前仍无账号登录、收藏读取/写回、歌单读取、搜索和媒体 URL 解析的真实适配器。
- 真实播放资源：fake Provider 返回 `provider://...` URI，仅用于验证票据流和桥接，不能代表实际音频播放。
- Android 后台体验验证：尚未做真机熄屏、蓝牙、通知栏、音频焦点、来电、网络切换和长时间播放验证。
- Android 下载落盘：当前已具备可持久化快照和恢复入口，但仍未接入 MediaStore/应用私有目录、存储权限和后台恢复执行器。
- Windows SMTC：Windows runner 已可构建，但未接入原生 SMTC 插件。
- 持久化：JSON 快照边界已落地；Drift/SQLite、安全存储、Provider 会话保存仍未落地。

## 下一步建议

1. 先选一个真实 Provider 做 Phase 2 闭环 spike：登录、读取喜欢、写回喜欢、解析可播放资源。
2. 用真实 HTTP media URL 在 Android 真机上验证 Media3 `MediaSessionService`，再补通知栏、音频焦点和蓝牙控制。
3. 将 `music_data` JSON 快照替换或包裹为 Drift/SQLite 仓储，并把 Provider 凭证接入系统安全存储。
4. 基于已可构建的 Windows runner 实现 SMTC native bridge。
