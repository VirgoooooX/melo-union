import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/bootstrap/app_bootstrap.dart';
import 'package:melo_union_app/src/bootstrap/demo_repository.dart';
import 'package:melo_union_app/src/bootstrap/managed_snapshot_store.dart';
import 'package:melo_union_app/src/bootstrap/kugou_session_store.dart';
import 'package:melo_union_app/src/bootstrap/netease_session_store.dart';
import 'package:melo_union_app/src/bootstrap/qq_music_session_store.dart';
import 'package:music_data/music_data.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:provider_kugou/provider_kugou.dart';
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

final class _FailingSnapshotStore implements MeloSnapshotStore {
  var clearCalls = 0;
  var writeCalls = 0;

  @override
  Future<MeloDataSnapshot?> read() async {
    throw StateError('corrupt snapshot');
  }

  @override
  Future<void> write(MeloDataSnapshot snapshot) async {
    writeCalls++;
  }

  @override
  Future<void> clear() async {
    clearCalls++;
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

final class _MemoryKugouSessionStore implements KugouSessionStore {
  KugouSession? session;

  @override
  Future<KugouSession?> read() async => session;

  @override
  Future<void> write(KugouSession session) async {
    this.session = session;
  }

  @override
  Future<void> clear() async {
    session = null;
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

  test('read failure preserves the database and disables fallback writes',
      () async {
    final store = _FailingSnapshotStore();
    final bootstrap = await createAppBootstrap(
      createStore: () async => ManagedSnapshotStore(store: store),
    );

    expect(store.clearCalls, 0);
    expect(bootstrap.repository.snapshotStore, isNull);

    bootstrap.repository.createPlaylist('Recovery Session Playlist');
    await Future<void>.delayed(Duration.zero);

    expect(store.writeCalls, 0);
    await bootstrap.close();
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
    final qqRef = ProviderTrackRef(
      providerId: qqMusicProviderId,
      trackId: 'qq_mid_001',
      extraIds: const {
        'song_id': '123456',
        'song_mid': 'qq_mid_001',
      },
    );
    final likedAt = DateTime.utc(2026, 7, 5, 8, 30);
    repository.favoriteLikedAtLedger.record(
      qqRef,
      LikedAtMetadata(
        likedAt: likedAt,
        source: LikedAtMetadata.sourceQqImport,
        precision: LikedAtMetadata.precisionUnknown,
      ),
    );

    await expectLater(
      repository.saveQqMusicCredentials(
        const QqMusicCredentials(cookie: 'pgv_pvid=fake'),
      ),
      throwsArgumentError,
    );

    await repository.saveQqMusicCredentials(
      const QqMusicCredentials(cookie: 'uin=o12345; p_skey=abc'),
    );

    expect(qqStore.credentials?.cookie, contains('p_skey=abc'));
    expect(qqStore.credentials?.cookie, contains('qqmusic_key=abc'));
    expect(qqStore.credentials?.cookie, contains('qm_keyst=abc'));
    expect(repository.hasQqMusicSession, isTrue);
    expect(
      repository.registry.entryOf(qqMusicProviderId)!.provider.isAuthenticated,
      isTrue,
    );
    expect(
      repository.favoriteLikedAtLedger.likedAtFor(qqRef)?.likedAt,
      likedAt,
    );

    await repository.clearQqMusicCredentials();

    expect(qqStore.credentials, isNull);
    expect(repository.hasQqMusicSession, isFalse);
    expect(
      repository.favoriteLikedAtLedger.likedAtFor(qqRef)?.likedAt,
      likedAt,
    );
  });

  test('DemoRepository validates and stores Kugou cookie session', () async {
    final kugouStore = _MemoryKugouSessionStore();
    final repository = DemoRepository.seeded(kugouSessionStore: kugouStore);

    await expectLater(
      repository.saveKugouCookieSession(
        cookie: 'KuGooToken=token; kg_mid=mid; kg_dfid=dfid',
      ),
      throwsArgumentError,
    );

    await repository.saveKugouCookieSession(
      cookie:
          'KugooID=12345; KuGoo=KugooID=12345&KugooPwd=token; mid=mid; kg_dfid_collect=dfid; vip_type=1',
    );

    expect(kugouStore.session?.userId, '12345');
    expect(kugouStore.session?.token, 'token');
    expect(kugouStore.session?.mid, 'mid');
    expect(kugouStore.session?.deviceFingerprint, 'dfid');
    expect(kugouStore.session?.vipType, '1');
    expect(
      kugouStore.session?.refreshMetadata?['cookie'],
      'KugooID=12345; KuGoo=KugooID=12345&KugooPwd=token; mid=mid; kg_dfid_collect=dfid; vip_type=1',
    );
    expect(repository.hasKugouSession, isTrue);
    expect(
      repository.registry.entryOf(kugouProviderId)!.provider.isAuthenticated,
      isTrue,
    );
  });
}
