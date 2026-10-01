/// Global app configuration.
///
/// Public hosts/paths mirror the original Android build. Any credentials or
/// signing secrets required by the gateway are intentionally NOT hardcoded —
/// they must be supplied at runtime by the operator who owns the backend
/// (see [SignatureConfig] / [SignatureInterceptor]).
class AppConfig {
  AppConfig._();

  /// REST gateway base. All `/v1/...` and `/auth/...` paths hang off this.
  static const String apiBaseUrl = 'https://api.kinogo-10.biz/gateway';

  /// Public site base (used for absolute image URLs and web fallbacks).
  static const String siteBaseUrl = 'https://kinogo-10.biz';

  /// Update manifest polled by the update service.
  static const String versionManifestUrl =
      'https://kinogo-10.biz/kinogoapp/version.json';

  /// Mobile UA string the original app sends with WebView / API traffic.
  static const String userAgent =
      'Mozilla/5.0 (Linux; Android 11; Mobile) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36';

  /// When the API cannot be reached or authenticated, serve bundled mock data
  /// so the UI is usable during development. Set to false for production once
  /// the backend credentials are configured.
  static const bool useMockData = true;
}
