import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/auth_screen.dart';
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
import '../../features/profile/profile_screen.dart';
import '../../features/search/search_screen.dart';
import '../../shared/widgets/app_shell.dart';

/// App router. Mirrors `core/navigation/app_routes.dart`.
final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

int _tabIndex(String location) {
  if (location.startsWith('/categories')) return 1;
  if (location.startsWith('/search')) return 2;
  if (location.startsWith('/favorites')) return 3;
  if (location.startsWith('/profile')) return 4;
  return 0;
}

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: '/home',
  routes: [
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (context, state, child) => AppShell(
        currentIndex: _tabIndex(state.uri.path),
        child: child,
      ),
      routes: [
        GoRoute(
          path: '/home',
          builder: (_, __) => const HomeScreen(),
        ),
        GoRoute(
          path: '/categories',
          builder: (_, __) => const CategoriesScreen(),
          routes: [
            GoRoute(
              path: 'category/:slug',
              parentNavigatorKey: _rootKey,
              builder: (_, state) => CategoryDetailScreen(
                slug: state.pathParameters['slug']!,
                title: state.extra as String?,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/search',
          builder: (_, __) => const SearchScreen(),
        ),
        GoRoute(
          path: '/favorites',
          builder: (_, __) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => const ProfileScreen(),
          routes: [
            GoRoute(
              path: 'auth',
              parentNavigatorKey: _rootKey,
              builder: (_, __) => const AuthScreen(),
            ),
          ],
        ),
      ],
    ),
    // Detail routes (cover the bottom navigation).
    GoRoute(
      path: '/movie/:id',
      parentNavigatorKey: _rootKey,
      builder: (_, state) =>
          MovieScreen(id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
      routes: [
        GoRoute(
          path: 'player',
          parentNavigatorKey: _rootKey,
          builder: (_, state) => PlayerScreen(
            id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
            title: state.extra as String?,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/franchises',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const FranchiseListScreen(),
    ),
    GoRoute(
      path: '/franchise/:id',
      parentNavigatorKey: _rootKey,
      builder: (_, state) => FranchiseDetailScreen(
        id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
        title: state.extra as String?,
      ),
    ),
    GoRoute(
      path: '/podborki',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const PodborkiScreen(),
    ),
    GoRoute(
      path: '/history',
      parentNavigatorKey: _rootKey,
      builder: (_, __) => const HistoryScreen(),
    ),
  ],
);
