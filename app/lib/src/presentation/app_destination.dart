enum AppDestination {
  favorites('/favorites'),
  playlists('/playlists'),
  recommendations('/recommendations'),
  search('/search'),
  downloads('/downloads'),
  settings('/settings');

  const AppDestination(this.path);

  final String path;
}
