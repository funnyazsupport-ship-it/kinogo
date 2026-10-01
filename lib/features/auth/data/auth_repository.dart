import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_providers.dart';
import '../../../core/config/app_config.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../shared/models/auth_tokens.dart';
import '../../../shared/models/user.dart';

/// Authentication + profile. Mirrors `features/auth/data/auth_repository.dart`.
class AuthRepository {
  AuthRepository(this._dio, this._storage);
  final Dio _dio;
  final SecureStorage _storage;

  Future<User> login(String email, String password) =>
      _authenticate(ApiEndpoints.login, {'email': email, 'password': password});

  Future<User> register(String name, String email, String password) =>
      _authenticate(ApiEndpoints.register, {
        'name': name,
        'email': email,
        'password': password,
      });

  Future<User> _authenticate(String path, Map<String, dynamic> body) async {
    if (AppConfig.useMockData) {
      await _storage.saveTokens(accessToken: 'mock', refreshToken: 'mock');
      return User(id: 1, name: body['name']?.toString() ?? 'Гость',
          email: body['email']?.toString());
    }
    final resp = await _dio.post(path, data: body);
    final map = resp.data as Map<String, dynamic>;
    final tokens = AuthTokens.fromJson(map);
    if (tokens.isValid) {
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
    }
    return fetchProfile();
  }

  Future<User> fetchProfile() async {
    if (AppConfig.useMockData) {
      return const User(id: 1, name: 'Гость', email: 'guest@kinogo.app');
    }
    final resp = await _dio.get(ApiEndpoints.userProfile);
    return User.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> logout() async {
    if (!AppConfig.useMockData) {
      try {
        await _dio.post(ApiEndpoints.logout);
      } catch (_) {/* ignore network errors on logout */}
    }
    await _storage.clearTokens();
  }

  Future<bool> get hasSession => _storage.hasSession;
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(dioProvider),
    ref.watch(secureStorageProvider),
  ),
);
