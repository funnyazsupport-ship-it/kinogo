import 'package:dio/dio.dart';

import '../../storage/secure_storage.dart';
import '../api_endpoints.dart';

/// Attaches the bearer access token and transparently refreshes it on 401,
/// retrying the original request once. Mirrors
/// `core/api/interceptors/auth_interceptor.dart`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage storage,
    required Dio refreshClient,
  })  : _storage = storage,
        _refreshClient = refreshClient;

  final SecureStorage _storage;

  /// A bare Dio (no auth interceptor) used for the refresh call to avoid
  /// recursion.
  final Dio _refreshClient;

  bool _refreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final isRefreshCall =
        err.requestOptions.path.contains(ApiEndpoints.refresh);

    if (!is401 || isRefreshCall || _refreshing) {
      return handler.next(err);
    }

    _refreshing = true;
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _storage.clearTokens();
        return handler.next(err);
      }

      final resp = await _refreshClient.post(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
      );
      final data = resp.data as Map<String, dynamic>;
      final newAccess = (data['access_token'] ?? data['accessToken']) as String?;
      final newRefresh =
          (data['refresh_token'] ?? data['refreshToken']) as String?;

      if (newAccess == null) {
        await _storage.clearTokens();
        return handler.next(err);
      }
      await _storage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh ?? refreshToken,
      );

      // Retry the original request with the new token.
      final req = err.requestOptions;
      req.headers['Authorization'] = 'Bearer $newAccess';
      final retry = await _refreshClient.fetch(req);
      return handler.resolve(retry);
    } catch (_) {
      await _storage.clearTokens();
      return handler.next(err);
    } finally {
      _refreshing = false;
    }
  }
}
