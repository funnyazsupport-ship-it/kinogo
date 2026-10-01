import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/mock_data.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/models/comment.dart';
import '../../../shared/models/player_response.dart';
import '../../../shared/models/post.dart';

/// Loads a single movie, its player, related items and comments.
/// Mirrors `features/movie/data/movie_repository.dart`.
class MovieRepository {
  MovieRepository(this._dio);
  final Dio _dio;

  Future<Post> fetchPost(int id) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return MockData.post(id);
    }
    final resp = await _dio.get(ApiEndpoints.post(id));
    final data = resp.data is Map && (resp.data as Map)['data'] is Map
        ? (resp.data as Map)['data'] as Map<String, dynamic>
        : resp.data as Map<String, dynamic>;
    return Post.fromJson(data);
  }

  Future<PlayerResponse> fetchPlayer(int id) async {
    if (AppConfig.useMockData) return MockData.player(id);
    final resp = await _dio.get('${ApiEndpoints.post(id)}/player');
    return PlayerResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<Post>> fetchRelated(int id) async {
    if (AppConfig.useMockData) return MockData.posts().items.take(10).toList();
    final resp = await _dio.get('${ApiEndpoints.post(id)}/related');
    final list = (resp.data is Map ? (resp.data as Map)['data'] : resp.data);
    return (list as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }

  Future<List<Comment>> fetchComments(int id) async {
    if (AppConfig.useMockData) return MockData.comments();
    final resp = await _dio.get(ApiEndpoints.comments(id));
    final list = (resp.data is Map ? (resp.data as Map)['data'] : resp.data);
    return (list as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}

final movieRepositoryProvider = Provider<MovieRepository>(
  (ref) => MovieRepository(ref.watch(dioProvider)),
);
