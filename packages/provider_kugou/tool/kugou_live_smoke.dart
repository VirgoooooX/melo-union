import 'package:provider_contract/provider_contract.dart';
import 'package:provider_kugou/provider_kugou.dart';

Future<void> main() async {
  final provider = KugouMusicProvider.create(
    secureStore: _MemoryKugouSessionStore(),
  );

  final recommended = await provider.getDailyRecommendations();
  print('daily=${recommended.length}');
  if (recommended.isNotEmpty) {
    final first = recommended.first;
    print('daily.first=${first.title} ${first.ref.trackId}');
    final ticket = await provider.createPlaybackTicket(
      track: first.ref,
      quality: AudioQuality.high,
    );
    print('daily.first.url=${ticket.mediaUri}');
    print('daily.first.quality=${ticket.quality}');
  }

  final playlists = await provider.getRecommendedPlaylists();
  print('playlists=${playlists.length}');
  if (playlists.isNotEmpty) {
    final first = playlists.first;
    print('playlists.first=${first.name} ${first.playlistId}');
    final tracks = await provider.getPlaylistTracks(first.playlistId);
    print('playlists.first.tracks=${tracks.length}');
  }

  final charts = await provider.getChartPlaylists(limit: 3);
  print('charts=${charts.length}');
  if (charts.isNotEmpty) {
    final first = charts.first;
    print('charts.first=${first.name} ${first.playlistId}');
    final tracks = await provider.getPlaylistTracks(first.playlistId);
    print('charts.first.tracks=${tracks.length}');
  }
}

final class _MemoryKugouSessionStore implements KugouSecureSessionStore {
  KugouSession? _session;

  @override
  Future<void> clear() async {
    _session = null;
  }

  @override
  Future<KugouSession?> read() async => _session;

  @override
  Future<void> write(KugouSession session) async {
    _session = session;
  }
}
