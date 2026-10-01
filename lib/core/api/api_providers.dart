import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/preferences_storage.dart';
import '../storage/secure_storage.dart';
import 'api_client.dart';
import 'kinogo_web_service.dart';

/// Base dependency-injection providers. Mirrors `core/api/api_providers.dart`.

final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());

final sharedPrefsProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Override in main() with the resolved instance');
});

final preferencesStorageProvider = Provider<PreferencesStorage>(
  (ref) => PreferencesStorage(ref.watch(sharedPrefsProvider)),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(secureStorageProvider)),
);

final dioProvider = Provider<Dio>((ref) => ref.watch(apiClientProvider).dio);

final kinogoWebServiceProvider = Provider<KinogoWebService>(
  (ref) => KinogoWebService(),
);
