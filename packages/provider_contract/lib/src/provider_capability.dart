enum ProviderCapability {
  authenticate,
  readFavorites,
  writeFavorites,
  readUserPlaylists,
  readDailyRecommendations,
  readCharts,
  search,
  resolvePlayback,
  resolveDownload,
  lyrics,
  artwork,
}

extension ProviderCapabilityLabel on ProviderCapability {
  String get label => switch (this) {
        ProviderCapability.authenticate => 'Authenticate',
        ProviderCapability.readFavorites => 'Read favorites',
        ProviderCapability.writeFavorites => 'Write favorites',
        ProviderCapability.readUserPlaylists => 'Read playlists',
        ProviderCapability.readDailyRecommendations => 'Daily picks',
        ProviderCapability.readCharts => 'Charts',
        ProviderCapability.search => 'Search',
        ProviderCapability.resolvePlayback => 'Playback',
        ProviderCapability.resolveDownload => 'Download',
        ProviderCapability.lyrics => 'Lyrics',
        ProviderCapability.artwork => 'Artwork',
      };
}
