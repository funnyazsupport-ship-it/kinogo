import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/movie_card.dart';
import 'providers/history_provider.dart';

/// Locally-stored watch history (sqflite-backed).
/// Mirrors `features/history/history_screen.dart`.
class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('История')),
      body: history.isEmpty
          ? const EmptyState(
              icon: Icons.history,
              message: 'История просмотров пуста',
            )
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 0.52,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
              ),
              itemCount: history.length,
              itemBuilder: (_, i) => MovieCard(post: history[i]),
            ),
    );
  }
}
