import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/kinogo_web_service.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/podborka.dart';

/// Collections.
class PodborkiRepository {
  PodborkiRepository(this._service);
  final KinogoWebService _service;

  Future<PaginatedResponse<Podborka>> fetchList({int page = 1}) async {
    return _service.fetchPodborki(page: page);
  }
}

final podborkiRepositoryProvider = Provider<PodborkiRepository>(
  (ref) => PodborkiRepository(ref.watch(kinogoWebServiceProvider)),
);
