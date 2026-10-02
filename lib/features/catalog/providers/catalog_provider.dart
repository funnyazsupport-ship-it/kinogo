import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/kinogo_web_service.dart';
import '../../../shared/models/filter_state.dart';
import '../../../shared/models/filters_config.dart';
import '../../../shared/models/paginated_response.dart';
import '../../../shared/models/post.dart';
import '../../../shared/pagination/paginated_notifier.dart';
import '../../../shared/pagination/paginated_state.dart';

/// Filter fields and options offered by the site.
final filtersConfigProvider = FutureProvider<FiltersConfig>(
  (ref) => ref.watch(kinogoWebServiceProvider).fetchFiltersConfig(),
);

/// Filters chosen on the catalogue screen.
final catalogFilterProvider =
    StateProvider<FilterState>((ref) => const FilterState());

class CatalogNotifier extends PaginatedNotifier<Post> {
  CatalogNotifier(this._service, this._config, this._filter);
  final KinogoWebService _service;
  final FiltersConfig _config;
  final FilterState _filter;

  @override
  Future<PaginatedResponse<Post>> fetchPage(int page) =>
      _service.fetchFiltered(_filter, _config, page: page);
}

/// Posts matching [catalogFilterProvider]; reloads whenever the filter changes.
final catalogProvider = StateNotifierProvider.autoDispose
    .family<CatalogNotifier, PaginatedState<Post>, FiltersConfig>(
  (ref, config) => CatalogNotifier(
    ref.watch(kinogoWebServiceProvider),
    config,
    ref.watch(catalogFilterProvider),
  ),
);
