import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_providers.dart';
import '../../core/storage/preferences_storage.dart';

enum ViewMode { grid, list }

/// Persisted grid/list toggle for browse screens.
/// Mirrors `shared/providers/view_mode_provider.dart`.
class ViewModeNotifier extends StateNotifier<ViewMode> {
  ViewModeNotifier(this._prefs)
      : super(
          _prefs.getString(PreferencesStorage.kViewMode) == 'list'
              ? ViewMode.list
              : ViewMode.grid,
        );

  final PreferencesStorage _prefs;

  void toggle() {
    state = state == ViewMode.grid ? ViewMode.list : ViewMode.grid;
    _prefs.setString(PreferencesStorage.kViewMode, state.name);
  }
}

final viewModeProvider =
    StateNotifierProvider<ViewModeNotifier, ViewMode>(
  (ref) => ViewModeNotifier(ref.watch(preferencesStorageProvider)),
);
