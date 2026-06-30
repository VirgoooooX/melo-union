# QQ Music Provider 真实 API 接入设计

## 概述

将 `QqMusicProvider` 中 `pullFavorites`、`getUserPlaylists`、`getPlaylistTracks`、`getRecommendedPlaylists`、`getDailyRecommendations`、`getProfile` 六个方法从桩代码（stub）替换为真实 QQ Music API 调用，实现与 NeteaseMusicProvider 同级别的完整功能。

## 背景

当前 `packages/provider_qq` 的 QQ 音乐 provider 已有完整的基础设施：
- QQ / 微信扫码登录 ✅
- 歌曲搜索 ✅
- 歌词获取 ✅
- 播放和下载票据生成 ✅

但以下方法仍为桩代码：

| 方法 | 当前行为 | 问题 |
|------|---------|------|
| `pullFavorites()` | 搜索"周杰伦"伪装成喜欢列表 | 无真实数据、无喜欢时间 |
| `getDailyRecommendations()` | 搜索"流行"取前15条 | 非真实推荐 |
| `getRecommendedPlaylists()` | 2 条硬编码歌单 | 无真实数据 |
| `getUserPlaylists()` | 2 条硬编码歌单 | 无真实数据 |
| `getPlaylistTracks()` | 按 ID 搜索不同关键词 | 无真实数据 |
| `getProfile()` | 返回固定占位数据 | 无真实用户名 |

## 参考实现

