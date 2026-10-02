import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/pagination/paginated_list_view.dart';
import '../history/widgets/recently_watched_row.dart';
import 'providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final notifier = ref.read(homeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('KinoGo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Фильтр',
            onPressed: () => context.push('/catalog'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Поиск',
            onPressed: () => context.go('/search'),
          ),
        ],
      ),
      body: PaginatedPostGrid(
        state: state,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
        emptyMessage: 'Пока нет фильмов',
        // Shown right away, before the feed has loaded.
        header: const RecentlyWatchedRow(),
      ),
    );
  }
}
