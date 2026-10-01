import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/pagination/paginated_list_view.dart';
import 'providers/category_detail_provider.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({super.key, required this.slug, this.title});

  final String slug;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(categoryDetailProvider(slug));
    final notifier = ref.read(categoryDetailProvider(slug).notifier);

    return Scaffold(
      appBar: AppBar(title: Text(title ?? slug)),
      body: PaginatedPostGrid(
        state: state,
        onLoadMore: notifier.loadMore,
        onRefresh: notifier.refresh,
      ),
    );
  }
}
