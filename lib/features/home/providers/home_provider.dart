import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';
import '../../../shared/pagination/paginated_notifier.dart';
import '../../../shared/pagination/paginated_state.dart';
import '../data/home_repository.dart';

class HomeNotifier extends PaginatedNotifier<Post> {
  HomeNotifier(this._repo);
  final HomeRepository _repo;

  @override
  Future<PaginatedResponse<Post>> fetchPage(int page) =>
      _repo.fetchPosts(page: page);
}

final homeProvider =
    StateNotifierProvider<HomeNotifier, PaginatedState<Post>>(
  (ref) => HomeNotifier(ref.watch(homeRepositoryProvider)),
);
