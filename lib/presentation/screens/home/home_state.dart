import 'package:arunika_app/data/models/response/user_response.dart';

class HomeState {
  final UserResponse? user;

  HomeState({this.user});

  HomeState copyWith({UserResponse? user}) {
    return HomeState(
      user: user ?? this.user,
    );
  }
}

class NavigateToCategoryList extends HomeState {}
