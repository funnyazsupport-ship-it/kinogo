import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_retry_row.dart';
import '../../shared/widgets/movie_card.dart';
import 'providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  void _onFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final results = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        // iOS has no system button for closing the keyboard, so the search
        // bar offers one while the field is being edited.
        leading: _focus.hasFocus
            ? IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 30),
                tooltip: 'Скрыть клавиатуру',
                onPressed: _focus.unfocus,
              )
            : null,
        titleSpacing: _focus.hasFocus ? 0 : null,
        title: TextField(
          controller: _controller,
          focusNode: _focus,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: 'Поиск фильмов и сериалов',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                  )
                : null,
          ),
          onChanged: (v) =>
              ref.read(searchQueryProvider.notifier).state = v,
          onSubmitted: (_) => _focus.unfocus(),
        ),
        actions: const [SizedBox(width: 12)],
      ),
      // Tapping outside the field or scrolling the results also closes it.
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _focus.unfocus,
        child: query.trim().isEmpty
            ? const EmptyState(
                icon: Icons.search,
                message: 'Введите название для поиска',
              )
            : results.when(
                data: (items) => items.isEmpty
                    ? const EmptyState(message: 'Ничего не найдено')
                    : GridView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 160,
                          childAspectRatio: 0.52,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 14,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) => MovieCard(post: items[i]),
                      ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppTheme.accent),
                ),
                error: (_, __) => ErrorRetryRow(
                  onRetry: () => ref.invalidate(searchResultsProvider),
                ),
              ),
      ),
    );
  }
}
