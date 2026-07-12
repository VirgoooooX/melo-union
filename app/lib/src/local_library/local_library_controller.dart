import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:music_domain/music_domain.dart';
import 'package:path/path.dart' as path;

import 'local_library_scanner.dart';

final class LocalLibraryController extends ChangeNotifier {
  LocalLibraryController({required this.repository, required this.scanner});

  final LocalLibraryRepository repository;
  final LocalLibraryScanner scanner;

  List<LocalLibraryRoot> _roots = const [];
  List<LocalLibraryTrack> _tracks = const [];
  LocalLibraryScanProgress? _progress;
  bool _loading = false;
  bool _hasMore = false;
  String _query = '';
  LocalLibrarySortOrder _sort = LocalLibrarySortOrder.album;
  // 删除目录前等待扫描退出，避免扫描结果重新写回。
  Future<void>? _activeScan;

  List<LocalLibraryRoot> get roots => _roots;
  List<LocalLibraryTrack> get tracks => _tracks;
  LocalLibraryScanProgress? get progress => _progress;
  bool get isLoading => _loading;
  bool get isScanning => _roots.any(
        (root) => root.scanState == LocalLibraryScanState.scanning,
      );
  String get query => _query;
  LocalLibrarySortOrder get sort => _sort;
  bool get hasMore => _hasMore;

  Future<void> initialize({bool scanOnStartup = true}) async {
    await reload();
    if (scanOnStartup && _roots.isNotEmpty) {
      await scanAll();
    }
  }

  Future<void> reload({String? query}) async {
    if (query != null) _query = query;
    _loading = true;
    notifyListeners();
    try {
      _roots = await repository.listRoots();
      _tracks = await repository.listTracks(
        query: _query,
        sort: _sort,
        limit: 500,
      );
      _hasMore = _tracks.length == 500;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_loading || !_hasMore) return;
    _loading = true;
    notifyListeners();
    try {
      final next = await repository.listTracks(
        query: _query,
        sort: _sort,
        limit: 500,
        offset: _tracks.length,
      );
      _tracks = [..._tracks, ...next];
      _hasMore = next.length == 500;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setSort(LocalLibrarySortOrder sort) async {
    if (_sort == sort) return;
    _sort = sort;
    await reload();
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
    for (final root in List<LocalLibraryRoot>.of(_roots)) {
      await scanRoot(root.id);
    }
  }

  Future<void> scanRoot(String rootId) async {
    if (isScanning) return;
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

  Future<void> restore(
    List<LocalLibraryRoot> roots,
    List<LocalLibraryTrack> tracks,
  ) async {
    await repository.replaceAll(roots, tracks);
    await reload();
  }
}

String _newRootId() =>
    'root_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
