import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DongengDetailBloc extends Bloc<DongengDetailEvent, DongengDetailState> {
  DongengDetailBloc({required DongengResponse dongeng})
      : super(DongengDetailState(dongeng: dongeng)) {
    on<NextPage>(_onNextPage);
    on<PreviousPage>(_onPreviousPage);
    on<GoToPage>(_onGoToPage);
  }

  void _onNextPage(NextPage event, Emitter<DongengDetailState> emit) {
    if (state.isLastPage) return;
    emit(state.copyWith(currentPageIndex: state.currentPageIndex + 1));
  }

  void _onPreviousPage(PreviousPage event, Emitter<DongengDetailState> emit) {
    if (state.isFirstPage) return;
    emit(state.copyWith(currentPageIndex: state.currentPageIndex - 1));
  }

  void _onGoToPage(GoToPage event, Emitter<DongengDetailState> emit) {
    final idx = event.pageIndex.clamp(0, state.pages.length - 1);
    emit(state.copyWith(currentPageIndex: idx));
  }
}
