# provider_netease

NetEase Cloud Music Provider adapter for MeloUnion.

Current scope is intentionally conservative:

- Real catalog search through NetEase web endpoints.
- QR login session creation/checking plus optional local Cookie injection.
- Optional account profile, liked-song, user playlist, and daily
  recommendation reads when the caller provides a session.
- Favorite write, playback, download, and lyric paths exist and are covered by
  mocked tests; keep the provider experimental until official-client smoke
  verification is complete.

Do not commit Cookie values, request logs containing Cookie headers, or playback
URLs. Credentials must eventually move behind platform secure storage.
The Flutter app stores real sessions outside SQLite/snapshots through platform
secure storage.

Run a non-authenticated live search smoke with:

```powershell
dart run tool/netease_smoke.dart 孤勇者
```
