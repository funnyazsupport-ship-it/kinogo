import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Bottom-navigation scaffold hosting the five primary tabs.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.currentIndex});

  final Widget child;
  final int currentIndex;

  static const _destinations = [
    ('/home', Icons.home_outlined, Icons.home, 'Главная'),
    ('/categories', Icons.grid_view_outlined, Icons.grid_view, 'Категории'),
    ('/search', Icons.search_outlined, Icons.search, 'Поиск'),
    ('/favorites', Icons.favorite_border, Icons.favorite, 'Избранное'),
    ('/history', Icons.history, Icons.history, 'История'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => context.go(_destinations[i].$1),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.$2),
              selectedIcon: Icon(d.$3),
              label: d.$4,
            ),
        ],
      ),
    );
  }
}
