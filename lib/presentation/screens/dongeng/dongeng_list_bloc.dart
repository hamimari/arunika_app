import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DongengListBloc extends Bloc<DongengListEvent, DongengListState> {
  DongengListBloc() : super(DongengListInitial()){
    on<DongengSelected>((event, emit) {
      emit(NavigateToDongengPlayer());
    });
  }
}
