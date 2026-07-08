# Changelog

## [1.0.1] - 2026-07-08

### Added
- Implemented responsive recommendations feature with mobile and desktop views.
- Implemented full-screen player with responsive layout and automatic artwork precaching.

### Changed
- Documented WebDAV backup flow.

## [1.0.0] - 2026-07-08

### Added
- Implemented track row widgets and placeholder feature pages for navigation structure.
- Implemented provider-specific shell accents and swipeable tab navigation for the app shell.
- Implemented favorites management feature supporting unified tracks and multi-provider data synchronization.
- Implemented backup and restore system with WebDAV cloud support and encrypted account vaulting.
- Implemented unified favorites service with cross-provider metadata tracking and Drift database integration.
- Implemented core UI features (application shell, playlist management, search, and settings pages).

## [0.6.0] - 2026-07-07

### Added
- Added application icon to Windows runner resources.
- Implemented core repository infrastructure, desktop UI shell, and sidebar components for music playback.
- Set mobile navigation bar background color.
- Implemented app shell, accent coloring, and modular navigation features.
- Documented Kugou music provider support.

## [0.5.1] - 2026-07-07

### Fixed

- Fixed Android notification shade media controls not appearing reliably during mobile playback.
- Requested Android 13+ notification permission before starting playback so the media notification can be shown.

### Changed

- Simplified the mobile background playback path to use `just_audio_background` as the single system media session source.
- Removed the unused custom Media3 playback service and platform playback bridge to avoid split playback sessions.
- GitHub Releases now include this changelog entry in the release notes.
