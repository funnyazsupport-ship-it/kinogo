import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/podborka.dart';
import '../../shared/widgets/error_retry_row.dart';
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
        child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            childAspectRatio: 1.7,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: state.items.length,
          itemBuilder: (_, i) => _PodborkaTile(state.items[i]),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Подборки')),
      body: body,
    );
  }
}

/// A collection tile; tapping opens its post list.
class _PodborkaTile extends StatelessWidget {
  const _PodborkaTile(this.podborka);
  final Podborka podborka;

  @override
  Widget build(BuildContext context) {
    final slug = podborka.slug;
    return GestureDetector(
      onTap: slug == null
          ? null
          : () => context.push(
                '/category/${Uri.encodeComponent(slug)}',
                extra: podborka.title,
              ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (podborka.posterUrl != null)
              CachedNetworkImage(
                imageUrl: podborka.posterUrl!,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppTheme.surfaceVariant),
                errorWidget: (_, __, ___) =>
                    Container(color: AppTheme.surfaceVariant),
              )
            else
              Container(color: AppTheme.surfaceVariant),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.8),
                  ],
                ),
              ),
            ),
            if (podborka.itemCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${podborka.itemCount}',
                    style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  podborka.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
