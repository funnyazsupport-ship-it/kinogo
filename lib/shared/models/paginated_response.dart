/// Generic paged payload. Mirrors `shared/models/paginated_response.dart`.
///
/// Tolerant of several common envelope shapes:
///   { "items": [...], "page": 1, "totalPages": 10 }
///   { "data":  [...], "meta": { "currentPage": 1, "lastPage": 10 } }
///   [ ... ]  (a bare list)
class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.totalPages,
    this.total,
  });

  final List<T> items;
  final int page;
  final int totalPages;
  final int? total;

  bool get hasMore => page < totalPages;

  factory PaginatedResponse.fromJson(
    Object? json,
    T Function(Map<String, dynamic>) fromItem,
  ) {
    if (json is List) {
      return PaginatedResponse(
        items: json
            .whereType<Map<String, dynamic>>()
            .map(fromItem)
            .toList(growable: false),
        page: 1,
        totalPages: 1,
        total: json.length,
      );
    }

    final map = (json as Map).cast<String, dynamic>();
    final rawList = (map['items'] ?? map['data'] ?? map['posts'] ?? map['result'])
        as List? ??
        const [];
    final meta = (map['meta'] ?? map['pagination'] ?? map) as Map;

    int asInt(Object? v, int fallback) =>
        v is int ? v : int.tryParse('${v ?? ''}') ?? fallback;

    return PaginatedResponse(
      items: rawList
          .whereType<Map<String, dynamic>>()
          .map(fromItem)
          .toList(growable: false),
      page: asInt(meta['page'] ?? meta['currentPage'] ?? map['page'], 1),
      totalPages: asInt(
        meta['totalPages'] ?? meta['lastPage'] ?? map['totalPages'] ?? map['pages'],
        1,
      ),
      total: (meta['total'] ?? map['total']) is int
          ? (meta['total'] ?? map['total']) as int
          : null,
    );
  }
}
