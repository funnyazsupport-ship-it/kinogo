import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/storage/preferences_storage.dart';
import '../../../shared/models/watch_progress.dart';

/// Watch positions by post id, kept on the device.
class WatchProgressNotifier extends StateNotifier<Map<int, WatchProgress>> {
  WatchProgressNotifier(this._prefs) : super(_load(_prefs));
  final PreferencesStorage _prefs;

  static const _key = 'watch_progress';
  static const _max = 200;

  static Map<int, WatchProgress> _load(PreferencesStorage prefs) {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const {};
    try {
      return {
        for (final item in (jsonDecode(raw) as List).whereType<Map<String, dynamic>>())
          if (WatchProgress.fromJson(item) case final p when p.postId != 0) p.postId: p,
      };
    } catch (_) {
      return const {};
    }
  }

  Future<void> save(WatchProgress progress) {
    final next = {...state, progress.postId: progress};
    if (next.length > _max) {
      final oldest = next.values.reduce((a, b) => a.updatedAt <= b.updatedAt ? a : b);
      next.remove(oldest.postId);
    }
    state = next;
    return _persist();
  }

  Future<void> clear() {
    state = const {};
    return _persist();
  }

  Future<void> _persist() => _prefs.setString(
        _key,
        jsonEncode(state.values.map((p) => p.toJson()).toList()),
      );
}

final watchProgressProvider =
    StateNotifierProvider<WatchProgressNotifier, Map<int, WatchProgress>>(
  (ref) => WatchProgressNotifier(ref.watch(preferencesStorageProvider)),
);
