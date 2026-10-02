import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinogo/core/api/api_providers.dart';
import 'package:kinogo/core/api/kinogo_web_service.dart';
import 'package:kinogo/core/navigation/app_routes.dart';
import 'package:kinogo/core/theme/app_theme.dart';
import 'package:kinogo/features/history/providers/history_provider.dart';
import 'package:kinogo/features/history/providers/watch_progress_provider.dart';
import 'package:kinogo/features/movie/movie_screen.dart';
import 'package:kinogo/features/movie/player_hook.dart';
import 'package:kinogo/shared/models/comment.dart';
import 'package:kinogo/shared/models/paginated_response.dart';
import 'package:kinogo/shared/models/post.dart';
import 'package:kinogo/shared/models/watch_progress.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _episodeStored = '{xxx-0-s01-0-s01e02-0-abc}600.5--2962.64--1790971473423';

class _FakeService extends KinogoWebService {
  final searches = <String>[];

  List<Post> _posts(int from, int count) => [
        for (var i = from; i < from + count; i++)
          Post(id: i, title: 'Фильм $i', year: '2025'),
      ];

  @override
  Future<PaginatedResponse<Post>> fetchHomePosts({int page = 1}) async =>
      PaginatedResponse(items: _posts(page * 100, 10), page: page, totalPages: 3);

  @override
  Future<PaginatedResponse<Post>> search(String query, {int page = 1}) async {
    searches.add('$query#$page');
    return PaginatedResponse(items: _posts(page * 1000, 20), page: page, totalPages: 2);
  }

  @override
  Future<Post> fetchPost(int id) async =>
      Post(id: id, title: 'Невский', year: '2016', isSeries: true);

  @override
  Future<List<Post>> fetchRelated(int id) async => const [];

  @override
  Future<List<Comment>> fetchComments(int id) async => const [];
}

