import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/mock_data.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/podborka.dart';

/// Collections (`/v1/podborki`). Mirrors `features/podborki/data/podborki_repository.dart`.
class PodborkiRepository {
  PodborkiRepository(this._dio);
  final Dio _dio;

  Future<PaginatedResponse<Podborka>> fetchList({int page = 1}) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return MockData.podborki(page: page);
    }
    final resp = await _dio.get(
      ApiEndpoints.podborki,
      queryParameters: {'page': page},
    );
    return PaginatedResponse.fromJson(resp.data, Podborka.fromJson);
  }
}

final podborkiRepositoryProvider = Provider<PodborkiRepository>(
  (ref) => PodborkiRepository(ref.watch(dioProvider)),
);
