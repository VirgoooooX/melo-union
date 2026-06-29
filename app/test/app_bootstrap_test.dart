import 'package:flutter_test/flutter_test.dart';
import 'package:melo_union_app/src/bootstrap/app_bootstrap.dart';
import 'package:melo_union_app/src/bootstrap/managed_snapshot_store.dart';
import 'package:music_data/music_data.dart';
import 'package:music_domain/music_domain.dart';
import 'package:provider_contract/provider_contract.dart';

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

void main() {
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
}
