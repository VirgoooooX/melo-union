# ADR-0001：主应用采用 Flutter，而非 Electron + Capacitor

- 状态：Accepted
- 日期：2026-06-29

## 背景

项目要求 Windows + Android 都是长期主力客户端，包含后台播放、锁屏/通知栏、蓝牙控制、本地歌单、下载与平台账号适配。

Electron 对 Windows 桌面端开发很强，但不支持 Android。若选择 Electron，Android 必须另接 Capacitor 或 React Native，并仍需 Kotlin 实现 Media3 后台服务。

## 决策

采用 Flutter / Dart 作为主 UI 与业务层；Android 以 Kotlin + Media3 `MediaSessionService` 补足生产级后台播放；Windows 在系统媒体控制需求明确后以原生插件接入 SMTC。

## 理由

- UI、虚拟歌单、收藏写回、Provider 抽象、本地歌单、缓存、下载状态机可在 Windows 与 Android 共用。
- Android 后台播放器无论前端框架为何都需要原生媒体服务；Flutter 不比 Electron + Capacitor 多绕一层 WebView 桥接。
- Provider 适配的协议实现可以在 Dart 中统一运行，避免 Electron Node 代码无法等价运行到 Android WebView 的问题。
- 项目目标是长期音乐 App，而非桌面优先的下载工具。

## 后果

- 需要学习和维护 Dart。
- 复杂平台协议的社区参考可能多为 Node/TypeScript；可作为 Spike 参考，但最终实现不直接依赖 Node。
- Windows SMTC、Android Media3 等平台能力需要少量原生代码。
