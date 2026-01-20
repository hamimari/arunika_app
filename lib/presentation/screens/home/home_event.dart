abstract class HomeEvent {}

class HomePressed extends HomeEvent {}
class HomeInitial extends HomeEvent {}
class HomeRefresh extends HomeEvent {}
class DongengSelected extends HomeEvent {}
class SearchQueryChanged extends HomeEvent {
  final String query;
  SearchQueryChanged(this.query);
}
