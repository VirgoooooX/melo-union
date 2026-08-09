import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:music_domain/music_domain.dart';
import 'package:path/path.dart' as path;

import 'local_library_scanner.dart';

enum LocalLibraryView { songs, albums, artists }

final class LocalLibraryController extends ChangeNotifier {
  LocalLibraryController({required this.repository, required this.scanner});

  final LocalLibraryRepository repository;
  final LocalLibraryScanner scanner;

  List<LocalLibraryRoot> _roots = const [];
  List<LocalLibraryTrack> _tracks = const [];
  List<LocalLibraryAlbum> _albums = const [];
  List<LocalLibraryArtist> _artists = const [];
  LocalLibraryStats _stats = const LocalLibraryStats(
    trackCount: 0,
    albumCount: 0,
    artistCount: 0,
  );
  LocalLibraryScanProgress? _progress;
  bool _loading = false;
  bool _hasMore = false;
  bool _closed = false;
  String _query = '';
  LocalLibrarySortOrder _sort = LocalLibrarySortOrder.album;
  LocalAlbumSortOrder _albumSort = LocalAlbumSortOrder.artist;
  LocalArtistSortOrder _artistSort = LocalArtistSortOrder.name;
  LocalLibraryView _view = LocalLibraryView.songs;
  int _requestGeneration = 0;
  // 删除目录前等待扫描退出，避免扫描结果重新写回。
  Future<void>? _activeScan;

  List<LocalLibraryRoot> get roots => _roots;
  List<LocalLibraryTrack> get tracks => _tracks;
  List<LocalLibraryAlbum> get albums => _albums;
  List<LocalLibraryArtist> get artists => _artists;
  LocalLibraryStats get stats => _stats;
  LocalLibraryScanProgress? get progress => _progress;
  bool get isLoading => _loading;
  bool get isScanning => _roots.any(
        (root) => root.scanState == LocalLibraryScanState.scanning,
      );
  String get query => _query;
  LocalLibrarySortOrder get sort => _sort;
  LocalAlbumSortOrder get albumSort => _albumSort;
  LocalArtistSortOrder get artistSort => _artistSort;
  LocalLibraryView get view => _view;
  bool get hasMore => _hasMore;

  Future<void> initialize({bool scanOnStartup = true}) async {
    await reload();
    if (scanOnStartup && _roots.isNotEmpty) {
      await scanAll();
    }
  }

