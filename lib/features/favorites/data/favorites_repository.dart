import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/mock_data.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';

/// Favorites (bookmarks) backed by `/v1/favorites`.
/// Mirrors `features/favorites/data/favorites_repository.dart`.
class FavoritesRepository {
  FavoritesRepository(this._dio);
  final Dio _dio;

  Future<PaginatedResponse<Post>> fetch({int page = 1}) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return MockData.posts(page: page).items.isEmpty
          ? const PaginatedResponse(items: [], page: 1, totalPages: 1)
          : MockData.posts(page: page);
    }
    final resp = await _dio.get(
      ApiEndpoints.favorites,
      queryParameters: {'page': page},
    );
    return PaginatedResponse.fromJson(resp.data, Post.fromJson);
  }

  Future<Set<int>> fetchIds() async {
    if (AppConfig.useMockData) return {1, 3, 5};
    final resp = await _dio.get(ApiEndpoints.favoriteIds);
    final list = (resp.data is Map ? (resp.data as Map)['data'] : resp.data);
    return (list as List? ?? const [])
        .map((e) => e is int ? e : int.tryParse('$e') ?? 0)
        .toSet();
  }

  Future<void> add(int postId) async {
    if (AppConfig.useMockData) return;
    await _dio.post(ApiEndpoints.favorites, data: {'post_id': postId});
  }

  Future<void> remove(int postId) async {
    if (AppConfig.useMockData) return;
    await _dio.delete('${ApiEndpoints.favorites}/$postId');
  }
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(dioProvider)),
);
