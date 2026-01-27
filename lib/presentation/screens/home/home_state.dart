import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/models/response/user_response.dart';

class HomeState {
  final UserResponse? user;
  final List<DongengResponse> dongengList;
  final List<DongengResponse> filteredDongengList;
  final String searchQuery;


  HomeState({
    this.user,
    this.searchQuery = '',
    this.filteredDongengList = const [],
    this.dongengList = const [],
  });

  HomeState copyWith({
    UserResponse? user,
    List<DongengResponse>? filteredDongengList,
    List<DongengResponse>? dongengList,
    String? searchQuery,
  }) {
    return HomeState(
      user: user ?? this.user,
      dongengList: dongengList?? this.dongengList,
      filteredDongengList: filteredDongengList?? this.filteredDongengList,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class NavigateToCategoryList extends HomeState {}
class NavigateToDongengPlayer extends HomeState {
  final DongengResponse dongeng;
  NavigateToDongengPlayer(this.dongeng);
}
