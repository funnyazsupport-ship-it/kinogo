import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/filters_config.dart';

/// Bottom sheet for picking one of [options] (`(value, label)` pairs).
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required T current,
  required List<(T, String)> options,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppTheme.surface,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetTitle(title),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final (value, label) in options)
                  ListTile(
                    title: Text(label),
                    trailing: value == current
                        ? const Icon(Icons.check, color: AppTheme.accent)
                        : null,
                    onTap: () => Navigator.of(context).pop(value),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// What the user picked for one filter field.
typedef FilterFieldResult = ({Set<int> selected, bool combined});

/// Bottom sheet for picking any number of a field's values.
Future<FilterFieldResult?> showFilterFieldSheet(
  BuildContext context, {
  required FilterField field,
  required Set<int> selected,
  required bool combined,
}) {
  return showModalBottomSheet<FilterFieldResult>(
    context: context,
    backgroundColor: AppTheme.surface,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _FilterFieldSheet(
      field: field,
      selected: selected,
      combined: combined,
    ),
  );
}

class _FilterFieldSheet extends StatefulWidget {
  const _FilterFieldSheet({
    required this.field,
    required this.selected,
    required this.combined,
  });

  final FilterField field;
  final Set<int> selected;
  final bool combined;

  @override
  State<_FilterFieldSheet> createState() => _FilterFieldSheetState();
}

class _FilterFieldSheetState extends State<_FilterFieldSheet> {
  late final Set<int> _selected = {...widget.selected};
  late bool _combined = widget.combined;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    final query = _query.trim().toLowerCase();
    final options = query.isEmpty
        ? field.options
        : field.options
            .where((o) => o.title.toLowerCase().contains(query))
            .toList();

    return Padding(
      // Keep the sheet above the keyboard while searching.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: FractionallySizedBox(
        heightFactor: 0.8,
        child: Column(
          children: [
            _SheetTitle(field.label),
            if (field.options.length > 12)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: 'Поиск...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final option in options)
                        _OptionChip(
                          label: option.title,
                          selected: _selected.contains(option.id),
                          onTap: () => setState(() {
                            _selected.contains(option.id)
                                ? _selected.remove(option.id)
                                : _selected.add(option.id);
                          }),
                        ),
                      if (options.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Ничего не найдено',
                              style: TextStyle(color: AppTheme.textSecondary)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (field.canCombine)
              SwitchListTile(
                dense: true,
                activeThumbColor: AppTheme.accent,
                title: const Text('Сочетание значений'),
                subtitle: Text(
                  _combined
                      ? 'Подходит под все выбранные сразу'
                      : 'Подходит под любое из выбранных',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                value: _combined,
                onChanged: (v) => setState(() => _combined = v),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _selected.isEmpty
                          ? null
                          : () => setState(_selected.clear),
                      child: Text('Очистить (${_selected.length})'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(
                        (selected: _selected, combined: _combined),
                      ),
                      child: const Text('Применить'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Colors.black : AppTheme.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (_) => onTap(),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 4, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Закрыть',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
