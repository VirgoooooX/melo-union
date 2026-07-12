import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/all_favorites/all_favorites_page.dart';
import '../features/downloads/downloads_page.dart';
import '../features/local_playlists/local_playlists_page.dart';
import '../features/local_library/local_library_page.dart';
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
            pageBuilder: (context, state) =>
                _plainPage(state, const AllFavoritesPage()),
          ),
          GoRoute(
            path: AppDestination.playlists.path,
            pageBuilder: (context, state) =>
                _plainPage(state, const LocalPlaylistsPage()),
          ),
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows)
            GoRoute(
              path: AppDestination.local.path,
              pageBuilder: (context, state) =>
                  _plainPage(state, const LocalLibraryPage()),
            ),
          GoRoute(
            path: AppDestination.recommendations.path,
            pageBuilder: (context, state) =>
                _plainPage(state, const RecommendationsPage()),
          ),
          GoRoute(
            path: AppDestination.search.path,
            pageBuilder: (context, state) =>
                _plainPage(state, const SearchPage()),
          ),
          GoRoute(
            path: AppDestination.downloads.path,
            pageBuilder: (context, state) =>
                _plainPage(state, const DownloadsPage()),
          ),
          GoRoute(
            path: AppDestination.settings.path,
            pageBuilder: (context, state) =>
                _plainPage(state, const SettingsPage()),
          ),
        ],
      ),
    ],
  );
});

NoTransitionPage<void> _plainPage(GoRouterState state, Widget child) {
  return NoTransitionPage<void>(
    key: state.pageKey,
    child: child,
  );
}
