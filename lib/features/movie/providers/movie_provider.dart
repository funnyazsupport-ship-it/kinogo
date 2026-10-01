import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/comment.dart';
import '../../../shared/models/player_response.dart';
import '../../../shared/models/post.dart';
import '../data/movie_repository.dart';

final movieProvider = FutureProvider.family<Post, int>(
  (ref, id) => ref.watch(movieRepositoryProvider).fetchPost(id),
);

final playerProvider = FutureProvider.family<PlayerResponse, int>(
  (ref, id) => ref.watch(movieRepositoryProvider).fetchPlayer(id),
);

final relatedProvider = FutureProvider.family<List<Post>, int>(
  (ref, id) => ref.watch(movieRepositoryProvider).fetchRelated(id),
);

final commentsProvider = FutureProvider.family<List<Comment>, int>(
  (ref, id) => ref.watch(movieRepositoryProvider).fetchComments(id),
);
