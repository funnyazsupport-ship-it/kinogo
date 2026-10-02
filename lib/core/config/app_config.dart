/// Global app configuration.
class AppConfig {
  AppConfig._();

  /// REST gateway base.
  static const String apiBaseUrl = 'https://api.kinogo-10.biz/gateway';

  /// Public site base (used for absolute image URLs and web parsing).
  static const String siteBaseUrl = 'https://kinogo-10.biz';

  /// Update manifest polled by the update service.
  static const String versionManifestUrl =
      'https://kinogo-10.biz/kinogoapp/version.json';

  /// Mobile UA string sent with WebView / API traffic.
  static const String userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 '
      '(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1';
}
