/// Static category catalogue (slug → Russian label → bundled showcase image),
/// reconstructed from `core/api/categories_config.dart` and the 48 category
/// images shipped in the original APK (`assets/images/categories/*.webp`).
library;

enum CategoryKind {
  /// Browsed via `/v1/post/by-category/<slug>`.
  posts,

  /// Franchise list (`/v1/franchise`).
  franchises,

  /// Collections (`/v1/podborki`).
  podborki,
}

class CategoryConfig {
  const CategoryConfig(this.slug, this.title, {this.kind = CategoryKind.posts});

  final String slug;
  final String title;
  final CategoryKind kind;

  String get image => 'assets/images/categories/$slug.webp';
}

/// Order roughly follows the original showcase grid; special sections first.
const List<CategoryConfig> kCategories = [
  CategoryConfig('filmy', 'Фильмы'),
  CategoryConfig('serialy', 'Сериалы'),
  CategoryConfig('multfilmy', 'Мультфильмы'),
  CategoryConfig('multserialy', 'Мультсериалы'),
  CategoryConfig('anime', 'Аниме'),
  CategoryConfig('doramy', 'Дорамы'),
  CategoryConfig('tv-shou', 'ТВ-шоу'),
  CategoryConfig('top-filmy', 'Топ фильмы'),
  CategoryConfig('v1new', 'Новинки'),
  CategoryConfig('twenty', 'Топ 20'),
  CategoryConfig('franchises', 'Франшизы', kind: CategoryKind.franchises),
  CategoryConfig('podborki', 'Подборки', kind: CategoryKind.podborki),
  // Genres.
  CategoryConfig('boevik', 'Боевик'),
  CategoryConfig('komedia', 'Комедия'),
  CategoryConfig('drama', 'Драма'),
  CategoryConfig('melodrama', 'Мелодрама'),
  CategoryConfig('triller', 'Триллер'),
  CategoryConfig('detektiv', 'Детектив'),
  CategoryConfig('fantastika', 'Фантастика'),
  CategoryConfig('fentezi', 'Фэнтези'),
  CategoryConfig('uzhasy', 'Ужасы'),
  CategoryConfig('prikluchenia', 'Приключения'),
  CategoryConfig('kriminal', 'Криминал'),
  CategoryConfig('romance', 'Романтические'),
  CategoryConfig('muzikl', 'Мюзикл'),
  CategoryConfig('sport', 'Спорт'),
  CategoryConfig('voennye', 'Военные'),
  CategoryConfig('istoricheskie', 'Исторические'),
  CategoryConfig('biografia', 'Биография'),
  CategoryConfig('dokumentalnye', 'Документальные'),
  CategoryConfig('detskie', 'Детские'),
  CategoryConfig('family', 'Семейные'),
  CategoryConfig('book_adaptations', 'Экранизации книг'),
  CategoryConfig('zombies', 'Зомби'),
  CategoryConfig('vestern', 'Вестерн'),
  // Studios / universes.
  CategoryConfig('marvel', 'Marvel'),
  CategoryConfig('dc', 'DC'),
  CategoryConfig('netflix', 'Netflix'),
  // Countries.
  CategoryConfig('russia', 'Россия'),
  CategoryConfig('ukraine', 'Украина'),
  CategoryConfig('usa', 'США'),
  CategoryConfig('korea', 'Корея'),
  CategoryConfig('turkey', 'Турция'),
  CategoryConfig('india', 'Индия'),
  CategoryConfig('france', 'Франция'),
  CategoryConfig('italia', 'Италия'),
  CategoryConfig('germany', 'Германия'),
  CategoryConfig('kazakhstan', 'Казахстан'),
];
