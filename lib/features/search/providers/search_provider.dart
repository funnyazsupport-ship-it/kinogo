import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/post.dart';
import '../data/search_repository.dart';

/// Current search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Debounced-ish full search results for the active query.
final searchResultsProvider = FutureProvider<List<Post>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();
  if (query.isEmpty) return const [];
  final repo = ref.watch(searchRepositoryProvider);
  final res = await repo.fullSearch(query);
  return res.items;
});
