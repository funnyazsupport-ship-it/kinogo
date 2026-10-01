/// Available filter options returned by `/v1/filters`.
/// Mirrors `shared/models/filters_config.dart`.
class FiltersConfig {
  const FiltersConfig({
    this.genres = const [],
    this.countries = const [],
    this.years = const [],
    this.qualities = const [],
  });

  final List<FilterOption> genres;
  final List<FilterOption> countries;
  final List<FilterOption> years;
  final List<FilterOption> qualities;

  factory FiltersConfig.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map) ? json['data'] as Map : json;
    List<FilterOption> parse(Object? v) =>
        (v as List?)
            ?.map((e) => e is Map
                ? FilterOption.fromJson(e.cast<String, dynamic>())
                : FilterOption(id: '$e', title: '$e'))
            .toList() ??
        const [];
    return FiltersConfig(
      genres: parse(data['genres'] ?? data['genre']),
      countries: parse(data['countries'] ?? data['country']),
      years: parse(data['years'] ?? data['year']),
      qualities: parse(data['qualities'] ?? data['quality']),
    );
  }
}

class FilterOption {
  const FilterOption({required this.id, required this.title});

  final String id;
  final String title;

  factory FilterOption.fromJson(Map<String, dynamic> json) => FilterOption(
        id: '${json['id'] ?? json['slug'] ?? json['value'] ?? ''}',
        title: '${json['title'] ?? json['name'] ?? json['label'] ?? ''}',
      );
}
