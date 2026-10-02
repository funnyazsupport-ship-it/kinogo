import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinogo/core/api/api_providers.dart';
import 'package:kinogo/core/api/kinogo_web_service.dart';
import 'package:kinogo/core/theme/app_theme.dart';
import 'package:kinogo/features/catalog/catalog_screen.dart';
import 'package:kinogo/features/favorites/favorites_screen.dart';
import 'package:kinogo/features/favorites/providers/favorites_provider.dart';
import 'package:kinogo/features/search/search_screen.dart';
import 'package:kinogo/shared/models/filter_state.dart';
import 'package:kinogo/shared/models/filters_config.dart';
import 'package:kinogo/shared/models/paginated_response.dart';
import 'package:kinogo/shared/models/post.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _config = FiltersConfig(
  fields: [
    const FilterField(
      key: 'g',
      label: 'Жанр',
      canCombine: true,
      combinedByDefault: true,
      options: [
        FilterOption(id: 15, title: 'комедия'),
        FilterOption(id: 32, title: 'фантастика'),
      ],
    ),
    const FilterField(
      key: 'c',
      label: 'Страна',
      options: [FilterOption(id: 119, title: 'Россия')],
    ),
    FilterField(
      key: 'y',
      label: 'Год',
      options: [
        for (var y = 2026; y >= 1990; y--)
          FilterOption(id: 3000 - y, title: '$y'),
      ],
    ),
  ],
  sorts: const [
    SortOption(value: 'date', label: 'Последние обновления'),
    SortOption(value: 'kp', label: 'по Кинопоиску'),
  ],
);

class _FakeService extends KinogoWebService {
  final filters = <FilterState>[];

  @override
  Future<FiltersConfig> fetchFiltersConfig() async => _config;

  @override
  Future<PaginatedResponse<Post>> fetchFiltered(
    FilterState filter,
    FiltersConfig config, {
    int page = 1,
  }) async {
    filters.add(filter);
    return PaginatedResponse(
      items: [
        for (var i = 1; i <= 6; i++) Post(id: i, title: 'Фильм $i', year: '2025'),
      ],
      page: page,
      totalPages: 1,
      total: 6,
    );
  }
}

Widget _app(Widget home, {List<Override> overrides = const []}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(theme: AppTheme.dark, home: home),
    );

void main() {
  testWidgets('catalogue filter: pick values, apply, reset', (tester) async {
    final service = _FakeService();
    await tester.pumpWidget(_app(
      const CatalogScreen(),
      overrides: [kinogoWebServiceProvider.overrideWithValue(service)],
    ));
    await tester.pumpAndSettle();

    expect(find.text('Найдено: 6'), findsOneWidget);
    expect(find.text('Сбросить'), findsNothing);

    // Genre: multi-select with the "combine" switch.
    await tester.tap(find.text('Жанр'));
    await tester.pumpAndSettle();
    expect(find.text('Сочетание значений'), findsOneWidget);
    await tester.tap(find.text('комедия'));
    await tester.tap(find.text('фантастика'));
    await tester.pump();
    expect(find.text('Очистить (2)'), findsOneWidget);
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();
    expect(service.filters.last.valuesOf('g'), {15, 32});
    expect(find.text('Жанр: 2'), findsOneWidget);

    // Year: long list, so the sheet has a search box.
    await tester.tap(find.text('Год'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2025');
    await tester.pump();
    expect(find.widgetWithText(ChoiceChip, '2024'), findsNothing);
    await tester.tap(find.widgetWithText(ChoiceChip, '2025'));
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();
    expect(service.filters.last.valuesOf('y'), {3000 - 2025});
    expect(service.filters.last.cookieFor(_config), 'main|date|g=%2B15,32/y=975');

    // Section and sort are single-choice.
    await tester.tap(find.text('Раздел'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сериалы'));
    await tester.pumpAndSettle();
    expect(service.filters.last.section, 'serialy');
    expect(service.filters.last.cookieFor(_config), startsWith('cat__serialy|date|'));

    await tester.tap(find.text('Сбросить'));
    await tester.pumpAndSettle();
    expect(service.filters.last.isDefault, isTrue);
    expect(find.text('Жанр'), findsOneWidget);
  });

  testWidgets('search bar arrow closes the keyboard', (tester) async {
    await tester.pumpWidget(_app(const SearchScreen()));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isTrue);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pump();

    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.byIcon(Icons.keyboard_arrow_down), findsNothing);
  });

  testWidgets('favorites are stored on the device, no account', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final overrides = [sharedPrefsProvider.overrideWithValue(prefs)];

    await tester.pumpWidget(_app(const FavoritesScreen(), overrides: overrides));
    expect(find.textContaining('В избранном пока пусто'), findsOneWidget);
    expect(find.text('Войти'), findsNothing);

    final container = ProviderScope.containerOf(
        tester.element(find.byType(FavoritesScreen)));
    const post = Post(id: 7, title: 'Фильм 7', year: '2025');
    await container.read(favoritesProvider.notifier).toggle(post);
    await tester.pump();
    expect(find.text('Фильм 7'), findsWidgets);

    // Survives a restart: a fresh provider scope reads it back from storage.
    final restarted = ProviderContainer(overrides: overrides);
    addTearDown(restarted.dispose);
    expect(restarted.read(favoritesProvider).single.id, 7);

    await container.read(favoritesProvider.notifier).toggle(post);
    await tester.pump();
    expect(find.text('Фильм 7'), findsNothing);
  });
}
