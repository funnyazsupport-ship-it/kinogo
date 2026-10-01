import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/post.dart';
import '../data/history_repository.dart';

class HistoryNotifier extends StateNotifier<List<Post>> {
  HistoryNotifier(this._repo) : super(_repo.load());
  final HistoryRepository _repo;

  Future<void> add(Post post) async {
    await _repo.add(post);
    state = _repo.load();
  }

  Future<void> clear() async {
    await _repo.clear();
    state = const [];
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<Post>>(
  (ref) => HistoryNotifier(ref.watch(historyRepositoryProvider)),
);
