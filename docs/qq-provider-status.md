# QQ Provider Status

最后更新：2026-06-30

`packages/provider_qq` 是 QQ 音乐的 experimental Provider。当前先接入公开目录能力和扫码登录入口框架，不对用户承诺完整 QQ 音乐账号闭环。

## 已接入

- `ProviderId('qq_music')`
- 公开搜索端点：`/soso/fcgi-bin/client_search_cp`
- 歌词端点：`/lyric/fcgi-bin/fcg_query_lyric_new.fcg`
- 播放 / 下载票据解析：`https://u.y.qq.com/cgi-bin/musicu.fcg` 的 vkey 响应；如果 QQ 未返回 `purl`，Provider 会抛出不可播放错误，不伪造 URL。
- 设置页支持 QQ / 微信两个真实扫码登录流程：QQ 使用 `ptqrshow` / `ptqrlogin`，微信使用 `open.weixin.qq.com/connect/qrconnect` 轮询后通过 QQ 音乐 `musicu.fcg` 换取 Cookie；扫码成功后 Cookie 会写入平台安全存储。

## 当前能力声明

- 已声明：`search`、`artwork`、`resolvePlayback`、`resolveDownload`、`lyrics`
- 当前登录能力已接入设置页会话层，但 Provider 仍暂不声明 `authenticate`、`readFavorites`、`writeFavorites`、`readUserPlaylists`、`readDailyRecommendations`，直到账号读取/写回 smoke 完成。

## 下一步

1. 真实账号 smoke：QQ 扫码、微信扫码、登录后播放/下载票据。
2. 接入 profile、喜欢列表、用户歌单、每日推荐。
3. 通过官方端抽检后再声明账号读写能力。
