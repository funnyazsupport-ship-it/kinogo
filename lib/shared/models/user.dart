import '../../core/config/app_config.dart';

/// Authenticated user profile. Mirrors `shared/models/user.dart`.
class User {
  const User({
    required this.id,
    required this.name,
    this.email,
    this.avatar,
    this.group,
  });

  final int id;
  final String name;
  final String? email;
  final String? avatar;
  final String? group;

  String? get avatarUrl {
    final a = avatar;
    if (a == null || a.isEmpty) return null;
    if (a.startsWith('http')) return a;
    return '${AppConfig.siteBaseUrl}${a.startsWith('/') ? '' : '/'}$a';
  }

  factory User.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map) ? json['data'] as Map : json;
    return User(
      id: data['id'] is int
          ? data['id'] as int
          : int.tryParse('${data['id'] ?? ''}') ?? 0,
      name: '${data['name'] ?? data['username'] ?? data['login'] ?? ''}',
      email: data['email']?.toString(),
      avatar: (data['avatar'] ?? data['photo'] ?? data['foto'])?.toString(),
      group: (data['group'] ?? data['role'])?.toString(),
    );
  }

  User copyWith({String? name, String? email, String? avatar}) => User(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        avatar: avatar ?? this.avatar,
        group: group,
      );
}
