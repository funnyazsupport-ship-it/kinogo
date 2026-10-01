import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/analytics/analytics_service.dart';
import 'core/api/api_providers.dart';
import 'core/api/interceptors/signature_interceptor.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
    ),
  );

  // Gateway signing credentials are supplied by the operator via --dart-define
  // (never bundled). Without them the client runs unsigned; see AppConfig.
  const secret = String.fromEnvironment('KINOGO_APP_SECRET');
  const clientId = String.fromEnvironment('KINOGO_CLIENT_ID');
  if (secret.isNotEmpty) {
    SignatureConfig.configure(secret: secret, clientFingerprint: clientId);
  }

  final prefs = await SharedPreferences.getInstance();
  await AnalyticsService.init();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const KinogoApp(),
    ),
  );
}
