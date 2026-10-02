import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/post.dart';
import '../data/search_repository.dart';

/// Current search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Search results for the active query. Each query costs a full page load on
/// the site, so typing is debounced instead of searching on every keystroke.
final searchResultsProvider = FutureProvider<List<Post>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return const [];

  var superseded = false;
  ref.onDispose(() => superseded = true);
  await Future<void>.delayed(const Duration(milliseconds: 450));
  if (superseded) return const [];

  final repo = ref.watch(searchRepositoryProvider);
  final res = await repo.fullSearch(query);
  return res.items;
});
