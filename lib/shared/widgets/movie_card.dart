import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../models/post.dart';
import 'kp_rating_badge.dart';
import 'quality_badge.dart';

/// Poster card used across grids and carousels. Tapping opens the movie screen.
///
/// The card fills the height it is given (a grid cell, a fixed-height row):
/// the poster takes whatever the title and year leave, so a two-line title
/// never pushes the year out of the card.
class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.post, this.width});

  final Post post;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final rating = post.kinopoiskRating ?? post.imdbRating ?? post.rating;
    return GestureDetector(
      onTap: () => context.push('/movie/${post.id}'),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _Poster(post.posterUrl, title: post.title),
                    Positioned(
                      left: 6,
                      right: 6,
                      top: 6,
                      child: Row(
                        children: [
                          if (rating != null && rating > 0)
                            KpRatingBadge(rating),
                          if (post.quality != null) ...[
                            const SizedBox(width: 4),
                            Flexible(child: QualityBadge(post.quality!)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              post.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            if (post.year != null)
              Text(
                post.year!,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster(this.url, {required this.title});
  final String? url;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _placeholder();
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(color: AppTheme.surfaceVariant),
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        color: AppTheme.surfaceVariant,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.movie_outlined,
                color: AppTheme.textSecondary, size: 32),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 3,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 11),
            ),
          ],
        ),
      );
}
