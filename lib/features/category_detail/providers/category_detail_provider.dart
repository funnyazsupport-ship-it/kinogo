import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';
import '../../../shared/pagination/paginated_notifier.dart';
import '../../../shared/pagination/paginated_state.dart';
import '../data/category_detail_repository.dart';

class CategoryDetailNotifier extends PaginatedNotifier<Post> {
  CategoryDetailNotifier(this._repo, this.slug);
  final CategoryDetailRepository _repo;
  final String slug;

  @override
  Future<PaginatedResponse<Post>> fetchPage(int page) =>
      _repo.fetch(slug: slug, page: page);
}

/// Family keyed by category slug.
final categoryDetailProvider = StateNotifierProvider.family<
    CategoryDetailNotifier, PaginatedState<Post>, String>(
  (ref, slug) =>
      CategoryDetailNotifier(ref.watch(categoryDetailRepositoryProvider), slug),
);
