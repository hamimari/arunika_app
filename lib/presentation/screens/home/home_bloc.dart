import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/presentation/screens/home/home_event.dart';
import 'package:arunika_app/presentation/screens/home/home_state.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FairyTalesRepository repository;
  HomeBloc({required this.repository}) : super(HomeState()) {
    on<HomeInitial>((event, emit) async {
      final profile = await LocalProfileStorage.get();
      if (profile != null) {
        emit(state.copyWith(user: profile));
      }

      try {
        final List<DongengResponse> responses = await repository.findAll();
        emit(state.copyWith(dongengList: responses, filteredDongengList: responses));
      } on DioException catch (e) {
        rethrow;
      }
    });
    on<HomeRefresh>((event, emit) async {
      final profile = await LocalProfileStorage.get();
      if (profile != null) {
        emit(state.copyWith(user: profile));
      }
      try {
        final List<DongengResponse> responses = await repository.findAll();
        emit(state.copyWith(
            dongengList: responses,
            filteredDongengList: responses));
      } on DioException catch (e) {
        rethrow;
      }
    });
    on<HomePressed>((event, emit) async {
      emit(NavigateToCategoryList());
    });
    on<DongengSelected>((event, emit) {
      emit(NavigateToDongengPlayer());
    });
    on<SearchQueryChanged>((event, emit) {
      final q = event.query.toLowerCase();
      final filtered = state.dongengList.where((story) {
        final title = story.title.toLowerCase();
        return title.contains(q);
      }).toList();
      emit(
        state.copyWith(
          searchQuery: event.query,
          filteredDongengList: filtered,
        ),
      );
    });

  }
}
