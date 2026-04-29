import 'package:arunika_app/data/models/response/dongeng_response.dart';

abstract class DongengListEvent {}

/// Fetch the full list of dongeng from the API.
class LoadDongengList extends DongengListEvent {}

/// User tapped a story card.
class DongengItemSelected extends DongengListEvent {
  final DongengResponse dongeng;
  DongengItemSelected(this.dongeng);
}

/// Reset the one-shot navigation state back to [DongengListLoaded] after the
/// screen has handled the push, so the user can re-select the same story.
class ResetDongengListNavigation extends DongengListEvent {}
