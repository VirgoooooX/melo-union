import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:melo_union_app/src/bootstrap/backup/account_vault_service.dart';
import 'package:melo_union_app/src/bootstrap/backup/backup_archive_service.dart';
import 'package:melo_union_app/src/bootstrap/backup/backup_coordinator.dart';
import 'package:melo_union_app/src/bootstrap/backup/backup_target.dart';
import 'package:melo_union_app/src/bootstrap/demo_repository.dart';
import 'package:melo_union_app/src/bootstrap/kugou_session_store.dart';
import 'package:melo_union_app/src/bootstrap/netease_session_store.dart';
import 'package:melo_union_app/src/bootstrap/qq_music_session_store.dart';
import 'package:music_data/music_data.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';
import 'package:provider_kugou/provider_kugou.dart';
import 'package:provider_netease/provider_netease.dart';
import 'package:provider_qq/provider_qq.dart';

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
  _MemoryQqMusicSessionStore([this.credentials]);

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
  _MemoryKugouSessionStore([this.session]);

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

  test('BackupArchiveService creates and reads zip snapshots', () {
    const service = BackupArchiveService();
    final ref = ProviderTrackRef(
      providerId: ProviderId('qq_music'),
      trackId: 'mid_001',
      extraIds: const {'song_id': '1001', 'song_mid': 'mid_001'},
    );
    final track = SourceTrack(
      ref: ref,
      title: '晴天',
      artists: const ['周杰伦'],
      duration: const Duration(minutes: 4, seconds: 29),
      isFavorited: true,
    );
    final ledger = LikedAtLedger()
      ..record(
        ref,
        LikedAtMetadata(
          likedAt: DateTime.utc(2026, 7, 7, 12),
          source: LikedAtMetadata.sourceLocalEstimate,
          precision: LikedAtMetadata.precisionUnknown,
        ),
      );
    final archive = service.createArchive(
      snapshot: MeloDataSnapshot(
        favoriteProviderSnapshots: [
          FavoriteSnapshot(providerId: ProviderId('qq_music'), tracks: [track]),
        ],
        favoriteLikedAtLedger: ledger,
        unifiedFavoritesCache: CachedUnifiedFavorites(
          builtAt: DateTime.utc(2026, 7, 7, 12, 1),
          tracks: [
            UnifiedFavoriteTrack(
              unifiedId: '0_qingtian',
              title: '晴天',
              artists: const ['周杰伦'],
              duration: const Duration(minutes: 4, seconds: 29),
              variants: [track],
            ),
          ],
        ),
      ),
      deviceName: 'test-device',
      platform: 'test',
      now: DateTime.utc(2026, 7, 7, 12, 2),
    );

    final payload = service.readArchive(archive);

    expect(payload.manifest.backupVersion, 1);
    expect(payload.manifest.includesAccountVault, isFalse);
    expect(
      payload.snapshot.favoriteProviderSnapshots.single.tracks.single.ref,
      ref,
    );
    expect(
      payload.snapshot.favoriteLikedAtLedger.likedAtFor(ref)?.likedAt,
      DateTime.utc(2026, 7, 7, 12),
    );
    expect(payload.snapshot.unifiedFavoritesCache?.tracks.single.title, '晴天');
  });

  test('BackupCoordinator names new backups as zip files', () {
    expect(
      BackupCoordinator.backupFileName(DateTime(2026, 7, 7, 12, 0, 0)),
      'melo-union-backup-20260707-120000.zip',
    );
  });

  test('AccountVaultService encrypts accounts and rejects wrong passwords',
      () async {
    final sourceNetease = _MemoryNeteaseSessionStore(
      const NeteaseCredentials(cookie: 'MUSIC_U=secret', userId: '42'),
    );
    final sourceQq = _MemoryQqMusicSessionStore(
      const QqMusicCredentials(cookie: 'uin=o12345; qqmusic_key=secret'),
    );
    final sourceKugou = _MemoryKugouSessionStore(
      const KugouSession(
        userId: '88',
        token: 'kg-secret-token',
        deviceId: 'device',
        mid: 'mid',
        deviceFingerprint: 'dfid',
      ),
    );
    final encrypted = await AccountVaultService(
      neteaseSessionStore: sourceNetease,
      qqMusicSessionStore: sourceQq,
      kugouSessionStore: sourceKugou,
    ).exportEncrypted('good-password');

    expect(encrypted, isNotNull);
    final envelopeText = utf8.decode(encrypted!);
    expect(envelopeText, isNot(contains('MUSIC_U=secret')));
    expect(envelopeText, isNot(contains('qqmusic_key=secret')));
    expect(envelopeText, isNot(contains('kg-secret-token')));

    final targetNetease = _MemoryNeteaseSessionStore(
      const NeteaseCredentials(cookie: 'MUSIC_U=existing'),
    );
    final targetQq = _MemoryQqMusicSessionStore();
    final targetKugou = _MemoryKugouSessionStore();
    final targetService = AccountVaultService(
      neteaseSessionStore: targetNetease,
      qqMusicSessionStore: targetQq,
      kugouSessionStore: targetKugou,
    );

    await expectLater(
      targetService.importEncrypted(encrypted, 'bad-password'),
      throwsA(isA<Exception>()),
    );
    expect(targetNetease.credentials?.cookie, 'MUSIC_U=existing');
    expect(targetQq.credentials, isNull);
    expect(targetKugou.session, isNull);

    await targetService.importEncrypted(encrypted, 'good-password');

    expect(targetNetease.credentials?.userId, '42');
    expect(targetQq.credentials?.cookie, contains('qqmusic_key=secret'));
    expect(targetKugou.session?.token, 'kg-secret-token');
  });

  test('AccountVaultService restores QQ cookies as replacement and normalizes',
      () async {
    final sourceQq = _MemoryQqMusicSessionStore(
      const QqMusicCredentials(cookie: 'uin=o12345; p_skey=fresh'),
    );
    final encrypted = await AccountVaultService(
      neteaseSessionStore: const NullNeteaseSessionStore(),
      qqMusicSessionStore: sourceQq,
      kugouSessionStore: const NullKugouSessionStore(),
    ).exportEncrypted('good-password');

    final targetNetease = _MemoryNeteaseSessionStore(
      const NeteaseCredentials(cookie: 'MUSIC_U=old'),
    );
    final targetQq = _MemoryQqMusicSessionStore(
      const QqMusicCredentials(cookie: 'uin=o99999; qqmusic_key=stale'),
    );
    final targetKugou = _MemoryKugouSessionStore(
      const KugouSession(
        userId: '88',
        token: 'old-token',
        deviceId: 'device',
        mid: 'mid',
        deviceFingerprint: 'dfid',
      ),
    );

    await AccountVaultService(
      neteaseSessionStore: targetNetease,
      qqMusicSessionStore: targetQq,
      kugouSessionStore: targetKugou,
    ).importEncrypted(encrypted!, 'good-password');

    expect(targetNetease.credentials, isNull);
    expect(targetKugou.session, isNull);
    expect(targetQq.credentials?.cookie, contains('uin=o12345'));
    expect(targetQq.credentials?.cookie, contains('p_skey=fresh'));
    expect(targetQq.credentials?.cookie, contains('qqmusic_key=fresh'));
    expect(targetQq.credentials?.cookie, contains('qm_keyst=fresh'));
    expect(targetQq.credentials?.cookie, isNot(contains('stale')));
  });

  test('DemoRepository restores unified favorites cache without restart',
      () async {
    final ref = ProviderTrackRef(
      providerId: ProviderId('qq_music'),
      trackId: 'mid_001',
      extraIds: const {'song_id': '1001', 'song_mid': 'mid_001'},
    );
    final track = SourceTrack(
      ref: ref,
      title: '晴天',
      artists: const ['周杰伦'],
      duration: const Duration(minutes: 4, seconds: 29),
      isFavorited: true,
    );
    final repository = DemoRepository.seeded();

    await repository.restoreFromSnapshot(
      MeloDataSnapshot(
        unifiedFavoritesCache: CachedUnifiedFavorites(
          builtAt: DateTime.utc(2026, 7, 7, 12),
          tracks: [
            UnifiedFavoriteTrack(
              unifiedId: '0_qingtian',
              title: '晴天',
              artists: const ['周杰伦'],
              duration: const Duration(minutes: 4, seconds: 29),
              variants: [track],
            ),
          ],
        ),
      ),
    );

    expect(repository.lastFavoritesData?.single.title, '晴天');
    expect(repository.sourceTrackByRef(ref)?.title, '晴天');
  });

  test('BackupCoordinator creates a pre-restore backup before data restore',
      () async {
    final dir = await Directory.systemTemp.createTemp('melo_backup_test_');
    addTearDown(() => dir.delete(recursive: true));
    final repository = DemoRepository.seeded(
      snapshot: MeloDataSnapshot(
        playlists: [LocalPlaylist(id: 'before', name: 'Before')],
      ),
    );
    final coordinator = BackupCoordinator(
      repository: repository,
      preRestoreDirectory: dir,
      now: () => DateTime.utc(2026, 7, 7, 12),
      accountVaultService: AccountVaultService(
        neteaseSessionStore: const NullNeteaseSessionStore(),
        qqMusicSessionStore: const NullQqMusicSessionStore(),
        kugouSessionStore: const NullKugouSessionStore(),
      ),
    );
    final archive = const BackupArchiveService().createArchive(
      snapshot: MeloDataSnapshot(
        playlists: [LocalPlaylist(id: 'after', name: 'After')],
      ),
      deviceName: 'test',
      platform: 'test',
      now: DateTime.utc(2026, 7, 7, 12, 1),
    );

    final result = await coordinator.restoreFromBackupBytes(
      bytes: Uint8List.fromList(archive),
      mode: BackupRestoreMode.dataOnly,
    );

    expect(result.preRestoreBackupPath, isNotNull);
    expect(File(result.preRestoreBackupPath!).existsSync(), isTrue);
    expect(repository.playlistList.single.name, 'After');
  });

  test('BackupCoordinator reloads providers after restoring Kugou account',
      () async {
    final sourceKugou = _MemoryKugouSessionStore(
      const KugouSession(
        userId: '88',
        token: 'kg-secret-token',
        deviceId: 'device',
        mid: 'mid',
        deviceFingerprint: 'dfid',
      ),
    );
    final accountVaultBytes = await AccountVaultService(
      neteaseSessionStore: const NullNeteaseSessionStore(),
      qqMusicSessionStore: const NullQqMusicSessionStore(),
      kugouSessionStore: sourceKugou,
    ).exportEncrypted('good-password');
    final archive = const BackupArchiveService().createArchive(
      snapshot: MeloDataSnapshot(),
      deviceName: 'desktop',
      platform: 'windows',
      accountVaultBytes: accountVaultBytes,
      now: DateTime.utc(2026, 7, 7, 12),
    );

    final targetKugou = _MemoryKugouSessionStore();
    final repository = DemoRepository.seeded(kugouSessionStore: targetKugou);
    final coordinator = BackupCoordinator(
      repository: repository,
      accountVaultService: AccountVaultService(
        neteaseSessionStore: const NullNeteaseSessionStore(),
        qqMusicSessionStore: const NullQqMusicSessionStore(),
        kugouSessionStore: targetKugou,
      ),
    );

    expect(repository.hasKugouSession, isFalse);

    await coordinator.restoreFromBackupBytes(
      bytes: archive,
      mode: BackupRestoreMode.accountsOnly,
      accountPassword: 'good-password',
    );

    expect(targetKugou.session?.token, 'kg-secret-token');
    expect(repository.hasKugouSession, isTrue);
  });

  test('WebDavBackupTarget covers list upload download and delete', () async {
    final methods = <String>[];
    final target = WebDavBackupTarget(
      config: WebDavConfig(
        baseUri: Uri.parse('https://dav.example.test/root/'),
        username: 'user',
        password: 'pass',
        remoteDirectory: '/MeloUnion/backups/',
      ),
      client: MockClient((request) async {
        methods.add('${request.method} ${request.url.path}');
        if (request.method == 'MKCOL') {
          return http.Response('', 405);
        }
        if (request.method == 'PROPFIND') {
          return http.Response(
            '''
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/root/MeloUnion/backups/</d:href>
    <d:propstat><d:prop><d:resourcetype><d:collection /></d:resourcetype></d:prop></d:propstat>
  </d:response>
  <d:response>
    <d:href>/root/MeloUnion/backups/melo-union-backup-20260707-120000.zip</d:href>
    <d:propstat><d:prop>
      <d:getcontentlength>12</d:getcontentlength>
      <d:getlastmodified>Tue, 07 Jul 2026 12:00:00 GMT</d:getlastmodified>
    </d:prop></d:propstat>
  </d:response>
</d:multistatus>
''',
            207,
          );
        }
        if (request.method == 'PUT') {
          return http.Response('', 201);
        }
        if (request.method == 'GET') {
          return http.Response.bytes([1, 2, 3], 200);
        }
        if (request.method == 'DELETE') {
          return http.Response('', 204);
        }
        return http.Response('unexpected', 500);
      }),
    );

    final entries = await target.listBackups();
    await target.uploadBackup(
        'melo-union-backup-20260707-120000.zip', Uint8List.fromList([1, 2, 3]));
    final bytes = await target.downloadBackup(entries.single.path);
    await target.deleteBackup(entries.single.path);

    expect(entries.single.name, 'melo-union-backup-20260707-120000.zip');
    expect(entries.single.size, 12);
    expect(bytes, [1, 2, 3]);
    expect(methods, contains(startsWith('PROPFIND ')));
    expect(methods, contains(startsWith('PUT ')));
    expect(methods, contains(startsWith('GET ')));
    expect(methods, contains(startsWith('DELETE ')));
  });

  test('WebDavBackupTarget still lists legacy melobak backups', () async {
    final target = WebDavBackupTarget(
      config: WebDavConfig(
        baseUri: Uri.parse('https://dav.example.test/root/'),
        username: 'user',
        password: 'pass',
        remoteDirectory: '/MeloUnion/backups/',
      ),
      client: MockClient((request) async {
        if (request.method == 'MKCOL') {
          return http.Response('', 405);
        }
        if (request.method == 'PROPFIND') {
          return http.Response(
            '''
<d:multistatus xmlns:d="DAV:">
  <d:response>
    <d:href>/root/MeloUnion/backups/melo-union-backup-20260707-120000.melobak</d:href>
    <d:propstat><d:prop>
      <d:getcontentlength>12</d:getcontentlength>
      <d:getlastmodified>Tue, 07 Jul 2026 12:00:00 GMT</d:getlastmodified>
    </d:prop></d:propstat>
  </d:response>
</d:multistatus>
''',
            207,
          );
        }
        return http.Response('unexpected', 500);
      }),
    );

    final entries = await target.listBackups();

    expect(entries.single.name, 'melo-union-backup-20260707-120000.melobak');
  });
}
