import 'package:arunika_app/data/models/response/dongeng_response.dart';

abstract class DongengListState {}

class DongengListInitial extends DongengListState {}

class DongengListLoading extends DongengListState {}

class DongengListLoaded extends DongengListState {
  final List<DongengResponse> dongengList;
  DongengListLoaded(this.dongengList);
}

class DongengListError extends DongengListState {
  final String message;
  DongengListError(this.message);
}

/// Emitted while [findById] is in-flight after the user taps a row.
/// Carries the current list so the UI stays visible with a loading overlay.
class DongengListNavigating extends DongengListState {
  final List<DongengResponse> dongengList;
  final String selectedId;
  DongengListNavigating(this.dongengList, this.selectedId);
}

/// One-shot navigation state — carry full dongeng (with pages) to the router.
class NavigateToDongengPlayer extends DongengListState {
  final DongengResponse dongeng;
  NavigateToDongengPlayer(this.dongeng);
}
