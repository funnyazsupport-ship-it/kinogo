import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/catalog/catalog_screen.dart';
import '../../features/categories/categories_screen.dart';
import '../../features/category_detail/category_detail_screen.dart';
import '../../features/favorites/favorites_screen.dart';
import '../../features/franchise/franchise_detail_screen.dart';
import '../../features/franchise/franchise_list_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/movie/movie_screen.dart';
import '../../features/movie/player_screen.dart';
import '../../features/podborki/podborki_screen.dart';
import '../../features/search/search_screen.dart';
import '../../shared/widgets/app_shell.dart';

/// App router. Mirrors `core/navigation/app_routes.dart`.
final _rootKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/home',
  routes: [
    // Each tab keeps its own state (scroll position, typed query) while the
    // user is on another tab.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/categories',
            builder: (_, __) => const CategoriesScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/favorites',
            builder: (_, __) => const FavoritesScreen(),
          ),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        ]),
      ],
    ),
    // Detail routes (cover the bottom navigation).
    GoRoute(
      path: '/category/:slug',
      builder: (_, state) => CategoryDetailScreen(
        slug: state.pathParameters['slug']!,
        title: state.extra as String?,
      ),
    ),
    GoRoute(
      path: '/movie/:id',
      builder: (_, state) =>
          MovieScreen(id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      routes: [
        GoRoute(
          path: 'player',
          builder: (_, state) {
            final args = state.extra is PlayerArgs
                ? state.extra as PlayerArgs
                : const PlayerArgs();
            return PlayerScreen(
              id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              title: args.title,
              resume: args.resume,
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/franchises',
      builder: (_, __) => const FranchiseListScreen(),
    ),
    GoRoute(
      path: '/franchise/:id',
      builder: (_, state) => FranchiseDetailScreen(
        id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        title: state.extra as String?,
      ),
    ),
    GoRoute(
      path: '/podborki',
      builder: (_, __) => const PodborkiScreen(),
    ),
    GoRoute(
      path: '/catalog',
      builder: (_, __) => const CatalogScreen(),
    ),
  ],
);
