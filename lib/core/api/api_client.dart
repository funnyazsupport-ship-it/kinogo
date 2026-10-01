import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/log_interceptor.dart';
import 'interceptors/signature_interceptor.dart';

/// Builds the configured Dio instance for the gateway. Mirrors
/// `core/api/api_client.dart`.
class ApiClient {
  ApiClient(this._storage) {
    dio = _build(withAuth: true);
  }

  final SecureStorage _storage;
  late final Dio dio;

  Dio _build({required bool withAuth}) {
    final options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Accept': 'application/json',
        'User-Agent': AppConfig.userAgent,
      },
      responseType: ResponseType.json,
    );

    final client = Dio(options);
    // A bare client (signature only) used by the auth interceptor for refresh.
    final refreshClient = Dio(options)..interceptors.add(SignatureInterceptor());

    client.interceptors.add(SignatureInterceptor());
    if (withAuth) {
      client.interceptors.add(
        AuthInterceptor(storage: _storage, refreshClient: refreshClient),
      );
    }
    client.interceptors.add(AppLogInterceptor());
    return client;
  }
}
