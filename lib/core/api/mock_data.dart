import '../../shared/models/comment.dart';
import '../../shared/models/filters_config.dart';
import '../../shared/models/franchise.dart';
import '../../shared/models/paginated_response.dart';
import '../../shared/models/player_response.dart';
import '../../shared/models/podborka.dart';
import '../../shared/models/post.dart';

/// Bundled sample data used while [AppConfig.useMockData] is true (e.g. before
/// the gateway's signed-request handshake is configured). Lets the full UI run
/// end-to-end offline. Swap off for production.
class MockData {
  MockData._();

  static const _titles = [
    'Дюна: Часть вторая',
    'Оппенгеймер',
    'Джон Уик 4',
    'Барби',
    'Аватар: Путь воды',
    'Человек-паук: Паутина вселенных',
    'Стражи Галактики 3',
    'Флэш',
    'Миссия невыполнима',
    'Индиана Джонс 5',
    'Убийцы цветочной луны',
    'Переходный возраст',
    'Ведьмак',
    'Локи',
    'Мандалорец',
    'Одни из нас',
    'Töп Ган: Мэверик',
    '王国',
    'Пацаны',
    'Разделение',
  ];

  static List<Post> _posts(int count, {String? category}) {
    return List.generate(count, (i) {
      final t = _titles[i % _titles.length];
      return Post(
        id: (category?.hashCode ?? 0).abs() % 1000 + i + 1,
        title: t,
        year: '${2019 + (i % 6)}',
        kinopoiskRating: 6.0 + (i % 40) / 10.0,
        imdbRating: 6.5 + (i % 35) / 10.0,
        quality: i.isEven ? '4K' : 'HD',
        genres: const ['Фантастика', 'Боевик'],
        countries: const ['США'],
        categorySlug: category,
        isSeries: i % 4 == 0,
        description:
            'Демонстрационное описание для «$t». Реальные данные появятся '
            'после настройки доступа к API.',
      );
    });
  }

  static PaginatedResponse<Post> posts({int page = 1, String? category}) {
    return PaginatedResponse(
      items: _posts(20, category: category),
      page: page,
      totalPages: 5,
      total: 100,
    );
  }

  static Post post(int id) => _posts(1).first;

  static List<Comment> comments() => List.generate(
        6,
        (i) => Comment(
          id: i + 1,
          author: 'Пользователь ${i + 1}',
          text: 'Отличный фильм, рекомендую к просмотру!',
          date: '2024-0${(i % 9) + 1}-12',
          rating: i % 5,
        ),
      );

  static PlayerResponse player(int id) => const PlayerResponse(
        embedUrl: 'https://kinogo-10.biz/',
        variants: [
          PlayerVariant(title: 'Дубляж', url: 'https://kinogo-10.biz/'),
          PlayerVariant(title: 'Оригинал', url: 'https://kinogo-10.biz/'),
        ],
      );

  static PaginatedResponse<Franchise> franchises({int page = 1}) {
    return PaginatedResponse(
      items: List.generate(
        12,
        (i) => Franchise(
          id: i + 1,
          title: ['Marvel', 'Гарри Поттер', 'Форсаж', 'Звёздные войны'][i % 4],
          itemCount: 3 + i,
          items: _posts(4),
        ),
      ),
      page: page,
      totalPages: 2,
    );
  }

  static PaginatedResponse<Podborka> podborki({int page = 1}) {
    return PaginatedResponse(
      items: List.generate(
        10,
        (i) => Podborka(
          id: i + 1,
          title: ['Лучшее за 2024', 'Для вечера', 'Семейные хиты'][i % 3],
          description: 'Подборка из ${5 + i} фильмов',
          itemCount: 5 + i,
          items: _posts(6),
        ),
      ),
      page: page,
      totalPages: 1,
    );
  }

  static FiltersConfig filters() => const FiltersConfig(
        genres: [
          FilterOption(id: 'boevik', title: 'Боевик'),
          FilterOption(id: 'komedia', title: 'Комедия'),
          FilterOption(id: 'drama', title: 'Драма'),
          FilterOption(id: 'triller', title: 'Триллер'),
        ],
        countries: [
          FilterOption(id: 'usa', title: 'США'),
          FilterOption(id: 'russia', title: 'Россия'),
          FilterOption(id: 'korea', title: 'Корея'),
        ],
        years: [
          FilterOption(id: '2024', title: '2024'),
          FilterOption(id: '2023', title: '2023'),
          FilterOption(id: '2022', title: '2022'),
        ],
        qualities: [
          FilterOption(id: '4k', title: '4K'),
          FilterOption(id: 'hd', title: 'HD'),
        ],
      );
}
