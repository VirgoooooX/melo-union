# provider_netease

NetEase Cloud Music Provider adapter for MeloUnion.

Current scope is intentionally conservative:

- Real catalog search through NetEase web endpoints.
- Optional account profile and liked-song reads when a caller injects a local
  Cookie string.
- No favorite write, download, or playback capability is declared until those
  flows are verified against an account and official client behavior.

Do not commit Cookie values, request logs containing Cookie headers, or playback
URLs. Credentials must eventually move behind platform secure storage.
