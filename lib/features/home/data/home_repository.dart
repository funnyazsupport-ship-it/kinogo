import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/kinogo_web_service.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';

/// Loads the home feed.
class HomeRepository {
  HomeRepository(this._service);
  final KinogoWebService _service;

  Future<PaginatedResponse<Post>> fetchPosts({int page = 1}) async {
    return _service.fetchHomePosts(page: page);
  }
}

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(ref.watch(kinogoWebServiceProvider)),
);
