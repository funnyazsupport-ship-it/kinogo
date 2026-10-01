import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/mock_data.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';

/// Loads the home feed (`/v1/post`). Mirrors `features/home/data/home_repository.dart`.
class HomeRepository {
  HomeRepository(this._dio);
  final Dio _dio;

  Future<PaginatedResponse<Post>> fetchPosts({int page = 1}) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return MockData.posts(page: page);
    }
    final resp = await _dio.get(
      ApiEndpoints.posts,
      queryParameters: {'page': page},
    );
    return PaginatedResponse.fromJson(resp.data, Post.fromJson);
  }
}

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(ref.watch(dioProvider)),
);
