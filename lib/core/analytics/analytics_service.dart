import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Thin analytics wrapper (mirrors `core/analytics/analytics_service.dart`).
///
/// Firebase is initialised softly: without a bundled `GoogleService-Info.plist`
/// / `google-services.json` the init throws, which we swallow so the app still
/// runs. Drop the real config files in to enable reporting.
class AnalyticsService {
  AnalyticsService._(this._analytics);

  final FirebaseAnalytics? _analytics;

  static Future<AnalyticsService> init() async {
    FirebaseAnalytics? analytics;
    try {
      await Firebase.initializeApp();
      analytics = FirebaseAnalytics.instance;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: Firebase not configured, disabled ($e)');
      }
    }
    return AnalyticsService._(analytics);
  }

  bool get enabled => _analytics != null;

  Future<void> logScreen(String name) async {
    await _analytics?.logScreenView(screenName: name);
  }

  Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    await _analytics?.logEvent(name: name, parameters: params);
  }
}
