import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../models/post.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_retry_row.dart';
import '../widgets/movie_card.dart';
import 'paginated_state.dart';

/// A poster grid bound to a [PaginatedState] that calls [onLoadMore] near the
/// bottom and [onRefresh] on pull. Mirrors `shared/pagination/paginated_list_view.dart`.
class PaginatedPostGrid extends StatefulWidget {
  const PaginatedPostGrid({
    super.key,
    required this.state,
    required this.onLoadMore,
    required this.onRefresh,
    this.header,
    this.emptyMessage = 'Ничего не найдено',
  });

  final PaginatedState<Post> state;
  final VoidCallback onLoadMore;
  final Future<void> Function() onRefresh;
  final Widget? header;
  final String emptyMessage;

  @override
  State<PaginatedPostGrid> createState() => _PaginatedPostGridState();
}

class _PaginatedPostGridState extends State<PaginatedPostGrid> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    if (_controller.position.pixels >=
        _controller.position.maxScrollExtent - 600) {
      widget.onLoadMore();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;

    if (s.isLoadingFirst) {
      return const Center(child: CircularProgressIndicator());
    }
    if (s.error != null && s.items.isEmpty) {
      return ErrorRetryRow(onRetry: widget.onRefresh);
    }
    if (s.isEmpty) {
      return EmptyState(icon: Icons.movie_filter_outlined, message: widget.emptyMessage);
    }

    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        controller: _controller,
        slivers: [
          if (widget.header != null)
            SliverToBoxAdapter(child: widget.header),
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 160,
                childAspectRatio: 0.52,
                crossAxisSpacing: 10,
                mainAxisSpacing: 14,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => MovieCard(post: s.items[i]),
                childCount: s.items.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: s.isLoadingMore
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
