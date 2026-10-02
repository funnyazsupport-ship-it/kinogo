import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/api/categories_config.dart';
import '../../core/theme/app_theme.dart';

/// The category showcase grid (fed by the bundled category images).
/// Mirrors `features/categories/categories_screen.dart`.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  void _open(BuildContext context, CategoryConfig c) {
    switch (c.kind) {
      case CategoryKind.franchises:
        context.push('/franchises');
      case CategoryKind.podborki:
        context.push('/podborki');
      case CategoryKind.posts:
        context.push('/categories/category/${c.slug}', extra: c.title);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Категории')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _FilterEntry(onTap: () => context.push('/catalog')),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 1.7,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: kCategories.length,
              itemBuilder: (context, i) => _CategoryTile(
                config: kCategories[i],
                onTap: () => _open(context, kCategories[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Entry to the catalogue filter (genre, country, year, ...).
class _FilterEntry extends StatelessWidget {
  const _FilterEntry({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceVariant,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.tune, color: AppTheme.accent),
        title: const Text('Подбор по фильтру',
            style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text(
          'Жанр, страна, год, подборки, качество, перевод',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.config, required this.onTap});
  final CategoryConfig config;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              config.image,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: AppTheme.surfaceVariant),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  config.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
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
