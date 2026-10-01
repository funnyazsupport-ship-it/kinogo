import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/pagination/paginated_list_view.dart';
import '../../shared/widgets/empty_state.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authed = ref.watch(authProvider).valueOrNull != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: !authed
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const EmptyState(
                    icon: Icons.favorite_border,
                    message: 'Войдите, чтобы сохранять фильмы в избранное',
                  ),
                  FilledButton(
                    onPressed: () => context.push('/profile/auth'),
                    child: const Text('Войти'),
                  ),
                ],
              ),
            )
          : _FavoritesBody(),
    );
  }
}

class _FavoritesBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoritesProvider);
    final notifier = ref.read(favoritesProvider.notifier);
    return PaginatedPostGrid(
      state: state,
      onLoadMore: notifier.loadMore,
      onRefresh: notifier.refresh,
      emptyMessage: 'В избранном пока пусто',
    );
  }
}
