import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paginated_response.dart';
import 'paginated_state.dart';

/// Base notifier that loads a paged endpoint and appends pages.
/// Mirrors `shared/pagination/paginated_notifier.dart`.
abstract class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  PaginatedNotifier() : super(PaginatedState<T>()) {
    loadFirst();
  }

  /// Subclasses fetch one page.
  Future<PaginatedResponse<T>> fetchPage(int page);

  Future<void> loadFirst() async {
    state = state.copyWith(isLoadingFirst: true, clearError: true);
    try {
      final res = await fetchPage(1);
      // The notifier may have been disposed while the page was loading.
      if (!mounted) return;
      state = PaginatedState<T>(
        items: res.items,
        page: res.page,
        totalPages: res.totalPages,
        total: res.total,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingFirst: false, error: e);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || state.isLoadingFirst || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final next = state.page + 1;
      final res = await fetchPage(next);
      if (!mounted) return;
      state = state.copyWith(
        items: [...state.items, ...res.items],
        page: res.page,
        totalPages: res.totalPages,
        isLoadingMore: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  Future<void> refresh() => loadFirst();
}
