import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/mock_data.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/models/filter_state.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';

/// Loads posts for a category (`/v1/post/by-category/<slug>`).
/// Mirrors `features/category_detail/data/category_detail_repository.dart`.
class CategoryDetailRepository {
  CategoryDetailRepository(this._dio);
  final Dio _dio;

  Future<PaginatedResponse<Post>> fetch({
    required String slug,
    int page = 1,
    FilterState filter = const FilterState(),
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return MockData.posts(page: page, category: slug);
    }
    final resp = await _dio.get(
      ApiEndpoints.postsByCategory(slug),
      queryParameters: {'page': page, ...filter.toQuery()},
    );
    return PaginatedResponse.fromJson(resp.data, Post.fromJson);
  }
}

final categoryDetailRepositoryProvider = Provider<CategoryDetailRepository>(
  (ref) => CategoryDetailRepository(ref.watch(dioProvider)),
);
