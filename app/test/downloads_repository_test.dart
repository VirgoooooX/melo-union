import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:melo_union_app/src/bootstrap/demo_repository.dart';
import 'package:melo_union_app/src/fakes/fake_music_provider.dart';
import 'package:music_data/music_data.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

final class _RecordingSnapshotStore implements MeloSnapshotStore {
  final writes = <MeloDataSnapshot>[];

  @override
  Future<MeloDataSnapshot?> read() async => null;

  @override
  Future<void> write(MeloDataSnapshot snapshot) async {
    writes.add(snapshot);
  }

  @override
  Future<void> clear() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DemoRepository removes and redownloads local media entries', () async {
    final ref = ProviderTrackRef(
      providerId: ProviderId('aurora_stream'),
      trackId: 'alpha_midnight',
      extraIds: const {'album_id': 'aurora_001'},
    );
    final localItem = LocalMediaItem(
      sourceRef: ref,
      title: 'Midnight Signal',
      artists: const ['Luna Park'],
      duration: const Duration(minutes: 3, seconds: 10),
      filePath: 'local://downloads/aurora_stream/alpha_midnight.mp3',
      fileSize: 4096,
      downloadedAt: DateTime.utc(2026, 6, 29),
    );
    final track = SourceTrack(
      ref: ref,
      title: 'Midnight Signal',
      artists: const ['Luna Park'],
      duration: const Duration(minutes: 3, seconds: 10),
      isFavorited: true,
      isDownloadable: true,
    );
    final alphaId = ProviderId('aurora_stream');
    final alpha = FakeMusicProvider(
      descriptor: ProviderDescriptor(
        id: alphaId,
        displayName: 'Aurora Stream',
        capabilities: const {
          ProviderCapability.resolveDownload,
        },
      ),
      profile: null,
      seedTracks: [
        SourceTrack(
          ref: ref,
          title: 'Midnight Signal',
          artists: const ['Luna Park'],
          duration: const Duration(minutes: 3, seconds: 10),
          isFavorited: true,
          isDownloadable: true,
        ),
      ],
    );

    final repository = DemoRepository.seeded(
      additionalProviders: [alpha],
      snapshot: MeloDataSnapshot(
        downloadTasks: [
          DownloadTask(
            track: track,
            quality: AudioQuality.standard,
            status: DownloadStatus.completed,
            progress: 1,
            savedFilePath: localItem.filePath,
          ),
        ],
        localMediaItems: [localItem],
      ),
    );

    repository.removeLocalMedia(ref);

    expect(repository.downloadCoordinator.isAvailableLocally(ref), isFalse);
    expect(repository.downloadCoordinator.getTask(ref)?.status,
        DownloadStatus.cancelled);

    final redownload = repository.redownloadLocalMedia(ref);

    expect(repository.downloadCoordinator.isAvailableLocally(ref), isFalse);
    expect(
      repository.downloadCoordinator.getTask(ref)?.status,
      isNot(DownloadStatus.queued),
    );
    await redownload;
    expect(
      repository.downloadCoordinator.getTask(ref)?.status,
      isNot(DownloadStatus.queued),
    );
  });

  test('DemoRepository persists download and local media mutations', () async {
    final ref = ProviderTrackRef(
      providerId: ProviderId('aurora_stream'),
      trackId: 'alpha_midnight',
      extraIds: const {'album_id': 'aurora_001'},
    );
    final localItem = LocalMediaItem(
      sourceRef: ref,
      title: 'Midnight Signal',
      artists: const ['Luna Park'],
      duration: const Duration(minutes: 3, seconds: 10),
      filePath: 'local://downloads/aurora_stream/alpha_midnight.mp3',
      fileSize: 4096,
      downloadedAt: DateTime.utc(2026, 6, 29),
    );
    final store = _RecordingSnapshotStore();
    final repository = DemoRepository.seeded(
      snapshot: MeloDataSnapshot(localMediaItems: [localItem]),
      snapshotStore: store,
    );

    repository.removeLocalMedia(ref);
    await Future<void>.delayed(Duration.zero);

    expect(store.writes, isNotEmpty);
    expect(store.writes.last.localMediaItems, isEmpty);

    await repository.persistNow();

    expect(store.writes.length, greaterThanOrEqualTo(2));
    expect(store.writes.last.localMediaItems, isEmpty);
  });

  test('DemoRepository persists volume changes', () async {
    final store = _RecordingSnapshotStore();
    final repository = DemoRepository.seeded(snapshotStore: store);

    await repository.setVolume(0.42);
    await Future<void>.delayed(Duration.zero);

    expect(store.writes, isNotEmpty);
    expect(store.writes.last.volume, closeTo(0.42, 0.001));
    expect(repository.toSnapshot().volume, closeTo(0.42, 0.001));
  });

  test('DemoRepository persists configured download directory', () async {
    final store = _RecordingSnapshotStore();
    final repository = DemoRepository.seeded(snapshotStore: store);
    final directory = path.join(
      path.current,
      'build',
      'test_downloads',
      'custom',
    );

    await repository.setDownloadDirectory(directory);
    await Future<void>.delayed(Duration.zero);

    final expected = path.normalize(path.absolute(directory));
    expect(await repository.downloadDirectoryPath(), expected);
    expect(repository.toSnapshot().downloadDirectory, expected);
    expect(store.writes.last.downloadDirectory, expected);

    await repository.setDownloadDirectory(null);

    expect(repository.toSnapshot().downloadDirectory, isNull);
  });
}
