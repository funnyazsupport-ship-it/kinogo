import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// Operator-supplied configuration for the gateway's `X-App-Signature` scheme.
///
/// The production gateway rejects unsigned requests with HTTP 403. The signing
/// secret and client fingerprint belong to whoever runs the backend and are
/// NOT bundled with the app. Inject them at startup, e.g.:
///
/// ```dart
/// SignatureConfig.configure(
///   secret: const String.fromEnvironment('KINOGO_APP_SECRET'),
///   clientFingerprint: const String.fromEnvironment('KINOGO_CLIENT_ID'),
/// );
/// ```
///
/// Supplying these via `--dart-define` keeps them out of source control.
class SignatureConfig {
  SignatureConfig._();

  static String _secret = '';
  static String _clientFingerprint = '';
  static String origin = 'biz.kinogo.app';

  static bool get isConfigured => _secret.isNotEmpty;

  static void configure({
    required String secret,
    required String clientFingerprint,
    String? origin,
  }) {
    _secret = secret;
    _clientFingerprint = clientFingerprint;
    if (origin != null) SignatureConfig.origin = origin;
  }

  static String get secret => _secret;
  static String get clientFingerprint => _clientFingerprint;
}

/// Adds the `X-App-Signature` header expected by the gateway.
///
/// Mirrors the observable contract of the original client (signature derived
/// from the client fingerprint, request origin and a current timestamp). The
/// exact server-side algorithm is defined by the backend; the HMAC-SHA256
/// construction below is the conventional default and can be adjusted to match
/// once the operator confirms it. When no secret is configured the interceptor
/// is a no-op (requests go out unsigned and the gateway may answer 403).
class SignatureInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    if (SignatureConfig.isConfigured) {
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final payload = [
        options.method.toUpperCase(),
        options.uri.path,
        SignatureConfig.clientFingerprint,
        SignatureConfig.origin,
        timestamp,
      ].join('\n');

      final signature = Hmac(sha256, utf8.encode(SignatureConfig.secret))
          .convert(utf8.encode(payload))
          .toString();

      options.headers['X-App-Signature'] = signature;
      options.headers['X-Timestamp'] = timestamp;
      options.headers['X-Client'] = SignatureConfig.clientFingerprint;
      options.headers['Origin'] = SignatureConfig.origin;
    }
    handler.next(options);
  }
}
