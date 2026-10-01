import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/franchise.dart';

class FranchiseCard extends StatelessWidget {
  const FranchiseCard({super.key, required this.franchise, required this.onTap});

  final Franchise franchise;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final poster = franchise.posterUrl ?? franchise.items.firstOrNull?.posterUrl;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (poster != null)
                    CachedNetworkImage(imageUrl: poster, fit: BoxFit.cover)
                  else
                    Container(
                      color: AppTheme.surfaceVariant,
                      child: const Icon(Icons.collections_bookmark_outlined,
                          color: AppTheme.textSecondary, size: 36),
                    ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${franchise.itemCount}',
                        style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            franchise.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
