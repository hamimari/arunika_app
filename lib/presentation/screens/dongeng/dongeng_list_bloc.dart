import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/data/repositories/dongeng_history_repository.dart';
import 'package:arunika_app/data/repositories/fairy_tales_repository.dart';
import 'package:arunika_app/di/locator.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/dongeng_list_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DongengListBloc extends Bloc<DongengListEvent, DongengListState> {
  final FairyTalesRepository repository;
  final DongengHistoryRepository _historyRepo =
      locator<DongengHistoryRepository>();

  List<DongengResponse> _lastLoadedList = const [];

  DongengListBloc({required this.repository}) : super(DongengListInitial()) {
    on<LoadDongengList>(_onLoad);
    on<DongengItemSelected>(_onSelected);
    on<ResetDongengListNavigation>(_onReset);
    on<SearchDongeng>(_onSearch);
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
    emit(
      DongengListNavigating(
        List.unmodifiable(_lastLoadedList),
        event.dongeng.id,
      ),
    );
    try {
      final full = await repository.findById(event.dongeng.id);
      // Record play start — fire and forget, errors suppressed in repository
      _historyRepo.recordPlay(event.dongeng.id);
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

  void _onSearch(SearchDongeng event, Emitter<DongengListState> emit) {
    final query = event.query.trim().toLowerCase();
    if (query.isEmpty) {
      emit(DongengListLoaded(List.unmodifiable(_lastLoadedList)));
    } else {
      final filtered = _lastLoadedList
          .where((d) => d.title.toLowerCase().contains(query))
          .toList();
      emit(DongengListLoaded(List.unmodifiable(filtered)));
    }
  }
}
