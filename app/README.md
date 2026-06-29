# MeloUnion App

Flutter Phase 1-5 MVP shell for MeloUnion.

This app uses fake capability-aware providers to exercise:

- all-favorites aggregation from enabled, authenticated `readFavorites` sources;
- independent source favorite states on a merged track;
- read-only favorite controls with visible disabled reasons;
- local playlists that preserve cached metadata when a provider is disabled;
- search routed by provider capabilities;
- a basic playback queue surface.

Run from this directory:

```powershell
flutter pub get
flutter test
flutter run -d chrome
```

Windows and Android runner directories are present, but native builds still depend on the local machine having the required Visual Studio C++ workload and Android command-line tools/licenses.
