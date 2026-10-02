import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:html_unescape/html_unescape.dart';

import '../../shared/models/comment.dart';
import '../../shared/models/filter_state.dart';
import '../../shared/models/filters_config.dart';
import '../../shared/models/franchise.dart';
import '../../shared/models/paginated_response.dart';
import '../../shared/models/player_response.dart';
import '../../shared/models/podborka.dart';
import '../../shared/models/post.dart';
import '../config/app_config.dart';

/// Loads data by parsing the public site's mobile template
/// (`/templates/smartphone/`, served for the mobile [AppConfig.userAgent]).
class KinogoWebService {
  KinogoWebService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.siteBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'User-Agent': AppConfig.userAgent,
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'ru,en;q=0.9',
        },
        responseType: ResponseType.plain,
      ),
    );
  }

  late final Dio _dio;
  final _unescape = HtmlUnescape();

  /// Movie pages are requested by several providers at once (details,
  /// related, comments), so the in-flight/last few pages are shared — but only
  /// briefly: the player links inside a page stop working after a while.
  final _pageCache = <int, ({Future<String> page, DateTime loadedAt})>{};
  static const _pageCacheTtl = Duration(minutes: 2);

  /// Franchise id → site path, filled while listing franchises.
  final _franchisePaths = <int, String>{};

  /// App category slugs that live under a different path on the site.
  static const _slugPaths = <String, String>{
    'twenty': 'top-filmy',
    'romance': 'xfsearch/podborki/Про любовь',
    'zombies': 'xfsearch/podborki/Про зомби',
    'book_adaptations': 'xfsearch/podborki/Экранизация книг',
    'marvel': 'xfsearch/podborki/Marvel',
    'dc': 'xfsearch/podborki/DC',
    'netflix': 'xfsearch/podborki/Netflix',
    'russia': 'xfsearch/strana-xfsearch/Россия',
    'ukraine': 'xfsearch/strana-xfsearch/Украина',
    'usa': 'xfsearch/strana-xfsearch/США',
    'korea': 'xfsearch/strana-xfsearch/Корея Южная',
    'turkey': 'xfsearch/strana-xfsearch/Турция',
    'india': 'xfsearch/strana-xfsearch/Индия',
    'france': 'xfsearch/strana-xfsearch/Франция',
    'italia': 'xfsearch/strana-xfsearch/Италия',
    'germany': 'xfsearch/strana-xfsearch/Германия',
    'kazakhstan': 'xfsearch/strana-xfsearch/Казахстан',
  };

  /// Redirects are followed by hand: the automatic follow-up request does not
  /// carry the mobile User-Agent, and the site then answers with its desktop
  /// template, which this parser does not understand.
  Future<String> _get(String path, {Map<String, String>? headers}) async {
    var target = path;
    for (var hop = 0; hop < 4; hop++) {
      final resp = await _dio.get<String>(
        target,
        options: Options(
          headers: headers,
          followRedirects: false,
          validateStatus: (s) => s != null && s >= 200 && s < 400,
        ),
      );
      final location = resp.headers.value('location');
      if ((resp.statusCode ?? 200) < 300 || location == null) return resp.data ?? '';
      target = resp.realUri.resolve(location).toString();
    }
    throw DioException(
      requestOptions: RequestOptions(path: path),
      message: 'Too many redirects',
    );
  }

  Future<String> _moviePage(int id, {bool fresh = false}) {
    final cached = _pageCache[id];
    if (!fresh &&
        cached != null &&
        DateTime.now().difference(cached.loadedAt) < _pageCacheTtl) {
      return cached.page;
    }
    _pageCache.remove(id);
    if (_pageCache.length >= 8) _pageCache.remove(_pageCache.keys.first);
    // `/<id>-.html` redirects to the canonical `/<id>-<slug>.html`.
    final future = _get('/$id-.html');
    _pageCache[id] = (page: future, loadedAt: DateTime.now());
    future.then<void>((_) {}, onError: (Object _) {
      if (identical(_pageCache[id]?.page, future)) _pageCache.remove(id);
    });
    return future;
  }

  String _withPage(String path, int page) =>
      page <= 1 ? path : '${path}page/$page/';

  /// Percent-encodes a (possibly already encoded) site path, keeping slashes.
  String _encodePath(String path) {
    final segments = path
        .split('/')
        .where((s) => s.isNotEmpty)
        .map((s) => Uri.encodeComponent(_decode(s)));
    return '/${segments.join('/')}/';
  }

  String _decode(String s) {
    try {
      return Uri.decodeComponent(s);
    } catch (_) {
      return s;
    }
  }

  // ---------------------------------------------------------------- lists

  Future<PaginatedResponse<Post>> fetchHomePosts({int page = 1}) async {
    final html = await _get(_withPage('/', page));
    return _parsePostList(html, page: page);
  }

  Future<PaginatedResponse<Post>> fetchCategoryPosts(String slug, {int page = 1}) async {
    final path = _encodePath(_slugPaths[slug] ?? slug);
    final html = await _get(_withPage(path, page));
    return _parsePostList(html, page: page, category: slug);
  }

  Future<PaginatedResponse<Post>> search(String query, {int page = 1}) async {
    final q = query.trim();
    if (q.isEmpty) {
      return PaginatedResponse(items: const [], page: page, totalPages: page, total: 0);
    }
    final base = '/search/${Uri.encodeComponent(q)}';
    final html = await _get(page <= 1 ? base : '$base/page/$page/');
    return _parsePostList(html, page: page);
  }

  Future<List<Post>> lightSearch(String query) async {
    if (query.trim().isEmpty) return const [];
    final res = await search(query, page: 1);
    return res.items.take(8).toList();
  }

  // --------------------------------------------------------------- filter

  /// The filter's fields and options are published on the home page.
  Future<FiltersConfig> fetchFiltersConfig() async {
    final html = await _get('/');
    final raw = _first(html, r'window\.__XSORT__\s*=\s*(\{.*?\})\s*;?\s*</script>');
    if (raw == null) throw const FormatException('Filter config not found');
    final filter = (jsonDecode(raw) as Map<String, dynamic>)['filter'] as Map<String, dynamic>;

    final fields = <FilterField>[];
    filter.forEach((key, value) {
      final data = value as Map<String, dynamic>;
      final options = <FilterOption>[
        for (final o in (data['values'] as List? ?? const []).whereType<Map<String, dynamic>>())
          if (int.tryParse('${o['id']}') case final id?)
            FilterOption(id: id, title: _text('${o['value'] ?? ''}')),
      ];
      if (options.isEmpty) return;
      fields.add(FilterField(
        key: key,
        label: '${data['title'] ?? data['label'] ?? key}',
        options: options,
        canCombine: data['combine_select'] == true,
        combinedByDefault: data['combined'] == true,
      ));
    });
    // Most used first; anything the site adds later keeps its own order.
    const order = ['g', 'c', 'y', 'p', 'q', 'tr'];
    int rank(FilterField f) {
      final i = order.indexOf(f.key);
      return i < 0 ? order.length : i;
    }

    fields.sort((a, b) => rank(a).compareTo(rank(b)));

    final sorts = <SortOption>[
      for (final m in RegExp(r'class="js-xs-sort[^"]*"[^>]*data-value="([^"]+)"[^>]*>([^<]*)<')
          .allMatches(html))
        SortOption(value: m.group(1)!, label: _text(m.group(2)!)),
    ];
    return FiltersConfig(fields: fields, sorts: sorts);
  }

  /// The site reads the filter from the `xsort` cookie, per page.
  Future<PaginatedResponse<Post>> fetchFiltered(
    FilterState filter,
    FiltersConfig config, {
    int page = 1,
  }) async {
    final path = filter.section.isEmpty ? '/' : _encodePath(filter.section);
    final String html;
    try {
      html = await _get(
        _withPage(path, page),
        headers: {'Cookie': 'xsort=${filter.cookieFor(config)}'},
      );
    } on DioException catch (e) {
      // Nothing matching the filter is answered with a 404 page.
      if (e.response?.statusCode != 404) rethrow;
      return PaginatedResponse(items: const [], page: page, totalPages: page, total: 0);
    }
    final list = _parsePostList(html, page: page);
    return PaginatedResponse(
      items: list.items,
      page: list.page,
      totalPages: list.totalPages,
      total: int.tryParse(_first(html, r'id="xsort__count"[^>]*>\s*(\d+)') ?? ''),
    );
  }

  PaginatedResponse<Post> _parsePostList(String html, {int page = 1, String? category}) {
    final posts = <Post>[];

    final articles = RegExp(
      r'<article[^>]+id="post-(\d+)"[^>]*>(.*?)</article>',
      dotAll: true,
    ).allMatches(html);
    for (final m in articles) {
      final post = _parseShortArticle(int.parse(m.group(1)!), m.group(2)!, category);
      if (post != null) posts.add(post);
    }

    // The "top" pages use a different card (`<a class="topitem">`).
    if (posts.isEmpty) {
      final tops = RegExp(
        r'<a[^>]+href="[^"]*/(\d+)-[^"/]*\.html"[^>]*class="topitem[^"]*"[^>]*>(.*?)</a>',
        dotAll: true,
      ).allMatches(html);
      for (final m in tops) {
        posts.add(_parseTopItem(int.parse(m.group(1)!), m.group(2)!, category));
      }
    }

    return PaginatedResponse(
      items: posts,
      page: page,
      totalPages: _parseTotalPages(html, page),
      total: posts.length,
    );
  }

  Post? _parseShortArticle(int id, String block, String? category) {
    final rawTitle = _first(block, r'<h2[^>]*class="article__title"[^>]*>(.*?)</h2>');
    if (rawTitle == null) return null;
    final (title, titleYear) = _splitTitle(_text(rawTitle));
    final genres = _linkTexts(_first(block, r'<b>Жанр[^<]*</b>(.*?)</div>') ?? '');

    return Post(
      id: id,
      title: title.isNotEmpty ? title : 'Фильм $id',
      poster: _image(_first(block, r'class="article__poster"[^>]*>\s*(<img[^>]*>)') ?? block),
      year: _first(block, r'year-teg-xfsearch/(\d{4})') ?? titleYear,
      rating: _siteRating(block),
      quality: _textOrNull(_first(block, r'class="article__quality"[^>]*>\s*<b>[^<]*</b>([^<]*)')),
      genres: genres,
      countries: _linkTexts(_first(block, r'<b>Страна[^<]*</b>(.*?)</div>') ?? ''),
      description: _textOrNull(_first(block, r'<div class="article__text">(.*?)</div>')),
      duration: _textOrNull(_first(block, r'<b>Длительность:</b>([^<]*)')),
      categorySlug: category,
      isSeries: _isSeries(genres),
    );
  }

  Post _parseTopItem(int id, String block, String? category) {
    final (title, titleYear) =
        _splitTitle(_text(_first(block, r'class="topitem-title"[^>]*>(.*?)</h2>') ?? ''));
    return Post(
      id: id,
      title: title.isNotEmpty ? title : 'Фильм $id',
      poster: _image(block),
      year: titleYear,
      kinopoiskRating: double.tryParse(
          _first(block, r'class="top_item-kp"[^>]*>\s*<span>[^<]*</span>\s*([\d.]+)') ?? ''),
      imdbRating: double.tryParse(
          _first(block, r'class="top_item-imdb"[^>]*>\s*<span>[^<]*</span>\s*([\d.]+)') ?? ''),
      rating: double.tryParse(_first(block, r'class="kinogo-rate"[^>]*>\s*([\d.]+)') ?? ''),
      description: _textOrNull(_first(block, r'class="topitem-descr"[^>]*>(.*?)</div>')),
      categorySlug: category,
    );
  }

  int _parseTotalPages(String html, int page) {
    final nav = _first(html, r'<div class="navigation">(.*?)</div>');
    if (nav == null) return page;
    var last = page;
    for (final m in RegExp(r'>(\d+)</(?:a|span)>').allMatches(nav)) {
      final n = int.tryParse(m.group(1)!) ?? 0;
      if (n > last) last = n;
    }
    return last;
  }

  // ---------------------------------------------------------------- movie

  Future<Post> fetchPost(int id) async {
    final html = await _moviePage(id);
    final article = _first(html, r'<article[^>]+id="post-\d+"[^>]*>(.*?)</article>') ?? html;

    final (title, titleYear) =
        _splitTitle(_text(_first(article, r'<h1[^>]*>(.*?)</h1>') ?? ''));
    final genres =
        _linkTexts(_first(article, r'class="article__info-genre"[^>]*>(.*?)</div>') ?? '');

    // The JSON-LD thumbnail is the full-size poster; the inline one is a mini.
    final poster = _first(html, r'"thumbnail":\{[^}]*"url":"([^"]+)"')?.replaceAll(r'\/', '/') ??
        _image(_first(article, r'class="article__poster"[^>]*>\s*(<img[^>]*>)') ?? '');

    final description = _first(
          article,
          r'<div class="article__text">(.*?)<div class="article__info">',
        ) ??
        _first(article, r'<div class="article__text">(.*?)</div>');

    return Post(
      id: id,
      title: title.isNotEmpty ? title : 'Фильм',
      poster: poster,
      year: _first(article, r'year-teg-xfsearch/(\d{4})') ?? titleYear,
      kinopoiskRating: double.tryParse(
          _first(article, r'class="article__info-kp[^"]*"[^>]*>\s*<b>[^<]*</b>\s*([\d.]+)') ?? ''),
      imdbRating: double.tryParse(
          _first(article, r'class="article__info-imdb[^"]*"[^>]*>\s*<b>[^<]*</b>\s*([\d.]+)') ?? ''),
      rating: _siteRating(article),
      quality: _textOrNull(_first(article, r'Лучшее качество:\s*</b>([^<]*)')),
      genres: genres,
      countries:
          _linkTexts(_first(article, r'class="article__info-country"[^>]*>(.*?)</div>') ?? ''),
      description: _textOrNull(description),
      duration: _textOrNull(
          _first(article, r'class="article__info-time"[^>]*>\s*<b>[^<]*</b>([^<]*)')),
      isSeries: _isSeries(genres),
    );
  }

  /// Player links are short-lived and tied to the page they came with, so
  /// the page is always loaded anew here; a remembered link ends in the
  /// player's "HTTP 403" error.
  Future<PlayerResponse> fetchPlayer(int id) async {
    final html = await _moviePage(id, fresh: true);
    final variants = <PlayerVariant>[];

    void add(String? rawSrc, String title) {
      var src = _unescape.convert(rawSrc?.trim() ?? '');
      if (src.startsWith('//')) src = 'https:$src';
      if (!src.startsWith('http')) return;
      if (variants.any((v) => v.url == src)) return;
      variants.add(PlayerVariant(title: title, url: src));
    }

    final tabs = _first(html, r'<ul[^>]*class="[^"]*js-player-tabs[^"]*"[^>]*>(.*?)</ul>') ?? '';
    for (final m in RegExp(r'<li[^>]+data-src="([^"]+)"[^>]*>(.*?)</li>', dotAll: true)
        .allMatches(tabs)) {
      final title = _text(m.group(2) ?? '');
      add(m.group(1), title.isNotEmpty ? title : 'Плеер ${variants.length + 1}');
    }

    if (variants.isEmpty) {
      final container =
          _first(html, r'class="[^"]*js-player-container[^"]*"[^>]*>(.*?)</iframe>') ?? '';
      add(_first(container, r'<iframe[^>]+(?:data-src|src)="([^"]+)"'), 'Смотреть онлайн');
    }

    add(_first(html, r'class="[^"]*js-player-trailer[^"]*"[^>]*data-src="([^"]+)"'), 'Трейлер');

    final primary = variants.isNotEmpty ? variants.first.url : '';
    return PlayerResponse(embedUrl: primary, variants: variants);
  }

  /// Loads the page of the site's main player (PlayerJS-based "Cinemar") so
  /// it can be shown directly instead of inside a frame, which is what lets
  /// the app follow the watch position. Returns null for any other player.
  Future<EmbedPage?> fetchEmbedPage(String url) async {
    try {
      // The player host only answers requests coming from the site.
      final html = await _get(url, headers: {'Referer': '${AppConfig.siteBaseUrl}/'});
      final cuid = _first(html, r'"cuid":"([^"]+)"');
      if (cuid == null || !html.contains('Cinemar(')) return null;
      return EmbedPage(
        html: html,
        // Where PlayerJS keeps the position: `pljsplayfrom_<host><cuid>`.
        storageKey: 'pljsplayfrom_${Uri.parse(url).host}$cuid',
      );
    } on DioException {
      return null;
    }
  }

  /// The "Рекомендации к просмотру" block of a movie page.
  Future<List<Post>> fetchRelated(int id) async {
    final html = await _moviePage(id);
    final posts = <Post>[];
    final pattern = RegExp(
      r'<a[^>]+href="[^"]*/(\d+)-[^"/]*\.html"[^>]*class="relatednews__item"[^>]*>(.*?)</a>',
      dotAll: true,
    );
    for (final m in pattern.allMatches(html)) {
      final postId = int.parse(m.group(1)!);
      if (postId == id) continue;
      final block = m.group(2)!;
      final (title, year) = _splitTitle(_text(block));
      posts.add(Post(
        id: postId,
        title: title.isNotEmpty ? title : 'Фильм $postId',
        poster: _image(block),
        year: year,
      ));
    }
    return posts;
  }

  Future<List<Comment>> fetchComments(int id) async {
    final html = await _moviePage(id);
    final comments = <Comment>[];
    final pattern = RegExp(
      r'class="comment__login[^"]*"[^>]*>(.*?)</div>([^<]*)</div>\s*'
      r'<div class="comment__body"[^>]*>\s*<div id=.comm-id-(\d+).>(.*?)</div>\s*</div>',
      dotAll: true,
    );
    final seen = <String>{};
    for (final m in pattern.allMatches(html)) {
      final text = _text(m.group(4) ?? '');
      // The pinned "top comment" is repeated further down the list.
      if (text.isEmpty || !seen.add(m.group(3)!)) continue;
      final author = _text(m.group(1) ?? '');
      comments.add(Comment(
        id: int.tryParse(m.group(3) ?? '') ?? 0,
        author: author.isNotEmpty ? author : 'Гость',
        text: text,
        date: _textOrNull(m.group(2)),
      ));
    }
    return comments;
  }

  // ------------------------------------------------- franchises / podborki

  Future<PaginatedResponse<Franchise>> fetchFranchises({int page = 1}) async {
    final html = await _get(_withPage('/franchise/', page));
    final items = <Franchise>[];
    final pattern = RegExp(
      r'<a[^>]+href="(/franchise/(\d+)-[^"]*\.html)"[^>]*class="franchise[ "][^>]*>(.*?)</a>',
      dotAll: true,
    );
    for (final m in pattern.allMatches(html)) {
      final id = int.parse(m.group(2)!);
      final block = m.group(3)!;
      _franchisePaths[id] = m.group(1)!;
      items.add(Franchise(
        id: id,
        title: _text(_first(block, r'class="franchise__title"[^>]*>(.*?)</h3>') ?? ''),
        poster: _image(block),
        itemCount:
            int.tryParse(_first(block, r'class="franchise__count"[^>]*>\s*(\d+)') ?? '') ?? 0,
      ));
    }
    return PaginatedResponse(
      items: items,
      page: page,
      totalPages: _parseTotalPages(html, page),
      total: items.length,
    );
  }

  Future<Franchise> fetchFranchise(int id) async {
    final html = await _get(_franchisePaths[id] ?? '/franchise/$id-.html');
    final items = <Post>[];
    final pattern = RegExp(
      r'<a[^>]+href="[^"]*/(\d+)-[^"/]*\.html"[^>]*class="fr-item[^"]*"[^>]*>(.*?)</a>',
      dotAll: true,
    );
    for (final m in pattern.allMatches(html)) {
      final block = m.group(2)!;
      final postId = int.parse(m.group(1)!);
      final title = _text(
          _first(block, r'class="fr-item__title"[^>]*>(.*?)<div class="fr-item__subtitle"') ??
              _first(block, r'class="fr-item__title"[^>]*>(.*?)</div>') ??
              '');
      final subtitle = _text(_first(block, r'class="fr-item__subtitle"[^>]*>(.*?)</div>') ?? '');
      items.add(Post(
        id: postId,
        title: title.isNotEmpty ? title : 'Фильм $postId',
        poster: _image(block),
        year: _first(block, r'class="fr-item__meta"[^>]*>\s*(\d{4})'),
        kinopoiskRating: double.tryParse(
            _first(block, r'class="fr-item__kprate"[^>]*>\s*([\d.]+)') ?? ''),
        isSeries: subtitle.toLowerCase().contains('сериал'),
      ));
    }
    return Franchise(
      id: id,
      title: _text(_first(html, r'<h1[^>]*class="franchise__title"[^>]*>(.*?)</h1>') ?? ''),
      poster: _first(html, r'<img[^>]+src="([^"]+)"[^>]*class="franchise__image"'),
      itemCount: items.length,
      items: items,
    );
  }

  /// The site lists every collection on a single page.
  Future<PaginatedResponse<Podborka>> fetchPodborki({int page = 1}) async {
    if (page > 1) {
      return PaginatedResponse(items: const [], page: page, totalPages: 1, total: 0);
    }
    final html = await _get('/podborki.html');
    final items = <Podborka>[];
    final pattern = RegExp(
      r'<a[^>]+href="/(xfsearch/podborki/[^"]+)"[^>]*class="[^"]*podborki__item[^"]*"[^>]*>(.*?)</a>',
      dotAll: true,
    );
    for (final m in pattern.allMatches(html)) {
      final block = m.group(2)!;
      final title = _text(block.replaceAll(
          RegExp(r'<div class="podborki__count">.*?</div>', dotAll: true), ''));
      if (title.isEmpty) continue;
      items.add(Podborka(
        id: items.length + 1,
        title: title,
        slug: _decode(m.group(1)!).replaceAll(RegExp(r'/+$'), ''),
        poster: _first(block, r'data-bg="([^"]+)"'),
        itemCount:
            int.tryParse(_first(block, r'class="podborki__count"[^>]*>\s*(\d+)') ?? '') ?? 0,
      ));
    }
    return PaginatedResponse(items: items, page: 1, totalPages: 1, total: items.length);
  }

  // -------------------------------------------------------------- helpers

  String? _first(String source, String pattern) =>
      RegExp(pattern, dotAll: true).firstMatch(source)?.group(1);

  /// Lazy-loaded images keep the real URL in `data-src`.
  String? _image(String html) {
    final src = _first(html, r'<img[^>]+data-src="([^"]+)"') ??
        _first(html, r'<img[^>]+src="([^"]+)"');
    if (src == null || src.startsWith('data:') || src.endsWith('dot.gif')) return null;
    return src;
  }

  List<String> _linkTexts(String html) => RegExp(r'<a[^>]*>(.*?)</a>', dotAll: true)
      .allMatches(html)
      .map((m) => _text(m.group(1) ?? ''))
      .where((t) => t.isNotEmpty)
      .toList();

  /// "Название (2026)" → ("Название", "2026").
  (String, String?) _splitTitle(String title) {
    final m = RegExp(r'^(.*?)\s*\((\d{4})\)\s*$').firstMatch(title);
    if (m == null) return (title, null);
    return (m.group(1)!.trim(), m.group(2));
  }

  /// Site rating is shown as "3.7/5 (8841 гол.)".
  double? _siteRating(String html) =>
      double.tryParse(_first(html, r'class="rating__votes"[^>]*>(?:\s*<span[^>]*>)?\s*([\d.]+)') ?? '');

  bool _isSeries(List<String> genres) =>
      genres.any((g) => g.toLowerCase().contains('сериал'));

  String? _textOrNull(String? html) {
    if (html == null) return null;
    final text = _text(html);
    return text.isEmpty ? null : text;
  }

  String _text(String html) {
    var text = html.replaceAll(RegExp(r'<[^>]*>'), ' ');
    text = _unescape.convert(text);
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
