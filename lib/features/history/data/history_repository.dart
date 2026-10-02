import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/storage/preferences_storage.dart';
import '../../../shared/models/post.dart';

/// Watch history persisted locally. The original uses sqflite (PRAGMA
/// user_version = 3); here we keep a compact JSON list in preferences, which is
/// enough for the recently-watched row. Mirrors
/// `features/history/data/history_repository.dart`.
class HistoryRepository {
  HistoryRepository(this._prefs);
  final PreferencesStorage _prefs;

  static const _key = 'watch_history';
  static const _max = 60;

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

  Future<void> add(Post post) async {
    final current = load().where((p) => p.id != post.id).toList();
    current.insert(0, post);
    final trimmed = current.take(_max).toList();
    await _prefs.setString(
      _key,
      jsonEncode(trimmed.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> clear() => _prefs.setString(_key, '');
}

final historyRepositoryProvider = Provider<HistoryRepository>(
  (ref) => HistoryRepository(ref.watch(preferencesStorageProvider)),
);
