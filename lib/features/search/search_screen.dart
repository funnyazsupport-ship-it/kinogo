import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/pagination/paginated_list_view.dart';
import '../../shared/widgets/empty_state.dart';
import 'providers/search_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  /// The query actually searched for. It trails the typed text: each search
  /// costs a full page load on the site, so typing is debounced.
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_rebuild);
    _controller.addListener(_rebuild);
  }

  void _rebuild() => setState(() {});

  @override
  void dispose() {
    _debounce?.cancel();
    _focus.removeListener(_rebuild);
    _controller.removeListener(_rebuild);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () => _search(text));
  }

  void _search(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (mounted && query != _query) setState(() => _query = query);
  }

  @override
  Widget build(BuildContext context) {
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
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Очистить',
                    onPressed: () {
                      _controller.clear();
                      _search('');
                    },
                  )
                : null,
          ),
          onChanged: _onChanged,
          onSubmitted: (text) {
            _search(text);
            _focus.unfocus();
          },
        ),
        actions: const [SizedBox(width: 12)],
      ),
      // Tapping outside the field or scrolling the results also closes it.
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _focus.unfocus,
        child: _query.isEmpty
            ? const EmptyState(
                icon: Icons.search,
                message: 'Введите название для поиска',
              )
            : _SearchResults(key: ValueKey(_query), query: _query),
      ),
    );
  }
}

class _SearchResults extends ConsumerWidget {
  const _SearchResults({super.key, required this.query});
  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(searchProvider(query));
    final notifier = ref.read(searchProvider(query).notifier);
    return PaginatedPostGrid(
      state: state,
      onLoadMore: notifier.loadMore,
      onRefresh: notifier.refresh,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
    );
  }
}