void main() {
  late SharedPreferences prefs;
  late _FakeService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = _FakeService();
  });

  List<Override> overrides() => [
        sharedPrefsProvider.overrideWithValue(prefs),
        kinogoWebServiceProvider.overrideWithValue(service),
      ];

  void iphone(WidgetTester tester) {
    tester.view.physicalSize = const Size(786, 1704); // 393x852 @2x
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
  }

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(Scaffold).first));

  group('WatchProgress', () {
    test('series: episode comes from the player\'s playlist path', () {
      final p = WatchProgress.fromPlayer(
        postId: 1,
        time: 600.5,
        duration: 2962.64,
        stored: _episodeStored,
        titles: const ['Сезон 9', 'Серия 9'],
      );
      expect((p.season, p.episode), (1, 2));
      expect(p.resumeLabel, 'Продолжить — 1 сезон 2 серия с 10:00');
      expect(p.shortLabel, '1 сезон 2 серия · 10:00');
      expect(p.canResume, isTrue);
    });

    test('series: falls back to the selector titles', () {
      final p = WatchProgress.fromPlayer(
        postId: 1,
        time: 75,
        duration: 2400,
        titles: const ['Сезон 3', 'Серия 12', 'Оригинал'],
      );
      expect(p.episodeLabel, '3 сезон 12 серия');
    });

    test('film: only the time, hours when needed', () {
      final p = WatchProgress.fromPlayer(
          postId: 2, time: 3754, duration: 5400, stored: '{xxx-0-abc}3754--5400--1');
      expect(p.isSeries, isFalse);
      expect(p.resumeLabel, 'Продолжить с 1:02:34');
      expect(p.fraction, closeTo(0.695, 0.001));
    });

    test('nothing to continue at the very start or once finished', () {
      WatchProgress at(double time) =>
          WatchProgress.fromPlayer(postId: 1, time: time, duration: 1000);
      expect(at(2).canResume, isFalse);
      expect(at(3).canResume, isTrue);
      expect(at(969).canResume, isTrue);
      expect(at(971).canResume, isFalse);
    });

    test('survives storage', () {
      final p = WatchProgress.fromPlayer(
          postId: 7, time: 600.5, duration: 2962.64, stored: _episodeStored, updatedAt: 42);
      final back = WatchProgress.fromJson(p.toJson());
      expect(back.toJson(), p.toJson());
    });
  });

  test('player hook carries the saved position and the resume flag', () {
    final hook = buildPlayerHook(
      storageKey: 'pljsplayfrom_cinemar.ccabc',
      seed: _episodeStored,
      resume: true,
    );
    expect(hook, contains('KEY = "pljsplayfrom_cinemar.ccabc"'));
    expect(hook, contains('SEED = "$_episodeStored"'));
    expect(hook, contains('RESUME = true'));
    expect(hook, contains('window.$kPlayerChannel.postMessage'));
    expect(RegExp(r'__[A-Z]+__').hasMatch(hook), isFalse,
        reason: 'no placeholder left behind');

    final page = injectPlayerHook('<!doctype html><html><head><title>x</title></head></html>', hook);
    expect(page, startsWith('<!doctype html><html><head><script>'));
    expect(page.indexOf('<script>'), lessThan(page.indexOf('<title>')),
        reason: 'the hook must run before the player\'s own scripts');
    expect(buildPlayerHook(storageKey: 'k'), contains('SEED = null'));
  });

  testWidgets('movie page offers to continue where the user stopped', (tester) async {
    iphone(tester);
    await tester.pumpWidget(ProviderScope(
      overrides: overrides(),
      child: MaterialApp(theme: AppTheme.dark, home: const MovieScreen(id: 1)),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Смотреть'), findsOneWidget);
    expect(find.textContaining('Продолжить'), findsNothing);

    await containerOf(tester).read(watchProgressProvider.notifier).save(
        WatchProgress.fromPlayer(
            postId: 1, time: 600.5, duration: 2962.64, stored: _episodeStored));
    await tester.pump();
    expect(find.text('Продолжить — 1 сезон 2 серия с 10:00'), findsOneWidget);

    // A different post's progress does not leak in.
    await containerOf(tester).read(watchProgressProvider.notifier).clear();
    await containerOf(tester).read(watchProgressProvider.notifier).save(
        WatchProgress.fromPlayer(postId: 2, time: 900, duration: 5400));
    await tester.pump();
    expect(find.textContaining('Продолжить'), findsNothing);
  });

  testWidgets('home shows recently watched; tabs keep their state', (tester) async {
    iphone(tester);
    await tester.pumpWidget(ProviderScope(
      overrides: overrides(),
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: appRouter),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Недавно просмотренные'), findsNothing);
    expect(find.text('Фильм 100'), findsWidgets);

    final container = containerOf(tester);
    await container.read(historyProvider.notifier)
        .add(const Post(id: 2, title: 'Человек-паук', year: '2026'));
    await container.read(historyProvider.notifier)
        .add(const Post(id: 1, title: 'Невский', year: '2016'));
    await container.read(watchProgressProvider.notifier).save(WatchProgress.fromPlayer(
        postId: 1, time: 600.5, duration: 2962.64, stored: _episodeStored));
    await tester.pumpAndSettle();

    expect(find.text('Недавно просмотренные'), findsOneWidget);
    expect(find.text('1 сезон 2 серия'), findsOneWidget);
    expect(find.text('10:00'), findsOneWidget);
    // Most recent first.
    expect(tester.getCenter(find.text('Невский')).dx,
        lessThan(tester.getCenter(find.text('Человек-паук')).dx));

    // Search: the typed query and its results survive a trip to another tab.
    await tester.tap(find.text('Поиск'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'чел');
    await tester.enterText(find.byType(TextField), 'человек');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(service.searches, ['человек#1'], reason: 'typing is debounced');
    expect(find.text('Фильм 1000'), findsWidgets);

    await tester.tap(find.text('История'));
    await tester.pumpAndSettle();
    expect(find.text('1 сезон 2 серия · 10:00'), findsOneWidget);

    await tester.tap(find.text('Поиск'));
    await tester.pumpAndSettle();
    expect(find.text('человек'), findsOneWidget);
    expect(find.text('Фильм 1000'), findsWidgets);
    expect(service.searches, ['человек#1'], reason: 'no reload on coming back');

    // The next page loads on scrolling down.
    await tester.drag(find.text('Фильм 1000').first, const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(service.searches, ['человек#1', 'человек#2']);

    // Clearing history removes the row from the home tab as well.
    await tester.tap(find.text('История'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Очистить'));
    await tester.pumpAndSettle();
    expect(find.text('История просмотров пуста'), findsOneWidget);
    await tester.tap(find.text('Главная'));
    await tester.pumpAndSettle();
    expect(find.text('Недавно просмотренные'), findsNothing);
    expect(container.read(watchProgressProvider), isEmpty);
  });
}
