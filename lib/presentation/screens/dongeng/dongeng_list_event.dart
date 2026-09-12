import 'package:arunika_app/data/models/response/dongeng_response.dart';

abstract class DongengListEvent {}

/// Fetch the full list of dongeng from the API.
///
/// [highlightProductId], when set, pins the matching story to the front of
/// the list as the featured item — the full list is otherwise unfiltered.
class LoadDongengList extends DongengListEvent {
  final String? highlightProductId;
  LoadDongengList({this.highlightProductId});
}

/// User tapped a story card.
class DongengItemSelected extends DongengListEvent {
  final DongengResponse dongeng;
  DongengItemSelected(this.dongeng);
}

/// Reset the one-shot navigation state back to [DongengListLoaded] after the
/// screen has handled the push, so the user can re-select the same story.
class ResetDongengListNavigation extends DongengListEvent {}

/// Client-side search by title.
class SearchDongeng extends DongengListEvent {
  final String query;
  SearchDongeng(this.query);
}

/// Client-side filter to just the stories the user already owns/unlocked.
class FilterOwnedOnly extends DongengListEvent {
  final bool ownedOnly;
  FilterOwnedOnly(this.ownedOnly);
}

/// Client-side filter by top-level dongeng category. `null` clears it.
class FilterByDongengCategory extends DongengListEvent {
  final String? categoryId;
  FilterByDongengCategory(this.categoryId);
}

/// Client-side filter by dongeng sub-category. `null` clears it.
class FilterByDongengSubCategory extends DongengListEvent {
  final String? subCategoryId;
  FilterByDongengSubCategory(this.subCategoryId);
}
