/// Gateway endpoint paths, reconstructed verbatim from the original binary.
class ApiEndpoints {
  ApiEndpoints._();

  // Posts (movies / series).
  static const String posts = '/v1/post';
  static String post(Object id) => '/v1/post/$id';
  static String postsByCategory(Object slug) => '/v1/post/by-category/$slug';
  static const String postsCustom = '/v1/post/custom';
  static const String lightSearch = '/v1/post/lightsearch';
  static const String xfSearch = '/v1/post/xfsearch';

  // Filters.
  static const String filters = '/v1/filters';

  // Franchises.
  static const String franchises = '/v1/franchise';
  static String franchise(Object id) => '/v1/franchise/$id';

  // Podborki (collections).
  static const String podborki = '/v1/podborki';

  // Favorites.
  static const String favorites = '/v1/favorites';
  static const String favoriteIds = '/v1/favorites/ids';

  // Comments.
  static String comments(Object postId) => '/v1/comments/$postId';

  // Users.
  static const String userProfile = '/v1/users/profile';
  static const String userAvatar = '/v1/users/avatar';

  // Auth.
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
}
