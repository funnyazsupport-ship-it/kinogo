import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/franchise.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/pagination/paginated_notifier.dart';
import '../../../shared/pagination/paginated_state.dart';
import '../data/franchise_repository.dart';

class FranchiseListNotifier extends PaginatedNotifier<Franchise> {
  FranchiseListNotifier(this._repo);
  final FranchiseRepository _repo;

  @override
  Future<PaginatedResponse<Franchise>> fetchPage(int page) =>
      _repo.fetchList(page: page);
}

final franchiseListProvider =
    StateNotifierProvider<FranchiseListNotifier, PaginatedState<Franchise>>(
  (ref) => FranchiseListNotifier(ref.watch(franchiseRepositoryProvider)),
);

final franchiseDetailProvider =
    FutureProvider.family<Franchise, int>((ref, id) =>
        ref.watch(franchiseRepositoryProvider).fetchDetail(id));
