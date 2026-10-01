import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/api/mock_data.dart';
import '../../../core/config/app_config.dart';
import '../../../shared/models/franchise.dart';
import '../../../shared/models/paginated_response.dart';

/// Franchises (`/v1/franchise`). Mirrors `features/franchise/data/franchise_repository.dart`.
class FranchiseRepository {
  FranchiseRepository(this._dio);
  final Dio _dio;

  Future<PaginatedResponse<Franchise>> fetchList({int page = 1}) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      return MockData.franchises(page: page);
    }
    final resp = await _dio.get(
      ApiEndpoints.franchises,
      queryParameters: {'page': page},
    );
    return PaginatedResponse.fromJson(resp.data, Franchise.fromJson);
  }

  Future<Franchise> fetchDetail(int id) async {
    if (AppConfig.useMockData) return MockData.franchises().items.first;
    final resp = await _dio.get(ApiEndpoints.franchise(id));
    final data = resp.data is Map && (resp.data as Map)['data'] is Map
        ? (resp.data as Map)['data'] as Map<String, dynamic>
        : resp.data as Map<String, dynamic>;
    return Franchise.fromJson(data);
  }
}

final franchiseRepositoryProvider = Provider<FranchiseRepository>(
  (ref) => FranchiseRepository(ref.watch(dioProvider)),
);
