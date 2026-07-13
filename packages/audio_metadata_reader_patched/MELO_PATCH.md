# MeloUnion patch

This package is pinned from `audio_metadata_reader` 1.6.0 so the local
library can distinguish track artists from album artists without changing
users' audio files.

Local changes:

- Vorbis/FLAC/Opus: keep `ARTIST` and `ALBUMARTIST` in separate lists.
- MP4/M4A: parse `©ART` as track artist and `aART` as album artist.
- ID3v2.4: preserve NUL-separated values in `TPE1` and `TPE2`.

APE already exposes `artist` and `albumArtist`; the app consumes the raw fields
through `readAllMetadata`.
