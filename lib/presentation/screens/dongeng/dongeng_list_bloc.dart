import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DongengListBloc extends Bloc<DongengListEvent, DongengListState> {
  final FairyTalesRepository repository;

  List<DongengResponse> _lastLoadedList = const [];

  DongengListBloc({required this.repository}) : super(DongengListInitial()) {
    on<LoadDongengList>(_onLoad);
    on<DongengItemSelected>(_onSelected);
    on<ResetDongengListNavigation>(_onReset);
  }

  Future<void> _onLoad(
    LoadDongengList event,
    Emitter<DongengListState> emit,
  ) async {
    emit(DongengListLoading());
    try {
      final result = await repository.findAll();
      _lastLoadedList = result.items;
      emit(DongengListLoaded(List.unmodifiable(_lastLoadedList)));
    } catch (_) {
      emit(DongengListError('Gagal memuat daftar dongeng. Coba lagi.'));
    }
  }

  // Fetches the full dongeng (with pages) before navigating so the detail
  // screen receives ready-to-render data and never needs to load anything.
  Future<void> _onSelected(
    DongengItemSelected event,
    Emitter<DongengListState> emit,
  ) async {
    emit(DongengListNavigating(List.unmodifiable(_lastLoadedList), event.dongeng.id));
    try {
      final full = await repository.findById(event.dongeng.id);
      emit(NavigateToDongengPlayer(full));
    } catch (_) {
      emit(DongengListLoaded(List.unmodifiable(_lastLoadedList)));
    }
  }

  void _onReset(
    ResetDongengListNavigation event,
    Emitter<DongengListState> emit,
  ) {
    emit(DongengListLoaded(List.unmodifiable(_lastLoadedList)));
  }
}
