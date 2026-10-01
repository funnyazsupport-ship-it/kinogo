/// Immutable state for an infinite, paged list.
/// Mirrors `shared/pagination/paginated_state.dart`.
class PaginatedState<T> {
  const PaginatedState({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoadingFirst = false,
    this.isLoadingMore = false,
    this.error,
  });

  final List<T> items;
  final int page;
  final int totalPages;
  final bool isLoadingFirst;
  final bool isLoadingMore;
  final Object? error;

  bool get hasMore => page < totalPages;
  bool get isEmpty => items.isEmpty && !isLoadingFirst && error == null;

  PaginatedState<T> copyWith({
    List<T>? items,
    int? page,
    int? totalPages,
    bool? isLoadingFirst,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
  }) =>
      PaginatedState<T>(
        items: items ?? this.items,
        page: page ?? this.page,
        totalPages: totalPages ?? this.totalPages,
        isLoadingFirst: isLoadingFirst ?? this.isLoadingFirst,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        error: clearError ? null : (error ?? this.error),
      );
}
