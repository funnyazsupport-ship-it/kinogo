import '../../core/config/app_config.dart';

/// A movie / series entry. Mirrors `shared/models/post.dart`.
///
/// Field names are tolerant: the gateway's exact schema is not published, so
/// several common aliases are accepted. Adjust in one place if the real keys
/// differ.
class Post {
  const Post({
    required this.id,
    required this.title,
    this.originalTitle,
    this.poster,
    this.year,
    this.kinopoiskRating,
    this.imdbRating,
    this.rating,
    this.quality,
    this.genres = const [],
    this.countries = const [],
    this.description,
    this.duration,
    this.categorySlug,
    this.isSeries = false,
  });

  final int id;
  final String title;
  final String? originalTitle;
  final String? poster;
  final String? year;
  final double? kinopoiskRating;
  final double? imdbRating;
  final double? rating;
  final String? quality;
  final List<String> genres;
  final List<String> countries;
  final String? description;
  final String? duration;
  final String? categorySlug;
  final bool isSeries;

  /// Absolute poster URL (prefixes site base for root-relative paths).
  String? get posterUrl {
    final p = poster;
    if (p == null || p.isEmpty) return null;
    if (p.startsWith('http')) return p;
    return '${AppConfig.siteBaseUrl}${p.startsWith('/') ? '' : '/'}$p';
  }

  /// Compact form for local storage (history, favorites); read back by
  /// [Post.fromJson].
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'poster': poster,
        'year': year,
        'quality': quality,
        'kinopoiskRating': kinopoiskRating,
        'imdbRating': imdbRating,
        'rating': rating,
        'isSeries': isSeries,
      };

  factory Post.fromJson(Map<String, dynamic> json) {
    double? asDouble(Object? v) =>
        v == null ? null : (v is num ? v.toDouble() : double.tryParse('$v'));
    int asInt(Object? v) =>
        v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
    List<String> asStrings(Object? v) {
      if (v is List) {
        return v
            .map((e) => e is Map ? '${e['name'] ?? e['title'] ?? ''}' : '$e')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (v is String && v.isNotEmpty) {
        return v.split(RegExp(r'\s*,\s*'));
      }
      return const [];
    }

    return Post(
      id: asInt(json['id'] ?? json['postId'] ?? json['news_id']),
      title: '${json['title'] ?? json['name'] ?? json['ru_title'] ?? ''}',
      originalTitle:
          (json['originalTitle'] ?? json['original_title'] ?? json['en_title'])
              ?.toString(),
      poster: (json['poster'] ?? json['image'] ?? json['cover'] ?? json['thumb'])
          ?.toString(),
      year: (json['year'] ?? json['date'])?.toString(),
      kinopoiskRating:
          asDouble(json['kinopoiskRating'] ?? json['kp_rating'] ?? json['kp']),
      imdbRating: asDouble(json['imdbRating'] ?? json['imdb_rating'] ?? json['imdb']),
      rating: asDouble(json['rating'] ?? json['ratingValue']),
      quality: (json['quality'] ?? json['translate'])?.toString(),
      genres: asStrings(json['genres'] ?? json['genre'] ?? json['category']),
      countries: asStrings(json['countries'] ?? json['country']),
      description:
          (json['description'] ?? json['story'] ?? json['text'])?.toString(),
      duration: (json['duration'] ?? json['time'])?.toString(),
      categorySlug: (json['categorySlug'] ?? json['category_slug'])?.toString(),
      isSeries: json['isSeries'] == true ||
          json['is_series'] == true ||
          '${json['type'] ?? ''}'.toLowerCase().contains('seri'),
    );
  }
}
