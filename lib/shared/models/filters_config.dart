/// Options of the site's catalogue filter (its `window.__XSORT__` config).
class FiltersConfig {
  const FiltersConfig({this.fields = const [], this.sorts = const []});

  final List<FilterField> fields;
  final List<SortOption> sorts;
}

/// One filter dimension (year, genre, country, ...).
class FilterField {
  const FilterField({
    required this.key,
    required this.label,
    this.options = const [],
    this.canCombine = false,
    this.combinedByDefault = false,
  });

  /// Short field id used by the site (`y`, `g`, `c`, ...).
  final String key;
  final String label;
  final List<FilterOption> options;

  /// Whether several values can be required at once ("фантастическая
  /// комедия") instead of matching any of them.
  final bool canCombine;
  final bool combinedByDefault;
}

class FilterOption {
  const FilterOption({required this.id, required this.title});

  final int id;
  final String title;
}

class SortOption {
  const SortOption({required this.value, required this.label});

  final String value;
  final String label;
}
