import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/features/local_library/local_library_views.dart';
import 'package:melo_union_app/src/local_library/local_library_controller.dart';
import 'package:melo_union_app/src/local_library/local_library_scanner.dart';
import 'package:music_data/music_data_drift.dart';
import 'package:music_domain/music_domain.dart';

class _LocalLibraryHistoryEntry {
  final LocalLibraryAlbum? album;
  final LocalLibraryArtist? artist;
  _LocalLibraryHistoryEntry({this.album, this.artist});
}

class LocalLibraryTestWrapper extends StatefulWidget {
  const LocalLibraryTestWrapper({
    super.key,
    required this.controller,
    required this.view,
  });
  final LocalLibraryController controller;
  final LocalLibraryView view;

  @override
  State<LocalLibraryTestWrapper> createState() => _LocalLibraryTestWrapperState();
}

class _LocalLibraryTestWrapperState extends State<LocalLibraryTestWrapper> {
  final List<_LocalLibraryHistoryEntry> _navigationHistory = [];

  void _popHistory() {
    setState(() {
      if (_navigationHistory.isNotEmpty) {
        _navigationHistory.removeLast();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_navigationHistory.isNotEmpty) {
      final top = _navigationHistory.last;
      if (top.album != null) {
        return LocalAlbumDetailView(
          controller: widget.controller,
          album: top.album!,
          onBack: _popHistory,
        );
      } else {
        return LocalArtistDetailView(
          controller: widget.controller,
          artist: top.artist!,
          onBack: _popHistory,
          onAlbumTap: (album) {
            setState(() {
              _navigationHistory.add(_LocalLibraryHistoryEntry(album: album));
            });
          },
        );
      }
    }

    if (widget.view == LocalLibraryView.albums) {
      return LocalAlbumsView(
        controller: widget.controller,
        onAlbumTap: (album) {
          setState(() {
            _navigationHistory.add(_LocalLibraryHistoryEntry(album: album));
          });
        },
      );
    } else {
      return LocalArtistsView(
        controller: widget.controller,
        onArtistTap: (artist) {
          setState(() {
            _navigationHistory.add(_LocalLibraryHistoryEntry(artist: artist));
          });
        },
      );
    }
  }
}

void main() {
  late Directory temp;
  late MeloDriftDatabase database;
  late DriftLocalLibraryRepository repository;
  late LocalLibraryController controller;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('melo_library_views_test_');
    database = MeloDriftDatabase(NativeDatabase.memory());
    repository = DriftLocalLibraryRepository(database);
    controller = LocalLibraryController(
      repository: repository,
      scanner: LocalLibraryScanner(
        repository: repository,
        artworkDirectory: Directory('${temp.path}/artwork'),
      ),
    );
    await repository.upsertRoot(LocalLibraryRoot(
      id: 'root',
      path: temp.path,
      displayName: 'Test',
    ));
  });

  tearDown(() async {
    controller.dispose();
    await database.close();
    await temp.delete(recursive: true);
  });

  testWidgets('album conflict is subtle on card and explicit in details',
      (tester) async {
    await repository.upsertTracks([
      _track('canonical-1', title: '标准年份一', year: 2020),
      _track('canonical-2', title: '标准年份二', year: 2020),
      _track('different', title: '年份异常', year: 2019),
      _track('unknown', title: '年份缺失'),
    ]);
    await controller.initialize(scanOnStartup: false);
    await controller.setView(LocalLibraryView.albums);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: LocalLibraryTestWrapper(
            controller: controller,
            view: LocalLibraryView.albums,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('2020'), findsOneWidget);
    expect(find.byTooltip('年份标签存在差异'), findsOneWidget);

    await tester.tap(find.text('测试专辑'));
    await tester.pumpAndSettle();

    expect(find.textContaining('检测到的年份：2019、2020'), findsOneWidget);
    expect(find.textContaining('年份异常（2019）'), findsOneWidget);
    expect(find.textContaining('年份缺失（未知年份）'), findsOneWidget);
  });

  test('loaded artist and album pages survive refreshes and rebuild state',
      () async {
    await repository.upsertTracks([
      for (var index = 0; index < 101; index++)
        _track(
          '$index',
          title: '歌曲 $index',
          artist: '歌手 $index',
          album: '专辑 $index',
        ),
    ]);
    await controller.initialize(scanOnStartup: false);

    await controller.setView(LocalLibraryView.artists);
    await controller.loadMore();
    expect(controller.artists, hasLength(101));
    final firstArtist = controller.artists.first;
    await repository.upsertArtistMetadata(LocalArtistMetadata(
      artistKey: firstArtist.artistKey,
      displayName: firstArtist.displayName,
      status: ArtistMetadataStatus.matched,
      avatarUrl: 'https://example.test/avatar.jpg',
    ));
    await controller.refreshArtist(firstArtist.artistKey);
    expect(controller.artists, hasLength(101));
    expect(controller.artists.first.metadata?.avatarUrl,
        'https://example.test/avatar.jpg');

    await controller.setView(LocalLibraryView.albums);
    await controller.loadMore();
    expect(controller.albums, hasLength(101));
    expect(controller.albums.last.title, isNotEmpty);
  });

