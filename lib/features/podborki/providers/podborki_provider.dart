import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/podborka.dart';
import '../../../shared/pagination/paginated_notifier.dart';
import '../../../shared/pagination/paginated_state.dart';
import '../data/podborki_repository.dart';

class PodborkiNotifier extends PaginatedNotifier<Podborka> {
  PodborkiNotifier(this._repo);
  final PodborkiRepository _repo;

  @override
  Future<PaginatedResponse<Podborka>> fetchPage(int page) =>
      _repo.fetchList(page: page);
}

final podborkiProvider =
    StateNotifierProvider<PodborkiNotifier, PaginatedState<Podborka>>(
  (ref) => PodborkiNotifier(ref.watch(podborkiRepositoryProvider)),
);
