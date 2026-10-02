import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';
import '../../../shared/pagination/paginated_notifier.dart';
import '../../../shared/pagination/paginated_state.dart';
import '../data/search_repository.dart';

class SearchNotifier extends PaginatedNotifier<Post> {
  SearchNotifier(this._repo, this.query);
  final SearchRepository _repo;
  final String query;

  @override
  Future<PaginatedResponse<Post>> fetchPage(int page) =>
      _repo.fullSearch(query, page: page);
}

/// Paged search results, keyed by the query.
final searchProvider = StateNotifierProvider.autoDispose
    .family<SearchNotifier, PaginatedState<Post>, String>(
  (ref, query) => SearchNotifier(ref.watch(searchRepositoryProvider), query),
);
