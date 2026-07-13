import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/local_library/local_library_controller.dart';
import 'package:melo_union_app/src/local_library/local_library_scanner.dart';
import 'package:music_domain/music_domain.dart';

void main() {
  late Directory temp;
  late _ControlledRepository repository;
  late LocalLibraryController controller;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('local_controller_test_');
    repository = _ControlledRepository();
    controller = LocalLibraryController(
      repository: repository,
      scanner: LocalLibraryScanner(
        repository: repository,
        artworkDirectory: Directory('${temp.path}/artwork'),
      ),
    );
  });

  tearDown(() async {
    controller.dispose();
    await temp.delete(recursive: true);
  });

  test('new reload owns loading and results when an old reload finishes first',
      () async {
    // Given: an initialized album page with another page available.
    await _initializeAlbums(controller, repository, _albums('initial', 100));

    // When: two reloads overlap and the stale request completes first.
    final oldRequestFuture = repository.nextAlbumRequest();
    final oldReload = controller.reload(query: 'old');
    final oldRequest = await oldRequestFuture;
    final newRequestFuture = repository.nextAlbumRequest();
    final newReload = controller.reload(query: 'new');
    final newRequest = await newRequestFuture;
    oldRequest.complete(_albums('old', 1));
    await oldReload;

    // Then: the newer request still owns loading and visible data.
    expect(controller.isLoading, isTrue);
    expect(controller.albums.first.title, 'initial-0');

    newRequest.complete(_albums('new', 1));
    await newReload;
    expect(controller.isLoading, isFalse);
    expect(controller.albums.single.title, 'new-0');
    expect(controller.hasMore, isFalse);
  });

  test('reload invalidates an older loadMore completion', () async {
    // Given: a full first album page.
    await _initializeAlbums(controller, repository, _albums('initial', 100));

    // When: loadMore remains pending while a fresh search reload completes.
    final pageRequestFuture = repository.nextAlbumRequest();
    final pageFuture = controller.loadMore();
    final pageRequest = await pageRequestFuture;
    expect(pageRequest.offset, 100);
    final reloadRequestFuture = repository.nextAlbumRequest();
    final reloadFuture = controller.reload(query: 'fresh');
    final reloadRequest = await reloadRequestFuture;
    reloadRequest.complete(_albums('fresh', 1));
    await reloadFuture;
    pageRequest.complete(_albums('stale-page', 100));
    await pageFuture;

    // Then: the stale page cannot append or change hasMore.
    expect(controller.albums, hasLength(1));
    expect(controller.albums.single.title, 'fresh-0');
    expect(controller.hasMore, isFalse);
    expect(controller.isLoading, isFalse);
  });

  test('concurrent loadMore calls issue only one page request', () async {
    // Given: a full first album page.
    await _initializeAlbums(controller, repository, _albums('initial', 100));

    // When: two callers request the next page before it completes.
    final requestFuture = repository.nextAlbumRequest();
    final first = controller.loadMore();
    final second = controller.loadMore();
    final request = await requestFuture;
    request.complete(_albums('next', 1));
    await Future.wait([first, second]);

    // Then: only one offset page was fetched and appended once.
    expect(repository.albumRequestCount, 2);
    expect(controller.albums, hasLength(101));
    expect(controller.albums.last.title, 'next-0');
  });
}

Future<void> _initializeAlbums(
  LocalLibraryController controller,
  _ControlledRepository repository,
  List<LocalLibraryAlbum> albums,
) async {
  final requestFuture = repository.nextAlbumRequest();
  final viewFuture = controller.setView(LocalLibraryView.albums);
  final request = await requestFuture;
  request.complete(albums);
  await viewFuture;
}

List<LocalLibraryAlbum> _albums(String prefix, int count) => [
      for (var index = 0; index < count; index++)
        LocalLibraryAlbum(
          albumKey: '$prefix-$index',
          title: '$prefix-$index',
          albumArtist: 'Artist',
          trackCount: 1,
          duration: const Duration(minutes: 3),
        ),
    ];

final class _AlbumRequest {
  _AlbumRequest({required this.query, required this.offset});

  final String query;
  final int offset;
  final Completer<List<LocalLibraryAlbum>> _completer = Completer();

  void complete(List<LocalLibraryAlbum> albums) => _completer.complete(albums);
}

final class _ControlledRepository implements LocalLibraryRepository {
  final List<_AlbumRequest> _pendingRequests = [];
  Completer<_AlbumRequest>? _requestWaiter;
  int albumRequestCount = 0;

  Future<_AlbumRequest> nextAlbumRequest() {
    if (_pendingRequests.isNotEmpty) {
      return Future.value(_pendingRequests.removeAt(0));
    }
    final waiter = Completer<_AlbumRequest>();
    _requestWaiter = waiter;
    return waiter.future;
  }

  @override
  Future<List<LocalLibraryAlbum>> listAlbums({
    String query = '',
    LocalAlbumSortOrder sort = LocalAlbumSortOrder.artist,
    int limit = 100,
    int offset = 0,
  }) {
    albumRequestCount++;
    final request = _AlbumRequest(query: query, offset: offset);
    final waiter = _requestWaiter;
    if (waiter == null) {
      _pendingRequests.add(request);
    } else {
      _requestWaiter = null;
      waiter.complete(request);
    }
    return request._completer.future;
  }

  @override
  Future<List<LocalLibraryRoot>> listRoots() async => const [];

  @override
  Future<LocalLibraryStats> getStats() async => const LocalLibraryStats(
        trackCount: 0,
        albumCount: 0,
        artistCount: 0,
      );

  @override
  Future<List<LocalLibraryTrack>> listTracks({
    String query = '',
    LocalLibrarySortOrder sort = LocalLibrarySortOrder.album,
    int limit = 200,
    int offset = 0,
  }) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
