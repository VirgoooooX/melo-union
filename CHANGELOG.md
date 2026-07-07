# Changelog

## [0.5.1] - 2026-07-07

### Fixed

- Fixed Android notification shade media controls not appearing reliably during mobile playback.
- Requested Android 13+ notification permission before starting playback so the media notification can be shown.

### Changed

- Simplified the mobile background playback path to use `just_audio_background` as the single system media session source.
- Removed the unused custom Media3 playback service and platform playback bridge to avoid split playback sessions.
- GitHub Releases now include this changelog entry in the release notes.
