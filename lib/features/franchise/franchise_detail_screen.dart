import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/error_retry_row.dart';
import '../../shared/widgets/movie_card.dart';
import 'providers/franchise_provider.dart';

class FranchiseDetailScreen extends ConsumerWidget {
  const FranchiseDetailScreen({super.key, required this.id, this.title});

  final int id;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(franchiseDetailProvider(id));
    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Франшиза')),
      body: detail.when(
        data: (f) => GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 160,
            childAspectRatio: 0.52,
            crossAxisSpacing: 10,
            mainAxisSpacing: 14,
          ),
          itemCount: f.items.length,
          itemBuilder: (_, i) => MovieCard(post: f.items[i]),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (_, __) =>
            ErrorRetryRow(onRetry: () => ref.invalidate(franchiseDetailProvider(id))),
      ),
    );
  }
}
