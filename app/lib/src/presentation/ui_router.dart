import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/all_favorites/all_favorites_page.dart';
import '../features/downloads/downloads_page.dart';
import '../features/local_playlists/local_playlists_page.dart';
import '../features/recommendations/recommendations_page.dart';
import '../features/search/search_page.dart';
import '../features/settings/settings_page.dart';
import '../layout/app_shell_scaffold.dart';
import 'app_destination.dart';

final uiRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppDestination.favorites.path,
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShellScaffold(
          location: state.uri.toString(),
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppDestination.favorites.path,
            builder: (context, state) => const AllFavoritesPage(),
          ),
          GoRoute(
            path: AppDestination.playlists.path,
            builder: (context, state) => const LocalPlaylistsPage(),
          ),
          GoRoute(
            path: AppDestination.recommendations.path,
            builder: (context, state) => const RecommendationsPage(),
          ),
          GoRoute(
            path: AppDestination.search.path,
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: AppDestination.downloads.path,
            builder: (context, state) => const DownloadsPage(),
          ),
          GoRoute(
            path: AppDestination.settings.path,
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
});
