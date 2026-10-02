/// Immutable state for an infinite, paged list.
/// Mirrors `shared/pagination/paginated_state.dart`.
class PaginatedState<T> {
  const PaginatedState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.total,
    this.isLoadingFirst = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<T> items;
  final int page;
  final int totalPages;

  /// Number of matching items overall, when the source reports it.
  final int? total;
  final bool isLoadingFirst;
  final bool isLoadingMore;
  final Object? error;

  bool get hasMore => page < totalPages;
  bool get isEmpty => items.isEmpty && !isLoadingFirst && error == null;

  PaginatedState<T> copyWith({
    List<T>? items,
    int? page,
    int? totalPages,
    int? total,
    bool? isLoadingFirst,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) =>
      PaginatedState<T>(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        total: total ?? this.total,
        isLoadingFirst: isLoadingFirst ?? this.isLoadingFirst,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : (error ?? this.error),
      );
}
