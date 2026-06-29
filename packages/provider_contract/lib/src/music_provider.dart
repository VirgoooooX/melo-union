import 'provider_descriptor.dart';
import 'provider_models.dart';

abstract interface class MusicProvider {
  ProviderDescriptor get descriptor;

  bool get isAuthenticated;

  Future<ProviderAccountProfile?> getProfile();

  Future<FavoriteSnapshot> pullFavorites({bool forceRefresh = false});

  Future<List<SourceTrack>> search(String query);

  Future<void> setFavorite({
    required ProviderTrackRef track,
    required bool liked,
  });

  Future<List<SourceTrack>> getDailyRecommendations();

  Future<PlaybackTicket> createPlaybackTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  });

  Future<DownloadTicket> createDownloadTicket({
    required ProviderTrackRef track,
    required AudioQuality quality,
  });
}
