import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/movie_card.dart';
import 'providers/favorites_provider.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Избранное')),
      body: favorites.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border,
              message: 'В избранном пока пусто.\n'
                  'Нажмите на сердечко на странице фильма, чтобы сохранить его.',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 0.52,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
              ),
              itemCount: favorites.length,
              itemBuilder: (_, i) => MovieCard(post: favorites[i]),
            ),
    );
  }
}
