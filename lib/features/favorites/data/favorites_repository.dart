import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/storage/preferences_storage.dart';
import '../../../shared/models/post.dart';

/// Favorites (bookmarks) kept on the device, so no account is needed.
class FavoritesRepository {
  FavoritesRepository(this._prefs);
  final PreferencesStorage _prefs;

  static const _key = 'favorites';

  List<Post> load() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map(Post.fromJson)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> save(List<Post> posts) => _prefs.setString(
        _key,
        jsonEncode(posts.map((p) => p.toJson()).toList()),
      );
}

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(preferencesStorageProvider)),
);
