import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/kinogo_web_service.dart';
import '../../../shared/models/comment.dart';
import '../../../shared/models/player_response.dart';
import '../../../shared/models/post.dart';

/// Loads a single movie, its player, related items and comments.
class MovieRepository {
  MovieRepository(this._service);
  final KinogoWebService _service;

  Future<Post> fetchPost(int id) async {
    return _service.fetchPost(id);
  }

  Future<PlayerResponse> fetchPlayer(int id) async {
    return _service.fetchPlayer(id);
  }

  Future<List<Post>> fetchRelated(int id) async {
    final home = await _service.fetchHomePosts(page: 1);
    return home.items.where((p) => p.id != id).take(10).toList();
  }

  Future<List<Comment>> fetchComments(int id) async {
    return _service.fetchComments(id);
  }
}

final movieRepositoryProvider = Provider<MovieRepository>(
  (ref) => MovieRepository(ref.watch(kinogoWebServiceProvider)),
);