  testWidgets('album grid loads its next page from a real bottom scroll',
      (tester) async {
    // Given: one album beyond the 100-card first page.
    await repository.upsertTracks([
      for (var index = 0; index < 101; index++)
        _track(
          'album-scroll-$index',
          title: '歌曲 $index',
          album: '专辑 $index',
        ),
    ]);
    await controller.initialize(scanOnStartup: false);
    await controller.setView(LocalLibraryView.albums);
    expect(controller.albums, hasLength(100));

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: controller,
            builder: (_, __) => LocalAlbumsView(
              controller: controller,
              onAlbumTap: (_) {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // When: the real grid scrollable reaches its pagination threshold.
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -10000),
    );
    await tester.pumpAndSettle();

    // Then: the final album is appended automatically with no manual control.
    expect(controller.albums, hasLength(101));
    expect(find.text('加载更多'), findsNothing);
    await tester.scrollUntilVisible(
      find.text(controller.albums.last.title),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text(controller.albums.last.title), findsOneWidget);
  });

  testWidgets('artist bottom scroll and metadata refresh retain the deep page',
      (tester) async {
    // Given: an artist grid with a second page.
    await repository.upsertTracks([
      for (var index = 0; index < 101; index++)
        _track(
          'artist-scroll-$index',
          title: '歌曲 $index',
          artist: '歌手 $index',
          album: '专辑 $index',
        ),
    ]);
    await controller.initialize(scanOnStartup: false);
    await controller.setView(LocalLibraryView.artists);
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: controller,
            builder: (_, __) => LocalArtistsView(
              controller: controller,
              onArtistTap: (_) {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // When: the real grid reaches bottom and metadata refresh rebuilds it.
    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -10000),
    );
    await tester.pumpAndSettle();
    expect(controller.artists, hasLength(101));
    final deepArtist = controller.artists.last;
    await tester.scrollUntilVisible(
      find.text(deepArtist.displayName),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final scrollable =
        tester.state<ScrollableState>(find.byType(Scrollable).first);
    final offsetBeforeRefresh = scrollable.position.pixels;
    final refreshedArtist = controller.artists.first;
    await repository.upsertArtistMetadata(LocalArtistMetadata(
      artistKey: refreshedArtist.artistKey,
      displayName: refreshedArtist.displayName,
      status: ArtistMetadataStatus.matched,
      avatarUrl: 'https://example.test/refreshed.jpg',
    ));
    await controller.refreshArtist(refreshedArtist.artistKey);
    await tester.pumpAndSettle();

    // Then: loaded count, scroll position, and the visible deep item survive.
    expect(controller.artists, hasLength(101));
    expect(scrollable.position.pixels, closeTo(offsetBeforeRefresh, 0.1));
    expect(find.text(deepArtist.displayName), findsOneWidget);
    expect(find.text('加载更多'), findsNothing);
  });

  testWidgets('artist details keep track performers under the owning artist',
      (tester) async {
    await repository.upsertTracks([
      _track(
        'collaboration',
        title: '千里之外',
        artist: '周杰伦',
        trackArtists: const ['周杰伦', '费玉清'],
        album: '依然范特西',
      ),
    ]);
    await controller.initialize(scanOnStartup: false);
    await controller.setView(LocalLibraryView.artists);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: LocalLibraryTestWrapper(
            controller: controller,
            view: LocalLibraryView.artists,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('周杰伦'));
    await tester.pumpAndSettle();

    expect(find.text('专辑'), findsWidgets);
    expect(find.text('全部歌曲'), findsOneWidget);
    expect(find.textContaining('费玉清'), findsOneWidget);
    expect(find.textContaining('Album Artist'), findsNothing);
    expect(find.textContaining('Library Artist'), findsNothing);
  });

  testWidgets('album details disclose tracks with missing years',
      (tester) async {
    await repository.upsertTracks([
      _track('known', title: '有年份', year: 2006),
      _track('missing', title: '无年份'),
    ]);
    await controller.initialize(scanOnStartup: false);
    await controller.setView(LocalLibraryView.albums);
    expect(controller.albums.single.hasYearConflict, isTrue);

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: LocalLibraryTestWrapper(
            controller: controller,
            view: LocalLibraryView.albums,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('测试专辑'));
    await tester.pumpAndSettle();

    expect(find.textContaining('无年份（未知年份）'), findsOneWidget);
  });

  testWidgets('album without any year uses the unknown-year label',
      (tester) async {
    await repository.upsertTracks([
      _track('unknown-only', title: '未标年份'),
    ]);
    await controller.initialize(scanOnStartup: false);
    await controller.setView(LocalLibraryView.albums);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LocalAlbumsView(
          controller: controller,
          onAlbumTap: (_) {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('未知年份'), findsOneWidget);
  });
}

LocalLibraryTrack _track(
  String id, {
  required String title,
  String artist = '测试歌手',
  List<String>? trackArtists,
  String album = '测试专辑',
  int? year,
}) =>
    LocalLibraryTrack(
      id: id,
      rootId: 'root',
      filePath: 'C:/Music/$id.flac',
      relativePath: '$id.flac',
      fileSize: 1,
      modifiedAt: DateTime.utc(2026, 7, 13),
      fingerprint: 'fingerprint-$id',
      title: title,
      artists: trackArtists ?? [artist],
      duration: const Duration(minutes: 3),
      format: 'FLAC',
      album: album,
      albumArtist: artist,
      albumArtistSource: LocalAlbumArtistSource.embeddedTag,
      year: year,
    );
