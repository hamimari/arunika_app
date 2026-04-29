import 'package:arunika_app/data/models/response/dongeng_response.dart';

abstract class HomeEvent {}

class HomePressed extends HomeEvent {}

class HomeInitial extends HomeEvent {}

class HomeRefresh extends HomeEvent {}

/// Clears the one-shot navigation state back to a plain HomeState without
/// triggering any API call.
class ResetNavigation extends HomeEvent {}

class DongengSelected extends HomeEvent {
  final DongengResponse dongeng;
  DongengSelected(this.dongeng);
}

/// Fired when the user types in the search box.
/// The bloc debounces 400 ms before hitting the backend.
class SearchQueryChanged extends HomeEvent {
  final String query;
  SearchQueryChanged(this.query);
}

/// Fired when the list is scrolled to the bottom and more items are available.
class LoadMoreDongeng extends HomeEvent {}

