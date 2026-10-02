// Live check of the site parser: `dart run tool/site_smoke_test.dart`.
// Exits non-zero when any section comes back empty.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:kinogo/core/api/kinogo_web_service.dart';
import 'package:kinogo/shared/models/filter_state.dart';

Future<void> main() async {
  final service = KinogoWebService();
  final failures = <String>[];
  void check(String name, bool ok, [String details = '']) {
    print('${ok ? 'OK  ' : 'FAIL'} $name $details');
    if (!ok) failures.add(name);
  }

  final home = await service.fetchHomePosts();
  check('home', home.items.isNotEmpty, '${home.items.length} posts, pages=${home.totalPages}');
  for (final p in home.items.take(2)) {
    print('     [${p.id}] ${p.title} (${p.year}) q=${p.quality} rating=${p.rating} poster=${p.posterUrl}');
  }
  final home2 = await service.fetchHomePosts(page: 2);
  check('home page 2', home2.items.isNotEmpty && home2.items.first.id != home.items.first.id);

  for (final slug in ['boevik', 'usa', 'marvel', 'top-filmy', 'twenty', 'korea', 'book_adaptations', 'romance', 'zombies']) {
    final c = await service.fetchCategoryPosts(slug);
    check('category $slug', c.items.isNotEmpty, '${c.items.length} posts, pages=${c.totalPages}');
  }
  final cat2 = await service.fetchCategoryPosts('usa', page: 2);
  check('category usa page 2', cat2.items.isNotEmpty);

  final id = home.items.first.id;
  final post = await service.fetchPost(id);
  check('post', post.title.isNotEmpty && post.description != null,
      '${post.title} (${post.year}) kp=${post.kinopoiskRating} imdb=${post.imdbRating} q=${post.quality} genres=${post.genres} dur=${post.duration}');
  print('     poster=${post.posterUrl}');
  print('     descr=${post.description?.substring(0, post.description!.length.clamp(0, 90))}...');

  final player = await service.fetchPlayer(id);
  check('player', player.hasPlayer, '${player.variants.length} variants');
  for (final v in player.variants) {
    print('     ${v.title}: ${Uri.parse(v.url).host}');
  }

  final comments = await service.fetchComments(id);
  check('comments', comments.isNotEmpty, '${comments.length}');
  if (comments.isNotEmpty) print('     ${comments.first.author} (${comments.first.date}): ${comments.first.text}');

  final search = await service.search('Человек');
  check('search', search.items.isNotEmpty, '${search.items.length} posts, pages=${search.totalPages}');
  final search2 = await service.search('Человек', page: 2);
  check('search page 2', search2.items.isNotEmpty);

  final franchises = await service.fetchFranchises();
  check('franchises', franchises.items.isNotEmpty, '${franchises.items.length}, pages=${franchises.totalPages}');
  if (franchises.items.isNotEmpty) {
    final f = franchises.items.first;
    print('     [${f.id}] ${f.title} count=${f.itemCount} poster=${f.posterUrl}');
    final detail = await service.fetchFranchise(f.id);
    check('franchise detail', detail.items.isNotEmpty, '${detail.title}: ${detail.items.map((p) => '${p.title} ${p.year}').join(', ')}');
    // Detail opened without the list having been loaded first.
    final cold = await KinogoWebService().fetchFranchise(f.id);
    check('franchise detail (cold)', cold.items.isNotEmpty);
  }

  final podborki = await service.fetchPodborki();
  check('podborki', podborki.items.isNotEmpty, '${podborki.items.length}');
  if (podborki.items.isNotEmpty) {
    final p = podborki.items.first;
    print('     ${p.title} slug=${p.slug} count=${p.itemCount} poster=${p.posterUrl}');
    final posts = await service.fetchCategoryPosts(p.slug!);
    check('podborka posts', posts.items.isNotEmpty, '${posts.items.length}');
  }

  // Catalogue filter: комедия + Россия + 2025.
  final config = await service.fetchFiltersConfig();
  check('filter config', config.fields.length >= 6 && config.sorts.length >= 6,
      '${config.fields.map((f) => '${f.label}=${f.options.length}').join(', ')}, '
      'sorts=${config.sorts.length}');
  int idOf(String field, String title) => config.fields
      .firstWhere((f) => f.key == field)
      .options
      .firstWhere((o) => o.title == title)
      .id;
  final filter = const FilterState()
      .withField('g', {idOf('g', 'комедия')})
      .withField('c', {idOf('c', 'Россия')})
      .withField('y', {idOf('y', '2025')});
  print('     cookie=${filter.cookieFor(config)}');
  final filtered = await service.fetchFiltered(filter, config);
  check(
    'filter комедия+Россия+2025',
    // The genre filter uses a field the list cards do not always show, so
    // only year and country are checked on each card.
    filtered.items.isNotEmpty &&
        (filtered.total ?? 0) > 0 &&
        filtered.items
            .every((p) => p.year == '2025' && p.countries.contains('Россия')),
    '${filtered.items.length} posts, total=${filtered.total}, pages=${filtered.totalPages}',
  );
  final filtered2 = await service.fetchFiltered(filter, config, page: 2);
  check('filter page 2',
      filtered2.items.isNotEmpty && filtered2.items.first.id != filtered.items.first.id);
  final inSection = await service.fetchFiltered(
      filter.copyWith(section: 'serialy', sort: 'kp'), config);
  check('filter in section serialy',
      inSection.items.isNotEmpty && inSection.items.every((p) => p.isSeries),
      '${inSection.items.length} posts, total=${inSection.total}');
  final nothing = await service.fetchFiltered(
    const FilterState()
        .withField('y', {idOf('y', '1960')})
        .withField('c', {idOf('c', 'Азербайджан')})
        .withField('g', {idOf('g', 'новости'), idOf('g', 'игра')}),
    config,
  );
  check('filter with no matches', nothing.items.isEmpty, 'total=${nothing.total}');

  print(failures.isEmpty ? '\nAll checks passed.' : '\nFAILED: ${failures.join(', ')}');
  exit(failures.isEmpty ? 0 : 1);
}
