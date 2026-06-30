# provider_qq

QQ Music Provider adapter for MeloUnion.

Current scope is intentionally conservative:

- Public catalog search through QQ Music web endpoints.
- Public lyric lookup.
- Playback and download ticket resolution when QQ Music returns a public vkey
  URL for the selected track.
- QQ / WeChat QR login session creation and polling. Successful QR login
  returns QQ Music cookies for the app to store in platform secure storage.
  Account capabilities are not declared until account reads/writes pass smoke
  verification.

Do not commit cookies, OAuth callbacks, QR session tokens, request logs
containing account headers, or playback URLs.
