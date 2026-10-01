import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/kinogo_web_service.dart';
import '../../../shared/models/franchise.dart';
import '../../../shared/models/paginated_response.dart';

/// Franchises.
class FranchiseRepository {
  FranchiseRepository(this._service);
  final KinogoWebService _service;

  Future<PaginatedResponse<Franchise>> fetchList({int page = 1}) async {
    return _service.fetchFranchises(page: page);
  }

  Future<Franchise> fetchDetail(int id) async {
    return _service.fetchFranchise(id);
  }
}

final franchiseRepositoryProvider = Provider<FranchiseRepository>(
  (ref) => FranchiseRepository(ref.watch(kinogoWebServiceProvider)),
);
