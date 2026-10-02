import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/post.dart';
import '../../../shared/models/watch_progress.dart';
import '../providers/history_provider.dart';
import '../providers/watch_progress_provider.dart';

/// "Недавно просмотренные": the latest watched posts with how far each one
/// got. Takes no space until something has been watched.
class RecentlyWatchedRow extends ConsumerWidget {
  const RecentlyWatchedRow({super.key});

  static const _maxItems = 15;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(historyProvider);
    if (history.isEmpty) return const SizedBox.shrink();
    final progress = ref.watch(watchProgressProvider);
    final items = history.take(_maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 2),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Недавно просмотренные',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/history'),
                child: const Text('Все'),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 204,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) =>
                _RecentCard(post: items[i], progress: progress[items[i].id]),
          ),
        ),
      ],
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.post, this.progress});

  final Post post;
  final WatchProgress? progress;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    final poster = post.posterUrl;
    return GestureDetector(
      onTap: () => context.push('/movie/${post.id}'),
      child: SizedBox(
        width: 108,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 156,
                width: 108,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (poster != null)
                      CachedNetworkImage(
                        imageUrl: poster,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: AppTheme.surfaceVariant),
                        errorWidget: (_, __, ___) => const _PosterPlaceholder(),
                      )
                    else
                      const _PosterPlaceholder(),
                    if (progress != null && progress.canResume)
                      Positioned(
                        left: 6,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            progress.position,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (progress != null && progress.duration > 0)
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: LinearProgressIndicator(
                          value: progress.fraction,
                          minHeight: 4,
                          color: AppTheme.accent,
                          backgroundColor: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              post.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            if (progress?.episodeLabel != null)
              Text(
                progress!.episodeLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppTheme.accent),
              )
            else if (post.year != null)
              Text(
                post.year!,
                maxLines: 1,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
        color: AppTheme.surfaceVariant,
        alignment: Alignment.center,
        child: const Icon(Icons.movie_outlined,
            color: AppTheme.textSecondary, size: 30),
      );
}
