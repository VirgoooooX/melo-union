# NetEase Provider Status

最后更新：2026-06-30

`packages/provider_netease` 是首个真实平台 Provider。当前状态是 experimental，不应对用户承诺完整网易云账号闭环。

## 已接入

- `ProviderId('netease_cloud_music')`
- 真实网易云 Web 搜索端点：`/api/search/get/web`
- 可选 Cookie 注入后的账号资料读取：`/api/nuser/account/get`
- 可选 Cookie 注入后的喜欢歌曲读取与歌曲详情映射：用户歌单定位喜欢列表，`/api/v6/playlist/detail`、`/api/song/detail/`
- App Registry 注册，UI 按 capability 与 provider 展示元数据渲染。
- 设置页支持网易云 App 扫码登录，也保留 Cookie 导入/清除作为高级兜底；启动时会从会话边界读取并注入 Provider。

## 当前能力声明

- 无 Cookie：`search`、`artwork`、`resolvePlayback`、`resolveDownload`、`lyrics`
- 注入 Cookie：额外声明 `authenticate`、`readFavorites`、`writeFavorites`、`readUserPlaylists`、`readDailyRecommendations`
- 歌单：已接入用户歌单列表与歌单详情曲目读取。
- 推荐：已接入每日推荐歌曲读取，并从 App 推荐页直接调用 Provider API。
- 播放 / 下载票据：当前已提供 `resolvePlayback`、`resolveDownload` 路径；优先使用 `/api/song/enhance/player/url/v1` 的音质 level 解析，失败时回落旧版码率接口，再失败才回落网易云公开外链 URL。App 端已透传票据 headers 给 `just_audio`，用于 Windows 桌面播放验证。

`writeFavorites`、播放票据和下载票据的代码路径已经有 mock 测试覆盖；本机 Credential Manager 中的真实 Cookie 已通过认证 smoke，验证到喜欢列表、每日推荐、搜索、歌词以及标准/较高/极高/无损音质票据，其中无损返回 FLAC。

## 安全边界

- 不提交 Cookie、二维码会话、授权头或真实账号资料。
- 不把 Cookie 写入 SQLite、测试 fixture、日志或文档。
- Android 端 Cookie 通过 `melo_union/provider_credentials` MethodChannel 写入系统级加密的 SharedPreferences (EncryptedSharedPreferences)；Windows 桌面环境通过 MethodChannel 写入 Windows 凭据管理器 (Credential Manager)；也可使用 `MELO_NETEASE_COOKIE` / `MELO_NETEASE_USER_ID` 环境变量或当前进程内存会话。
- 不持久化播放/下载 URL 和 headers。
- 不使用公共账号池、第三方代登录或绕过会员/地区/版权限制的接口。

## 下一步

1. 使用测试账号验证 `readFavorites` 与官方客户端一致。
2. 运行 `packages/provider_netease/tool/netease_auth_smoke.dart` 完成 profile、喜欢列表、歌单、每日推荐、搜索、播放票据、下载票据和可选写收藏 roundtrip 验证。
3. 对 `writeFavorites` 做官方客户端抽检：喜欢后可见，恢复后不可见或回到原状态。
4. 对扫码登录做 Windows 与 Android 真机回归，确认扫码成功后的 Cookie 能被平台安全存储读取并跨启动保留。

## 已完成的下一步

- 将 Android 私有存储升级为系统级加密存储，并补 Windows Credential Manager 实现。
