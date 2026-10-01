import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: user == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.surfaceVariant,
                    child: Icon(Icons.person_outline,
                        size: 40, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Вы не авторизованы'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.push('/profile/auth'),
                    child: const Text('Войти или зарегистрироваться'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: AppTheme.surfaceVariant,
                        backgroundImage: user.avatarUrl != null
                            ? CachedNetworkImageProvider(user.avatarUrl!)
                            : null,
                        child: user.avatarUrl == null
                            ? Text(
                                user.name.isNotEmpty
                                    ? user.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(fontSize: 32),
                              )
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(user.name,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      if (user.email != null)
                        Text(user.email!,
                            style: const TextStyle(
                                color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                ListTile(
                  leading: const Icon(Icons.favorite_border),
                  title: const Text('Избранное'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/favorites'),
                ),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('История просмотров'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/history'),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text('Выйти',
                      style: TextStyle(color: Colors.redAccent)),
                  onTap: () => ref.read(authProvider.notifier).logout(),
                ),
              ],
            ),
    );
  }
}
