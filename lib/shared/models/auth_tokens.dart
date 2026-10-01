/// Access/refresh token pair. Mirrors `shared/models/auth_tokens.dart`.
class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map) ? json['data'] as Map : json;
    return AuthTokens(
      accessToken:
          '${data['access_token'] ?? data['accessToken'] ?? data['token'] ?? ''}',
      refreshToken: '${data['refresh_token'] ?? data['refreshToken'] ?? ''}',
    );
  }

  bool get isValid => accessToken.isNotEmpty;
}
