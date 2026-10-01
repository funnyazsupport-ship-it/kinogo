import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/kinogo_web_service.dart';
import '../../../shared/models/filter_state.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';

/// Loads posts for a category.
class CategoryDetailRepository {
  CategoryDetailRepository(this._service);
  final KinogoWebService _service;

  Future<PaginatedResponse<Post>> fetch({
    required String slug,
    int page = 1,
    FilterState filter = const FilterState(),
  }) async {
    return _service.fetchCategoryPosts(slug, page: page);
  }
}

final categoryDetailRepositoryProvider = Provider<CategoryDetailRepository>(
  (ref) => CategoryDetailRepository(ref.watch(kinogoWebServiceProvider)),
);
