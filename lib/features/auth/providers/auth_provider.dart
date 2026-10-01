import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/user.dart';
import '../data/auth_repository.dart';

/// Session state: null = signed out.
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier(this._repo) : super(const AsyncValue.data(null)) {
    _restore();
  }

  final AuthRepository _repo;

  Future<void> _restore() async {
    if (await _repo.hasSession) {
      state = const AsyncValue.loading();
      try {
        state = AsyncValue.data(await _repo.fetchProfile());
      } catch (e, st) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  bool get isAuthenticated => state.valueOrNull != null;

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.login(email, password));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    try {
      state = AsyncValue.data(await _repo.register(name, email, password));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
  }

  void updateUser(User user) => state = AsyncValue.data(user);
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>(
  (ref) => AuthNotifier(ref.watch(authRepositoryProvider)),
);
