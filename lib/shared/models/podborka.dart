import '../../core/config/app_config.dart';
import 'post.dart';

/// A curated collection ("подборка"). Mirrors `shared/models/podborka.dart`.
class Podborka {
  const Podborka({
    required this.id,
    required this.title,
    this.slug,
    this.description,
    this.poster,
    this.itemCount = 0,
    this.items = const [],
  });

  final int id;
  final String title;

  /// Site path of the collection's post list (e.g. `xfsearch/podborki/Marvel`).
  final String? slug;
  final String? description;
  final String? poster;
  final int itemCount;
  final List<Post> items;

  String? get posterUrl {
    final p = poster;
    if (p == null || p.isEmpty) return null;
    if (p.startsWith('http')) return p;
    return '${AppConfig.siteBaseUrl}${p.startsWith('/') ? '' : '/'}$p';
  }

  factory Podborka.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
    final rawItems = (json['items'] ?? json['posts']) as List?;
    return Podborka(
      id: asInt(json['id']),
      title: '${json['title'] ?? json['name'] ?? ''}',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      poster: (json['poster'] ?? json['image'])?.toString(),
      itemCount: asInt(json['count'] ?? rawItems?.length),
      items: rawItems
              ?.whereType<Map<String, dynamic>>()
              .map(Post.fromJson)
              .toList() ??
          const [],
    );
  }
}
