import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/models/response/user_response.dart';

class HomeState {
  final UserResponse? user;
  final List<DongengResponse> dongengList;
  final String searchQuery;
  final int currentPage;
  final int totalCount;
  final bool isLoadingMore;

  HomeState({
    this.user,
    this.searchQuery = '',
    this.dongengList = const [],
    this.currentPage = 0,
    this.totalCount = 0,
    this.isLoadingMore = false,
  });

  bool get hasMore => dongengList.length < totalCount;

  HomeState copyWith({
    UserResponse? user,
    List<DongengResponse>? dongengList,
    String? searchQuery,
    int? currentPage,
    int? totalCount,
    bool? isLoadingMore,
  }) {
    return HomeState(
      user: user ?? this.user,
      dongengList: dongengList ?? this.dongengList,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Emitted while [findById] is in-flight after the user taps a story card.
class HomeNavigating extends HomeState {
  final String selectedId;
  HomeNavigating({
    UserResponse? user,
    List<DongengResponse> dongengList = const [],
    String searchQuery = '',
    int currentPage = 0,
    int totalCount = 0,
    required this.selectedId,
  }) : super(
          user: user,
          dongengList: dongengList,
          searchQuery: searchQuery,
          currentPage: currentPage,
          totalCount: totalCount,
        );
}

class NavigateToCategoryList extends HomeState {}

/// One-shot navigation state — carries the full dongeng (with pages) and
/// preserves all list state so [ResetNavigation] restores it without a reload.
class NavigateToDongengPlayer extends HomeState {
  final DongengResponse dongeng;
  NavigateToDongengPlayer(this.dongeng, HomeState prev)
      : super(
          user: prev.user,
          dongengList: prev.dongengList,
          searchQuery: prev.searchQuery,
          currentPage: prev.currentPage,
          totalCount: prev.totalCount,
        );
}
