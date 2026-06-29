# NetEase Provider Status

最后更新：2026-06-29

`packages/provider_netease` 是首个真实平台 Provider。当前状态是 experimental，不应对用户承诺完整网易云账号闭环。

## 已接入

- `ProviderId('netease_cloud_music')`
- 真实网易云 Web 搜索端点：`/api/search/get/web`
- 可选 Cookie 注入后的账号资料读取：`/api/nuser/account/get`
- 可选 Cookie 注入后的喜欢歌曲 ID 读取与歌曲详情映射：`/api/song/like/get`、`/api/song/detail/`
- App Registry 注册，UI 仍按 capability 展示，不加网易云特判。
- 设置页可导入或清除本机 Cookie 会话；启动时会从会话边界读取并注入 Provider。

## 当前能力声明

- 无 Cookie：`search`、`artwork`
- 注入 Cookie：额外声明 `authenticate`、`readFavorites`

暂不声明：

- `writeFavorites`
- `readUserPlaylists`
- `readDailyRecommendations`
- `resolvePlayback`
- `resolveDownload`

这些能力需要官方客户端抽检、错误分类和安全存储接线后再开放。

## 安全边界

- 不提交 Cookie、二维码会话、授权头或真实账号资料。
- 不把 Cookie 写入 SQLite、测试 fixture、日志或文档。
- Android 端 Cookie 通过 `melo_union/provider_credentials` MethodChannel 写入应用私有 SharedPreferences；桌面开发可使用 `MELO_NETEASE_COOKIE` / `MELO_NETEASE_USER_ID` 环境变量或当前进程内存会话。
- 不持久化播放/下载 URL 和 headers。
- 不使用公共账号池、第三方代登录或绕过会员/地区/版权限制的接口。

## 下一步

1. 将 Android 私有存储升级为系统级加密存储，并补 Windows Credential Manager 实现。
2. 使用测试账号验证 `readFavorites` 与官方客户端一致。
3. 在完成官方端抽检前，不开放写收藏、播放票据和下载票据能力。
