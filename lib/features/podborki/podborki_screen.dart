import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/podborka.dart';
import '../../shared/widgets/error_retry_row.dart';
import '../../shared/widgets/movie_card.dart';
import 'providers/podborki_provider.dart';

class PodborkiScreen extends ConsumerWidget {
  const PodborkiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(podborkiProvider);
    final notifier = ref.read(podborkiProvider.notifier);

    Widget body;
    if (state.isLoadingFirst) {
      body = const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    } else if (state.error != null && state.items.isEmpty) {
      body = ErrorRetryRow(onRetry: notifier.refresh);
    } else {
      body = RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: notifier.refresh,
        child: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: state.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 20),
          itemBuilder: (_, i) => _PodborkaRow(state.items[i]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Подборки')),
      body: body,
    );
  }
}

class _PodborkaRow extends StatelessWidget {
  const _PodborkaRow(this.podborka);
  final Podborka podborka;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (podborka.posterUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: podborka.posterUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
            if (podborka.posterUrl != null) const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    podborka.title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  if (podborka.description != null)
                    Text(
                      podborka.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: podborka.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) =>
                MovieCard(post: podborka.items[i], width: 120),
          ),
        ),
      ],
    );
  }
}
