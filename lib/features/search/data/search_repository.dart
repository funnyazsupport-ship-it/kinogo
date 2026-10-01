import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/kinogo_web_service.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';

/// Search over posts.
class SearchRepository {
  SearchRepository(this._service);
  final KinogoWebService _service;

  Future<List<Post>> lightSearch(String query) async {
    return _service.lightSearch(query);
  }

  Future<PaginatedResponse<Post>> fullSearch(String query, {int page = 1}) async {
    return _service.search(query, page: page);
  }
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => SearchRepository(ref.watch(kinogoWebServiceProvider)),
);
