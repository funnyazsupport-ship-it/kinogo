import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/post.dart';
import '../../shared/widgets/error_retry_row.dart';
import '../../shared/widgets/kp_rating_badge.dart';
import '../../shared/widgets/movie_card.dart';
import 'providers/movie_provider.dart';
import 'widgets/movie_comments.dart';

class MovieScreen extends ConsumerWidget {
  const MovieScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movie = ref.watch(movieProvider(id));
    return Scaffold(
      body: movie.when(
        data: (post) => _MovieBody(post: post),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (_, __) => Center(
          child: ErrorRetryRow(onRetry: () => ref.invalidate(movieProvider(id))),
        ),
      ),
    );
  }
}

class _MovieBody extends ConsumerWidget {
  const _MovieBody({required this.post});
  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref.watch(relatedProvider(post.id));
    final rating = post.kinopoiskRating ?? post.imdbRating ?? post.rating;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (post.posterUrl != null)
                  CachedNetworkImage(
                      imageUrl: post.posterUrl!, fit: BoxFit.cover)
                else
                  Container(color: AppTheme.surfaceVariant),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, AppTheme.background],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w800),
                ),
                if (post.originalTitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(post.originalTitle!,
                        style: const TextStyle(color: AppTheme.textSecondary)),
                  ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (rating != null && rating > 0) KpRatingBadge(rating),
                    if (post.year != null) _chip(post.year!),
                    if (post.quality != null) _chip(post.quality!),
                    ...post.genres.take(3).map(_chip),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/movie/${post.id}/player', extra: post.title),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Смотреть'),
                  ),
                ),
                if (post.description != null) ...[
                  const SizedBox(height: 16),
                  Text(post.description!,
                      style: const TextStyle(height: 1.4, fontSize: 14)),
                ],
                const SizedBox(height: 24),
                related.maybeWhen(
                  data: (items) => items.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Похожее',
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 230,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 10),
                                itemBuilder: (_, i) =>
                                    MovieCard(post: items[i], width: 120),
                              ),
                            ),
                          ],
                        ),
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                MovieComments(postId: post.id),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      );
}