本设计参考了 [guohuiyuan/music-lib](https://github.com/guohuiyuan/music-lib) 中 `qq/` 目录的 Go 实现，该库的 QQ 音乐模块经验证可正常工作。

## 架构

```
QqMusicProvider
├── _musicuJsonRequest(Map body)        ← 通用 musicu.fcg POST 网关
├── _qqFcgRequest(Uri uri)             ← 通用 QQ FCGI GET（含 JSONP strip）
├── _extractUin()                       ← 从 cookie 提取用户 uin
│
├── pullFavorites()
│   └── _fetchProfileSongs()            → fcg_get_profile_order_asset.fcg?reqtype=1
│
├── getUserPlaylists()
│   ├── _fetchProfilePlaylists()        → fcg_get_profile_order_asset.fcg?reqtype=3
│   └── _fetchCreatedPlaylists()        → fcg_user_created_diss
│
├── getPlaylistTracks(id)
│   ├── id == "profile:favorites"       → _fetchProfileSongs()
│   ├── id startsWith "profile:dir:"    → fcg_musiclist_getinfo.fcg
│   └── others                          → fcg_ucc_getcdinfo_byids_cp.fcg
│
├── getRecommendedPlaylists()
│   └── _musicuJsonRequest({module: playlist.HotRecommendServer, method: get_hot_recommend})
│
├── getDailyRecommendations()
│   └── _musicuJsonRequest({module: music.recommend.SmartRadio, method: GetSmartRadio})
│       fallback → getHotSongs() / search("流行")
│
└── getProfile()
    └── 从 cookie 解析 uin + _fetchProfileSongs() 中的用户信息
```

## 详细 API 规格

### 1. 用户歌单列表 `getUserPlaylists()`

**API 1：用户创建的歌单**

```
GET https://c.y.qq.com/rsc/fcgi-bin/fcg_user_created_diss
Params:
  hostuin   = {uin}
  sin       = 0
  size      = 100
  format    = json
  inCharset = utf8
  outCharset= utf-8
Headers:
  Cookie: {cookie}
  Referer: https://y.qq.com/
```

响应结构（参考 `music-lib`）：
```json
{
  "code": 0,
  "data": {
    "disslist": [
      {
        "dissid": 123456789,
        "diss_name": "我的歌单",
        "diss_cover": "http://...",
        "song_cnt": 30,
        "listen_num": 1500,
        "diss_desc": "...",
        "commit_time": "2026-01-15 10:30:00"
      }
    ],
    "list": [
      {
        "dissid": "987654321",
        "dissname": "收藏的歌单",
        "imgurl": "https://...",
        "song_count": 20,
        "listennum": 3000
      }
    ]
  }
}
```

`disslist` = 用户创建的歌单，`list` = 用户收藏的歌单。

**API 2：Profile 排序资产**（补充收藏歌单）

```
GET https://c.y.qq.com/fav/fcgi-bin/fcg_get_profile_order_asset.fcg
Params:
  reqtype   = 3        (3=歌单)
  sin       = {offset}
  ein       = {end}
  format    = json
  loginUin  = {uin}
  hostUin   = 0
  g_tk      = 5381
```

### 2. 喜欢的歌曲 `pullFavorites()`

```
GET https://c.y.qq.com/fav/fcgi-bin/fcg_get_profile_order_asset.fcg
Params:
  reqtype   = 1        (1=歌曲)
  sin       = {offset}
  ein       = {end}
  format    = json
  platform  = yqq.json
  loginUin  = {uin}
  hostUin   = 0
  g_tk      = 5381
```

响应结构：
```json
{
  "code": 0,
  "data": {
    "totalsong": 300,
    "songlist": [
      {
        "data": {
          "songid": 123456,
          "songname": "晴天",
          "songmid": "003abc",
          "albumname": "叶惠美",
          "albummid": "001xyz",
          "interval": 269,
          "singer": [{ "name": "周杰伦" }],
          "size128": 1234567,
          "size320": 2345678,
          "sizeflac": 5678910
        }
      }
    ]
  }
}
```

**喜欢时间处理**：QQ Music 的 profile order API 返回的 `songlist` 按添加时间排序，最新添加的在前。我们以 `index` 为参考顺序，返回的 `FavoriteSnapshot` 保持此顺序（最新在前），无需精确时间戳。

### 3. 歌单曲目 `getPlaylistTracks()`

**普通歌单（dissid）：**

```
GET https://i.y.qq.com/qzone-music/fcg-bin/fcg_ucc_getcdinfo_byids_cp.fcg
Params:
  disstid   = {playlistId}
  type      = 1
  json      = 1
  utf8      = 1
  onlysong  = 0
  format    = json
  g_tk      = 5381
```

注意：该 API 返回 **JSONP** 格式，需要 strip 外层的 `callback(...)` 包裹。

响应结构：
```json
{
  "code": 0,
  "cdlist": [{
    "dissname": "歌单名",
    "logo": "https://...",
    "nickname": "创建者",
    "songnum": 30,
    "songlist": [
      {
        "songid": 123,
        "songname": "歌名",
        "songmid": "mid",
        "albumname": "专辑",
        "albummid": "amid",
        "interval": 240,
        "singer": [{ "name": "歌手" }]
      }
    ]
  }]
}
```

**Dir 类型歌单**（包含"我喜欢的歌曲"的内部表示）：

```
GET http://s.plcloud.music.qq.com/fcgi-bin/fcg_musiclist_getinfo.fcg
Params:
  uin       = {uin}
  dirid     = {dirId}
  from      = 0
  to        = 500
  format    = json
  g_tk      = 5381
Headers:
  Referer: https://y.qq.com/w/myalbum.html
```

### 4. 推荐歌单 `getRecommendedPlaylists()`

```
POST https://u.y.qq.com/cgi-bin/musicu.fcg
Content-Type: application/json

Body:
{
  "comm": { "ct": 24 },
  "recomPlaylist": {
    "module": "playlist.HotRecommendServer",
    "method": "get_hot_recommend",
    "param": { "async": 1, "cmd": 2 }
  }
}
```

响应：
```json
{
  "code": 0,
  "recomPlaylist": {
    "data": {
      "v_hot": [
        {
          "content_id": 123456789,
          "title": "今日推荐",
          "cover": "https://...",
          "listen_num": 50000,
          "song_cnt": 30,
          "username": "QQ音乐"
        }
      ]
    }
  }
}
```

### 5. 每日推荐 `getDailyRecommendations()`

使用 `musicu.fcg` 的 SmartRadio 模块：

```
POST https://u.y.qq.com/cgi-bin/musicu.fcg
Body:
{
  "comm": { "ct": 24, "cv": 0 },
  "recommend": {
    "module": "music.recommend.SmartRadio",
    "method": "GetSmartRadio",
    "param": { "uin": "{uin}" }
  }
}
```

如果该 API 返回空或出错（QQ 音乐可能对此接口有限制），降级到搜索热门歌曲。

### 6. 用户信息 `getProfile()`

从 Cookie 中解析 uin 和相关用户信息。Cookie 通常在 QQ 登录后包含：
- `uin` 或 `musicid` = 用户 QQ 号 / 音乐 ID
- `qqmusic_key` = 认证 key
- `nickname` 或相关字段（某些登录方式包含）

优先查找 `uin` / `musicid` / `wxuin` 字段；如果 `displayName` 无法从 cookie 解析，可额外调用 `fcg_get_profile_order_asset.fcg` 的响应中获取 `nickname`。

## 辅助方法

### JSONP Strip 工具

```dart
String _stripJsonp(String raw) {
  // QQ API 返回格式: callback({...}) 或 ({...})
  final trimmed = raw.trim();
  if (trimmed.startsWith('(') && trimmed.endsWith(')')) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  final idx = trimmed.indexOf('(');
  if (idx >= 0 && trimmed.endsWith(')')) {
    return trimmed.substring(idx + 1, trimmed.length - 1);
  }
  return trimmed;
}
```

### Cookie UIN 提取

```dart
String? _extractUin() {
  final cookie = _credentials?.cookie ?? '';
  // 按优先级尝试常见 uin 字段
  for (final key in ['uin', 'musicid', 'wxuin', 'euin', 'p_uin', 'userid']) {
    final match = RegExp('${key}=([^;]+)').firstMatch(cookie);
    if (match != null) {
      final value = match.group(1)?.trim();
      if (value != null && value.isNotEmpty && value != '0') return value;
    }
  }
  return null;
}
```

## 数据模型映射

参考 `music-lib` 的 `model.Song → SourceTrack` 映射：

| model.Song 字段 | SourceTrack 字段 | 说明 |
|---|---|---|
| ID / songmid | `ref.trackId` | 使用 songmid 作为主要 ID |
| Name | `title` | 直接映射 |
| Artist (拼接) | `artists` | 拆分为 List |
| Album | `album` | 直接映射 |
| Duration (秒) | `duration` | 从 Duration(seconds) 构造 |
| Cover | `artwork` | 直接映射为 Uri |
| Extra.songmid | `ref.extraIds['song_mid']` | 用于 vkey 解析 |
| Extra.album_mid | `ref.extraIds['album_mid']` | 用于 artwork URL |

ProviderPlaylist 映射：
| 响应字段 | ProviderPlaylist 字段 |
|---|---|
| dissid / content_id | `playlistId` |
| diss_name / title | `name` |
| nickname / username | `creatorName` |
| diss_cover / logo / cover / imgurl | `cover` |
| song_cnt / song_count / songnum | `trackCount` |
| listen_num / visitnum | `playCount` |

## 错误处理

- 所有网络请求使用 `_client.get/post` 加 15 秒超时
- QQ Music API 错误码非 0 时抛出 `ProviderException`（附带错误信息）
- Cookie 缺失或 uin 缺失时抛出 `AuthenticationRequiredException`
- HTTP 非 2xx 时抛出 `ProviderException`
- 部分接口（如每日推荐）失败时应优雅降级而非硬失败
- JSONP 解析失败时应重试不同格式

## 测试策略

参考现有的 `test/qq_music_provider_test.dart` 模式，使用 `_FakeClient` mock HTTP 层：

- `test('getUserPlaylists maps created and collected playlists')` —— mock `fcg_user_created_diss` 响应
- `test('pullFavorites maps profile order songs')` —— mock `fcg_get_profile_order_asset.fcg` 响应
- `test('getPlaylistTracks strips JSONP and maps song list')` —— mock `fcg_ucc_getcdinfo_byids_cp.fcg` 响应
- `test('getRecommendedPlaylists maps musicu.fcg hot recommend')` —— mock POST 响应
- `test('getProfile extracts uin from cookie')` —— 测试 cookie 解析
- `test('getDailyRecommendations falls back to search on empty response')` —— 测试降级

## 文件变更清单

1. **`packages/provider_qq/lib/src/qq_music_provider.dart`**
   - 新增 `_extractUin()`、`_stripJsonp()`、`_musicuRequest()`、`_fcgRequest()` 辅助方法
   - 替换 `pullFavorites()` 为真实实现
   - 替换 `getUserPlaylists()` 为真实实现
   - 替换 `getPlaylistTracks()` 为真实实现
   - 替换 `getRecommendedPlaylists()` 为真实实现
   - 替换 `getDailyRecommendations()` 为真实实现
   - 替换 `getProfile()` 从 cookie 提取用户信息
   - 新增 `_trackFromQqSong()` 和 `_playlistFromQqItem()` 转换方法

2. **`packages/provider_qq/test/qq_music_provider_test.dart`**
   - 补充 6 个新方法的测试用例

## 未覆盖事项

- 精确的喜欢时间戳（QQ Music API 未直接提供，使用 profile order 排序作为参考）
- QQ 绿钻 VIP 歌曲的播放限制（已有 vkey 解析，但 VIP 判定未在 provider 层实现）
