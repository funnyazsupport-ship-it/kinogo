import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';
import '../../../shared/pagination/paginated_notifier.dart';
import '../../../shared/pagination/paginated_state.dart';
import '../data/favorites_repository.dart';

class FavoritesNotifier extends PaginatedNotifier<Post> {
  FavoritesNotifier(this._repo);
  final FavoritesRepository _repo;

  @override
  Future<PaginatedResponse<Post>> fetchPage(int page) =>
      _repo.fetch(page: page);
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, PaginatedState<Post>>(
  (ref) => FavoritesNotifier(ref.watch(favoritesRepositoryProvider)),
);

/// Set of favorited post ids for quick bookmark-state lookups.
final favoriteIdsProvider = FutureProvider<Set<int>>(
  (ref) => ref.watch(favoritesRepositoryProvider).fetchIds(),
);
