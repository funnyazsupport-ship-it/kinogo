import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/models/filter_state.dart';
import '../../shared/models/filters_config.dart';
import '../../shared/pagination/paginated_list_view.dart';
import '../../shared/widgets/error_retry_row.dart';
import 'providers/catalog_provider.dart';
import 'widgets/filter_sheets.dart';

/// Browse the whole catalogue by section, genre, country, year, collection,
/// quality and translation, with a choice of sort order.
class CatalogScreen extends ConsumerWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(filtersConfigProvider);
    final filter = ref.watch(catalogFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Фильтр'),
        actions: [
          if (!filter.isDefault)
            TextButton(
              onPressed: () => ref.read(catalogFilterProvider.notifier).state =
                  const FilterState(),
              child: const Text('Сбросить'),
            ),
        ],
      ),
      body: config.when(
        data: (c) => _CatalogBody(config: c),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.accent)),
        error: (_, __) => ErrorRetryRow(
          onRetry: () => ref.invalidate(filtersConfigProvider),
        ),
      ),
    );
  }
}

class _CatalogBody extends ConsumerWidget {
  const _CatalogBody({required this.config});
  final FiltersConfig config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(catalogFilterProvider);
    final state = ref.watch(catalogProvider(config));
    final notifier = ref.read(catalogProvider(config).notifier);

    void update(FilterState next) =>
        ref.read(catalogFilterProvider.notifier).state = next;

    final section = kCatalogSections.firstWhere(
      (s) => s.slug == filter.section,
      orElse: () => kCatalogSections.first,
    );
    final sort = config.sorts.where((s) => s.value == filter.sort).firstOrNull;

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _FilterButton(
                label: section.slug.isEmpty ? 'Раздел' : section.title,
                active: section.slug.isNotEmpty,
                onTap: () async {
                  final slug = await showChoiceSheet<String>(
                    context,
                    title: 'Раздел',
                    current: filter.section,
                    options: [
                      for (final s in kCatalogSections) (s.slug, s.title),
                    ],
                  );
                  if (slug != null) update(filter.copyWith(section: slug));
                },
              ),
              for (final field in config.fields)
                _FilterButton(
                  label: _fieldLabel(field, filter),
                  active: filter.valuesOf(field.key).isNotEmpty,
                  onTap: () async {
                    final result = await showFilterFieldSheet(
                      context,
                      field: field,
                      selected: filter.valuesOf(field.key),
                      combined: filter.isCombined(field),
                    );
                    if (result != null) {
                      update(filter.withField(
                        field.key,
                        result.selected,
                        combine: field.canCombine ? result.combined : null,
                      ));
                    }
                  },
                ),
              if (config.sorts.isNotEmpty)
                _FilterButton(
                  icon: Icons.sort,
                  label: sort?.label ?? 'Сортировка',
                  active: filter.sort != kDefaultSort,
                  onTap: () async {
                    final value = await showChoiceSheet<String>(
                      context,
                      title: 'Сортировка',
                      current: filter.sort,
                      options: [
                        for (final s in config.sorts) (s.value, s.label),
                      ],
                    );
                    if (value != null) update(filter.copyWith(sort: value));
                  },
                ),
            ],
          ),
        ),
        Expanded(
          child: PaginatedPostGrid(
            state: state,
            onLoadMore: notifier.loadMore,
            onRefresh: notifier.refresh,
            emptyMessage: 'По этому фильтру ничего не найдено',
            header: state.total == null
                ? null
                : Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                    child: Text(
                      'Найдено: ${state.total}',
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// "Жанр" → "комедия" → "Жанр: 3" as values get selected.
  String _fieldLabel(FilterField field, FilterState filter) {
    final ids = filter.valuesOf(field.key);
    if (ids.isEmpty) return field.label;
    if (ids.length > 1) return '${field.label}: ${ids.length}';
    return field.options
            .where((o) => o.id == ids.first)
            .firstOrNull
            ?.title ??
        field.label;
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.active,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.black : AppTheme.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: active ? AppTheme.accent : AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.only(left: 12, right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                ],
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, size: 20, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
