import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/post.dart';
import '../data/favorites_repository.dart';

/// Favorited posts, newest first.
class FavoritesNotifier extends StateNotifier<List<Post>> {
  FavoritesNotifier(this._repo) : super(_repo.load());
  final FavoritesRepository _repo;

  bool contains(int postId) => state.any((p) => p.id == postId);

  Future<void> toggle(Post post) async {
    state = contains(post.id)
        ? state.where((p) => p.id != post.id).toList()
        : [post, ...state];
    await _repo.save(state);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<Post>>(
  (ref) => FavoritesNotifier(ref.watch(favoritesRepositoryProvider)),
);
