import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../providers/movie_provider.dart';

class MovieComments extends ConsumerWidget {
  const MovieComments({super.key, required this.postId});
  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final comments = ref.watch(commentsProvider(postId));
    return comments.maybeWhen(
      data: (items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Комментарии (${items.length})',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...items.map(
            (c) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.surfaceVariant,
                        child: Text(
                          c.author.isNotEmpty ? c.author[0].toUpperCase() : '?',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(c.author,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      if (c.date != null)
                        Text(c.date!,
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(c.text, style: const TextStyle(fontSize: 13, height: 1.3)),
                ],
              ),
            ),
          ),
        ],
      ),
      orElse: () => const SizedBox.shrink(),
    );
  }
}
