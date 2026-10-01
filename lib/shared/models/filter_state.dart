/// Currently applied browse filters/sort. Mirrors `shared/models/filter_state.dart`.
enum SortBy { dateDesc, dateAsc, ratingDesc, popularityDesc }

extension SortByLabel on SortBy {
  String get label => switch (this) {
        SortBy.dateDesc => 'Сначала новые',
        SortBy.dateAsc => 'Сначала старые',
        SortBy.ratingDesc => 'По рейтингу',
        SortBy.popularityDesc => 'По популярности',
      };

  String get apiValue => switch (this) {
        SortBy.dateDesc => 'date_desc',
        SortBy.dateAsc => 'date_asc',
        SortBy.ratingDesc => 'rating_desc',
        SortBy.popularityDesc => 'popularity_desc',
      };
}

class FilterState {
  const FilterState({
    this.genre,
    this.country,
    this.year,
    this.quality,
    this.sortBy = SortBy.dateDesc,
  });

  final String? genre;
  final String? country;
  final String? year;
  final String? quality;
  final SortBy sortBy;

  bool get isEmpty =>
      genre == null && country == null && year == null && quality == null;

  int get activeCount =>
      [genre, country, year, quality].where((e) => e != null).length;

  FilterState copyWith({
    String? genre,
    String? country,
    String? year,
    String? quality,
    SortBy? sortBy,
    bool clearGenre = false,
    bool clearCountry = false,
    bool clearYear = false,
    bool clearQuality = false,
  }) =>
      FilterState(
        genre: clearGenre ? null : (genre ?? this.genre),
        country: clearCountry ? null : (country ?? this.country),
        year: clearYear ? null : (year ?? this.year),
        quality: clearQuality ? null : (quality ?? this.quality),
        sortBy: sortBy ?? this.sortBy,
      );

  Map<String, dynamic> toQuery() => {
        if (genre != null) 'genre': genre,
        if (country != null) 'country': country,
        if (year != null) 'year': year,
        if (quality != null) 'quality': quality,
        'sort': sortBy.apiValue,
      };
}
