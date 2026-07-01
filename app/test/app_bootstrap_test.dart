import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/bootstrap/app_bootstrap.dart';
import 'package:melo_union_app/src/bootstrap/demo_repository.dart';
import 'package:melo_union_app/src/bootstrap/managed_snapshot_store.dart';
import 'package:melo_union_app/src/bootstrap/netease_session_store.dart';
import 'package:melo_union_app/src/bootstrap/qq_music_session_store.dart';
import 'package:music_data/music_data.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:provider_netease/provider_netease.dart';
import 'package:provider_qq/provider_qq.dart';

final class _MemorySnapshotStore implements MeloSnapshotStore {
  _MemorySnapshotStore(this.snapshot);

  MeloDataSnapshot? snapshot;
  final writes = <MeloDataSnapshot>[];

  @override
  Future<MeloDataSnapshot?> read() async => snapshot;

  @override
  Future<void> write(MeloDataSnapshot snapshot) async {
    writes.add(snapshot);
    this.snapshot = snapshot;
  }

  @override
  Future<void> clear() async {
    snapshot = null;
  }
}

final class _MemoryNeteaseSessionStore implements NeteaseSessionStore {
  _MemoryNeteaseSessionStore([this.credentials]);

  NeteaseCredentials? credentials;

  @override
  Future<NeteaseCredentials?> read() async => credentials;

  @override
  Future<void> write(NeteaseCredentials credentials) async {
    this.credentials = credentials;
  }

  @override
  Future<void> clear() async {
    credentials = null;
  }
}

final class _MemoryQqMusicSessionStore implements QqMusicSessionStore {
  QqMusicCredentials? credentials;

  @override
  Future<QqMusicCredentials?> read() async => credentials;

  @override
  Future<void> write(QqMusicCredentials credentials) async {
    this.credentials = credentials;
  }

  @override
  Future<void> clear() async {
    credentials = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('createAppBootstrap hydrates repository from snapshot store', () async {
    final ref = ProviderTrackRef(
      providerId: ProviderId('aurora_stream'),
      trackId: 'alpha_midnight',
      extraIds: const {'album_id': 'aurora_001'},
    );
    var closed = false;
    final store = _MemorySnapshotStore(
      MeloDataSnapshot(
        playlists: [
          LocalPlaylist(
            id: 'playlist_bootstrap',
            name: 'Bootstrap State',
            items: [
              LocalPlaylistItem(
                trackRef: ref,
                cachedTitle: 'Midnight Signal',
                cachedArtists: const ['Luna Park'],
                cachedProviderName: 'Aurora Stream',
                addedAt: DateTime.utc(2026, 6, 29, 9),
              ),
            ],
          ),
        ],
      ),
    );

    final bootstrap = await createAppBootstrap(
      createStore: () async => ManagedSnapshotStore(
        store: store,
        close: () async {
          closed = true;
        },
      ),
    );

    expect(bootstrap.repository.playlistList.single.id, 'playlist_bootstrap');

    bootstrap.repository.createPlaylist('New Persisted Playlist');
    await Future<void>.delayed(Duration.zero);

    expect(
      store.writes.last.playlists.map((playlist) => playlist.name),
      contains('New Persisted Playlist'),
    );

    await bootstrap.close();

    expect(closed, isTrue);
  });

  test('createAppBootstrap injects NetEase credentials from session store',
      () async {
    final neteaseStore = _MemoryNeteaseSessionStore(
      const NeteaseCredentials(cookie: 'MUSIC_U=fake', userId: '42'),
    );

    final bootstrap = await createAppBootstrap(
      createStore: () async => ManagedSnapshotStore(store: null),
      createNeteaseStore: () => neteaseStore,
    );

    final entry = bootstrap.repository.registry.entryOf(neteaseProviderId);

    expect(entry, isNotNull);
    expect(entry!.provider.isAuthenticated, isTrue);
    expect(entry.descriptor.supports(ProviderCapability.authenticate), isTrue);
    expect(entry.descriptor.supports(ProviderCapability.readFavorites), isTrue);
  });

  test('DemoRepository can save and clear NetEase session credentials',
      () async {
    final neteaseStore = _MemoryNeteaseSessionStore();
    final repository = DemoRepository.seeded(
      neteaseSessionStore: neteaseStore,
    );

    expect(
      repository.registry
          .entryOf(neteaseProviderId)!
          .descriptor
          .supports(ProviderCapability.readFavorites),
      isFalse,
    );

    await repository.saveNeteaseCredentials(
      cookie: 'MUSIC_U=fake',
      userId: '42',
    );

    expect(neteaseStore.credentials?.cookie, 'MUSIC_U=fake');
    expect(repository.hasNeteaseSession, isTrue);
    expect(
      repository.registry
          .entryOf(neteaseProviderId)!
          .descriptor
          .supports(ProviderCapability.readFavorites),
      isTrue,
    );

    await repository.clearNeteaseCredentials();

    expect(neteaseStore.credentials, isNull);
    expect(repository.hasNeteaseSession, isFalse);
    expect(
      repository.registry
          .entryOf(neteaseProviderId)!
          .descriptor
          .supports(ProviderCapability.readFavorites),
      isFalse,
    );
  });

  test('DemoRepository validates and stores QQ Music cookie credentials',
      () async {
    final qqStore = _MemoryQqMusicSessionStore();
    final repository = DemoRepository.seeded(qqMusicSessionStore: qqStore);

    await expectLater(
      repository.saveQqMusicCredentials(
        const QqMusicCredentials(cookie: 'pgv_pvid=fake'),
      ),
      throwsArgumentError,
    );

    await repository.saveQqMusicCredentials(
      const QqMusicCredentials(cookie: 'uin=o12345; qqmusic_key=abc'),
    );

    expect(qqStore.credentials?.cookie, 'uin=o12345; qqmusic_key=abc');
    expect(repository.hasQqMusicSession, isTrue);
    expect(
      repository.registry.entryOf(qqMusicProviderId)!.provider.isAuthenticated,
      isTrue,
    );

    await repository.clearQqMusicCredentials();

    expect(qqStore.credentials, isNull);
    expect(repository.hasQqMusicSession, isFalse);
  });
}
