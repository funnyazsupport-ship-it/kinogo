import 'filters_config.dart';

/// A site section the catalogue filter can be limited to.
class CatalogSection {
  const CatalogSection(this.slug, this.title);

  /// Category slug on the site; empty for the whole catalogue.
  final String slug;
  final String title;
}

const List<CatalogSection> kCatalogSections = [
  CatalogSection('', 'Всё'),
  CatalogSection('filmy', 'Фильмы'),
  CatalogSection('serialy', 'Сериалы'),
  CatalogSection('russkie-serialy', 'Русские сериалы'),
  CatalogSection('zarubezhnye-serialy', 'Зарубежные сериалы'),
  CatalogSection('tureckie-serialy', 'Турецкие сериалы'),
  CatalogSection('multfilmy', 'Мультфильмы'),
  CatalogSection('multserialy', 'Мультсериалы'),
  CatalogSection('anime', 'Аниме'),
  CatalogSection('doramy', 'Дорамы'),
  CatalogSection('tv-shou', 'ТВ-шоу'),
  CatalogSection('v1new', 'Новинки'),
  CatalogSection('korotkometrazhka', 'Короткометражки'),
];

const String kDefaultSort = 'date';

/// Currently applied catalogue filters and sort.
class FilterState {
  const FilterState({
    this.section = '',
    this.sort = kDefaultSort,
    this.selected = const {},
    this.combined = const {},
  });

  final String section;
  final String sort;

  /// Field key → selected option ids.
  final Map<String, Set<int>> selected;

  /// Field key → whether all selected values are required at once.
  final Map<String, bool> combined;

  Set<int> valuesOf(String field) => selected[field] ?? const {};

  bool isCombined(FilterField field) =>
      combined[field.key] ?? field.combinedByDefault;

  bool get hasFilters => selected.values.any((s) => s.isNotEmpty);

  bool get isDefault => section.isEmpty && sort == kDefaultSort && !hasFilters;

  FilterState copyWith({String? section, String? sort}) => FilterState(
        section: section ?? this.section,
        sort: sort ?? this.sort,
        selected: selected,
        combined: combined,
      );

  FilterState withField(String field, Set<int> values, {bool? combine}) =>
      FilterState(
        section: section,
        sort: sort,
        selected: {...selected, field: values},
        combined: combine == null ? combined : {...combined, field: combine},
      );

  /// Site path of the filtered list.
  String get path => section.isEmpty ? '/' : '/$section/';

  /// Value of the site's `xsort` cookie, which carries the filter:
  /// `<page>|<sort>|<field>=<ids>/<field>=<ids>`.
  String cookieFor(FiltersConfig config) {
    final pageId = section.isEmpty ? 'main' : 'cat__$section';
    final parts = <String>[];
    for (final field in config.fields) {
      final ids = valuesOf(field.key).toList()..sort();
      if (ids.isEmpty) continue;
      final mode = !field.canCombine ? '' : (isCombined(field) ? '%2B' : '*');
      parts.add('${field.key}=$mode${ids.join(',')}');
    }
    return '$pageId|$sort|${parts.join('/')}';
  }
}
