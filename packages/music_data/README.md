# music_data

Persistence codecs and local JSON stores for MeloUnion MVP state.

The default `music_data.dart` entrypoint is platform-neutral and exports only
snapshot models and JSON codecs. File-backed storage lives behind
`music_data_io.dart` so Flutter web builds can consume codecs without importing
`dart:io`.

The codec intentionally does not persist short-lived `PlaybackTicket` or
`DownloadTicket` URLs, headers, or expiry data. Download resumes must request a
fresh ticket from the source Provider.
