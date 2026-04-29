import 'dart:async';

import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/presentation/screens/home/home_event.dart';
import 'package:arunika_app/presentation/screens/home/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _perPage = 10;

// Internal event — only dispatched by the debounce timer inside HomeBloc.
class _ExecuteSearch extends HomeEvent {
  final String query;
  _ExecuteSearch(this.query);
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FairyTalesRepository repository;

  Timer? _searchDebounce;

  HomeBloc({required this.repository}) : super(HomeState()) {
    on<HomeInitial>(_onInitial);
    on<HomeRefresh>(_onRefresh);
    on<HomePressed>((_, emit) => emit(NavigateToCategoryList()));
    on<DongengSelected>(_onSelected);
    on<ResetNavigation>((_, emit) => emit(state.copyWith()));
    on<SearchQueryChanged>(_onSearchChanged);
    on<_ExecuteSearch>(_onExecuteSearch);
    on<LoadMoreDongeng>(_onLoadMore);
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    return super.close();
  }

  Future<void> _onInitial(HomeInitial event, Emitter<HomeState> emit) async {
    final profile = await LocalProfileStorage.get();
    if (profile != null) emit(state.copyWith(user: profile));

    try {
      final result = await repository.findAll(page: 1, perPage: _perPage);
      emit(state.copyWith(
        dongengList: result.items,
        currentPage: result.page,
        totalCount: result.total,
      ));
    } catch (_) {}
  }

  Future<void> _onRefresh(HomeRefresh event, Emitter<HomeState> emit) async {
    final profile = await LocalProfileStorage.get();
    if (profile != null) emit(state.copyWith(user: profile));

    try {
      final result = await repository.findAll(
        search: state.searchQuery,
        page: 1,
        perPage: _perPage,
      );
      emit(state.copyWith(
        dongengList: result.items,
        currentPage: result.page,
        totalCount: result.total,
      ));
    } catch (_) {}
  }

  Future<void> _onSelected(
    DongengSelected event,
    Emitter<HomeState> emit,
  ) async {
    final snapshot = state;
    emit(HomeNavigating(
      user: snapshot.user,
      dongengList: snapshot.dongengList,
      searchQuery: snapshot.searchQuery,
      currentPage: snapshot.currentPage,
      totalCount: snapshot.totalCount,
      selectedId: event.dongeng.id,
    ));
    try {
      final full = await repository.findById(event.dongeng.id);
      emit(NavigateToDongengPlayer(full, snapshot));
    } catch (_) {
      emit(snapshot.copyWith());
    }
  }

  void _onSearchChanged(SearchQueryChanged event, Emitter<HomeState> emit) {
    _searchDebounce?.cancel();
    emit(state.copyWith(searchQuery: event.query));
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!isClosed) add(_ExecuteSearch(event.query));
    });
  }

  Future<void> _onExecuteSearch(
    _ExecuteSearch event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final result = await repository.findAll(
        search: event.query,
        page: 1,
        perPage: _perPage,
      );
      emit(state.copyWith(
        dongengList: result.items,
        currentPage: result.page,
        totalCount: result.total,
      ));
    } catch (_) {}
  }

  Future<void> _onLoadMore(
    LoadMoreDongeng event,
    Emitter<HomeState> emit,
  ) async {
    if (!state.hasMore || state.isLoadingMore) return;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.currentPage + 1;
      final result = await repository.findAll(
        search: state.searchQuery,
        page: nextPage,
        perPage: _perPage,
      );
      final merged = List<DongengResponse>.from(state.dongengList)
        ..addAll(result.items);
      emit(state.copyWith(
        dongengList: merged,
        currentPage: result.page,
        totalCount: result.total,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }
}
