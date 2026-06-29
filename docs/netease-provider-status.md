# NetEase Provider Status

最后更新：2026-06-29

`packages/provider_netease` 是首个真实平台 Provider。当前状态是 experimental，不应对用户承诺完整网易云账号闭环。

## 已接入

- `ProviderId('netease_cloud_music')`
- 真实网易云 Web 搜索端点：`/api/search/get/web`
- 可选 Cookie 注入后的账号资料读取：`/api/nuser/account/get`
- 可选 Cookie 注入后的喜欢歌曲 ID 读取与歌曲详情映射：`/api/song/like/get`、`/api/song/detail/`
- App Registry 注册，UI 仍按 capability 展示，不加网易云特判。

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
- 不持久化播放/下载 URL 和 headers。
- 不使用公共账号池、第三方代登录或绕过会员/地区/版权限制的接口。
