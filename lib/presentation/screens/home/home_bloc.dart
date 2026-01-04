import 'package:arunika_app/core/storage/LocalProfileStorage.dart';
import 'package:arunika_app/presentation/screens/home/home_event.dart';
import 'package:arunika_app/presentation/screens/home/home_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeState()) {
    on<HomeInitial>((event, emit) async {
      final profile = await LocalProfileStorage.get();
      if (profile != null) {
        emit(state.copyWith(user: profile));
      }
    });
    on<HomeRefresh>((event, emit) async {
      final profile = await LocalProfileStorage.get();
      if (profile != null) {
        emit(state.copyWith(user: profile));
      }
    });
    on<HomePressed>((event, emit) async {
      emit(NavigateToCategoryList());
    });
    on<DongengSelected>((event, emit) {
      emit(NavigateToDongengPlayer());
    });
  }
}