  Future<void> reload({String? query}) async {
    if (query != null) _query = query;
    final generation = ++_requestGeneration;
    final view = _view;
    final currentQuery = _query;
    final trackSort = _sort;
    final albumSort = _albumSort;
    final artistSort = _artistSort;
    _loading = true;
    notifyListeners();
    try {
      final roots = await repository.listRoots();
      final stats = await repository.getStats();
      switch (view) {
        case LocalLibraryView.songs:
          final tracks = await repository.listTracks(
              query: currentQuery, sort: trackSort, limit: 500);
          if (generation != _requestGeneration) return;
          _roots = roots;
          _stats = stats;
          _tracks = tracks;
          _hasMore = tracks.length == 500;
        case LocalLibraryView.albums:
          final albums = await repository.listAlbums(
              query: currentQuery, sort: albumSort, limit: 100);
          if (generation != _requestGeneration) return;
          _roots = roots;
          _stats = stats;
          _albums = albums;
          _hasMore = albums.length == 100;
        case LocalLibraryView.artists:
          final artists = await repository.listArtists(
              query: currentQuery, sort: artistSort, limit: 100);
          if (generation != _requestGeneration) return;
          _roots = roots;
          _stats = stats;
          _artists = artists;
          _hasMore = artists.length == 100;
      }
    } finally {
      if (generation == _requestGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    final generation = _requestGeneration;
    final view = _view;
    final currentQuery = _query;
    final trackSort = _sort;
    final albumSort = _albumSort;
    final artistSort = _artistSort;
    _loading = true;
    notifyListeners();
    try {
      switch (view) {
        case LocalLibraryView.songs:
          final next = await repository.listTracks(
              query: currentQuery,
              sort: trackSort,
              limit: 500,
              offset: _tracks.length);
          if (generation != _requestGeneration) return;
          _tracks = [..._tracks, ...next];
          _hasMore = next.length == 500;
        case LocalLibraryView.albums:
          final next = await repository.listAlbums(
              query: currentQuery,
              sort: albumSort,
              limit: 100,
              offset: _albums.length);
          if (generation != _requestGeneration) return;
          _albums = [..._albums, ...next];
          _hasMore = next.length == 100;
        case LocalLibraryView.artists:
          final next = await repository.listArtists(
              query: currentQuery,
              sort: artistSort,
              limit: 100,
              offset: _artists.length);
          if (generation != _requestGeneration) return;
          _artists = [..._artists, ...next];
          _hasMore = next.length == 100;
      }
    } finally {
      if (generation == _requestGeneration) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> setSort(LocalLibrarySortOrder sort) async {
    if (_sort == sort) return;
    _sort = sort;
    await reload();
  }

  Future<void> setAlbumSort(LocalAlbumSortOrder sort) async {
    if (_albumSort == sort) return;
    _albumSort = sort;
    await reload();
  }

  Future<void> setArtistSort(LocalArtistSortOrder sort) async {
    if (_artistSort == sort) return;
    _artistSort = sort;
    await reload();
  }

  Future<void> setView(LocalLibraryView view) async {
    if (_view == view) return;
    _view = view;
    await reload();
  }

  Future<List<LocalLibraryTrack>> tracksForAlbum(String albumKey) =>
      repository.listAlbumTracks(albumKey);

  Future<List<LocalLibraryTrack>> tracksForArtist(String artistKey) =>
      repository.listArtistTracks(artistKey);

  Future<List<LocalLibraryAlbum>> albumsForArtist(String artistKey) =>
      repository.listArtistAlbums(artistKey);

  Future<void> refreshArtist(String artistKey) async {
    final index =
        _artists.indexWhere((artist) => artist.artistKey == artistKey);
    if (index < 0) return;
    final refreshed = await repository.getArtist(artistKey);
    if (refreshed == null || _view != LocalLibraryView.artists) return;
    final currentIndex =
        _artists.indexWhere((artist) => artist.artistKey == artistKey);
    if (currentIndex < 0) return;
    _artists = [..._artists]..[currentIndex] = refreshed;
    notifyListeners();
  }

  Future<void> addRoot(String directoryPath) async {
    final normalized = path.normalize(Directory(directoryPath).absolute.path);
    if (_roots.any((root) =>
        path.equals(root.path, normalized) ||
        path.isWithin(root.path, normalized) ||
        path.isWithin(normalized, root.path))) {
      return;
    }
    final root = LocalLibraryRoot(
      id: _newRootId(),
      path: normalized,
      displayName: path.basename(normalized),
    );
    await repository.upsertRoot(root);
    await reload();
    await scanRoot(root.id);
  }

  Future<void> removeRoot(String rootId) async {
    scanner.cancel();
    final activeScan = _activeScan;
    if (activeScan != null) {
      await activeScan.catchError((Object _) {});
    }
    await repository.removeRoot(rootId);
    await reload();
  }

  Future<void> scanAll() async {
    if (_closed) return;
    for (final root in List<LocalLibraryRoot>.of(_roots)) {
      if (_closed) return;
      await scanRoot(root.id);
    }
  }

  Future<void> scanRoot(String rootId) async {
    if (_closed || isScanning) return;
    final root = _roots.where((item) => item.id == rootId).firstOrNull;
    if (root == null) return;
    _roots = [
      for (final item in _roots)
        if (item.id == rootId)
          item.copyWith(scanState: LocalLibraryScanState.scanning)
        else
          item,
    ];
    notifyListeners();
    final scanFuture = scanner.scan(root, onProgress: (progress) {
      _progress = progress;
      notifyListeners();
    });
    _activeScan = scanFuture;
    try {
      await scanFuture;
    } finally {
      if (identical(_activeScan, scanFuture)) _activeScan = null;
      _progress = null;
      await reload();
    }
  }

  void cancelScan() => scanner.cancel();

  Future<void> close() async {
    _closed = true;
    scanner.cancel();
    final activeScan = _activeScan;
    if (activeScan != null) {
      await activeScan.catchError((Object _) {});
    }
  }

  Future<void> restore(
    List<LocalLibraryRoot> roots,
    List<LocalLibraryTrack> tracks, {
    List<LocalArtistMetadata> artistMetadata = const [],
    List<LocalTrackMatch> trackMatches = const [],
  }) async {
    await repository.replaceAll(roots, tracks);
    for (final value in artistMetadata) {
      await repository.upsertArtistMetadata(value);
    }
    for (final value in trackMatches) {
      await repository.upsertLocalTrackMatch(value);
    }
    await reload();
  }
}

String _newRootId() =>
    'root_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
