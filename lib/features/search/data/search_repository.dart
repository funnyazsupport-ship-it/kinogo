import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/mock_data.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';

/// Search over posts. `lightsearch` powers the as-you-type suggestions;
/// `xfsearch` runs the full search. Mirrors
/// `features/search/data/search_repository.dart` + `xfsearch_repository.dart`.
class SearchRepository {
  SearchRepository(this._dio);
  final Dio _dio;

  Future<List<Post>> lightSearch(String query) async {
    if (query.trim().isEmpty) return const [];
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return MockData.posts().items.take(6).toList();
    }
    final resp = await _dio.get(
      ApiEndpoints.lightSearch,
      queryParameters: {'q': query, 'query': query},
    );
    return PaginatedResponse.fromJson(resp.data, Post.fromJson).items;
  }

  Future<PaginatedResponse<Post>> fullSearch(String query, {int page = 1}) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return MockData.posts(page: page);
    }
    final resp = await _dio.get(
      ApiEndpoints.xfSearch,
      queryParameters: {'q': query, 'query': query, 'page': page},
    );
    return PaginatedResponse.fromJson(resp.data, Post.fromJson);
  }
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(dioProvider)),
);
