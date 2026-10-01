import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/error_retry_row.dart';
import 'providers/franchise_provider.dart';
import 'widgets/franchise_card.dart';

class FranchiseListScreen extends ConsumerWidget {
  const FranchiseListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(franchiseListProvider);
    final notifier = ref.read(franchiseListProvider.notifier);

    Widget body;
    if (state.isLoadingFirst) {
      body = const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    } else if (state.error != null && state.items.isEmpty) {
      body = ErrorRetryRow(onRetry: notifier.refresh);
    } else {
      body = RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: notifier.refresh,
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 180,
            childAspectRatio: 0.62,
            crossAxisSpacing: 10,
            mainAxisSpacing: 14,
          ),
          itemCount: state.items.length,
          itemBuilder: (_, i) {
            final f = state.items[i];
            return FranchiseCard(
              franchise: f,
              onTap: () => context.push('/franchise/${f.id}', extra: f.title),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Франшизы')),
      body: body,
    );
  }
}
