import '../../core/config/app_config.dart';
import 'post.dart';

/// A franchise / movie universe. Mirrors `shared/models/franchise.dart`.
class Franchise {
  const Franchise({
    required this.id,
    required this.title,
    this.poster,
    this.itemCount = 0,
    this.items = const [],
  });

  final int id;
  final String title;
  final String? poster;
  final int itemCount;
  final List<Post> items;

  String? get posterUrl {
    final p = poster;
    if (p == null || p.isEmpty) return null;
    if (p.startsWith('http')) return p;
    return '${AppConfig.siteBaseUrl}${p.startsWith('/') ? '' : '/'}$p';
  }

  factory Franchise.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) => v is int ? v : int.tryParse('${v ?? ''}') ?? 0;
    final rawItems = (json['items'] ?? json['posts'] ?? json['movies']) as List?;
    return Franchise(
      id: asInt(json['id']),
      title: '${json['title'] ?? json['name'] ?? ''}',
      poster: (json['poster'] ?? json['image'])?.toString(),
      itemCount: asInt(json['count'] ?? json['itemCount'] ?? rawItems?.length),
      items: rawItems
              ?.whereType<Map<String, dynamic>>()
              .map(Post.fromJson)
              .toList() ??
          const [],
    );
  }
}
