import 'package:arunika_app/core/auth/auth_notifier.dart';
import 'package:arunika_app/data/models/response/dongeng_category.dart';
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
  List<DongengCategory> _categories = const [];
  String _currentQuery = '';
  bool _ownedOnly = false;
  String? _highlightProductId;
  String? _activeCategoryId;
  String? _activeSubCategoryId;

  DongengListBloc({required this.repository}) : super(DongengListInitial()) {
    on<LoadDongengList>(_onLoad);
    on<DongengItemSelected>(_onSelected);
    on<ResetDongengListNavigation>(_onReset);
    on<SearchDongeng>(_onSearch);
    on<FilterOwnedOnly>(_onFilterOwnedOnly);
    on<FilterByDongengCategory>(_onFilterByCategory);
    on<FilterByDongengSubCategory>(_onFilterBySubCategory);
  }

  List<DongengResponse> _filtered() {
    var result = _lastLoadedList;
    if (_currentQuery.isNotEmpty) {
      result = result
          .where((d) => d.title.toLowerCase().contains(_currentQuery))
          .toList();
    }
    final categoryId = _activeCategoryId;
    if (categoryId != null && categoryId.isNotEmpty) {
      result = result.where((d) => d.categoryId == categoryId).toList();
    }
    final subCategoryId = _activeSubCategoryId;
    if (subCategoryId != null && subCategoryId.isNotEmpty) {
      result = result.where((d) => d.subCategoryId == subCategoryId).toList();
    }
    if (_ownedOnly) {
      result = result.where((d) => d.isUnlocked).toList();
    }
    final highlightId = _highlightProductId;
    if (highlightId != null) {
      final idx = result.indexWhere((d) => d.productId == highlightId);
      if (idx > 0) {
        result = [
          result[idx],
          ...result.sublist(0, idx),
          ...result.sublist(idx + 1),
        ];
      }
    }
    return result;
  }

  DongengListLoaded _loadedState() => DongengListLoaded(
    List.unmodifiable(_filtered()),
    ownedOnly: _ownedOnly,
    categories: _categories,
    activeCategoryId: _activeCategoryId,
    activeSubCategoryId: _activeSubCategoryId,
  );

  Future<void> _onLoad(
    LoadDongengList event,
    Emitter<DongengListState> emit,
  ) async {
    emit(DongengListLoading());
    if (event.highlightProductId != null) {
      _highlightProductId = event.highlightProductId;
    }
    try {
      final results = await Future.wait([
        repository.findAll(),
        repository.getCategories(),
      ]);
      _lastLoadedList = (results[0] as DongengListResult).items;
      _categories = results[1] as List<DongengCategory>;
      emit(_loadedState());
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
      // Record play start — fire and forget, errors suppressed in repository.
      // Guests have no session to attribute this to; skip the call entirely
      // rather than let it 401 (the backend now no-ops it anyway, but this
      // avoids the request altogether for the common guest-browsing case).
      if (locator<AuthNotifier>().isLoggedIn) {
        _historyRepo.recordPlay(event.dongeng.id);
      }
      emit(NavigateToDongengPlayer(full));
    } catch (_) {
      emit(DongengListLoaded(List.unmodifiable(_lastLoadedList)));
    }
  }

  void _onReset(
    ResetDongengListNavigation event,
    Emitter<DongengListState> emit,
  ) {
    emit(_loadedState());
  }

  void _onSearch(SearchDongeng event, Emitter<DongengListState> emit) {
    _currentQuery = event.query.trim().toLowerCase();
    emit(_loadedState());
  }

  void _onFilterOwnedOnly(
    FilterOwnedOnly event,
    Emitter<DongengListState> emit,
  ) {
    _ownedOnly = event.ownedOnly;
    emit(_loadedState());
  }

  void _onFilterByCategory(
    FilterByDongengCategory event,
    Emitter<DongengListState> emit,
  ) {
    _activeCategoryId = event.categoryId;
    _activeSubCategoryId = null;
    emit(_loadedState());
  }

  void _onFilterBySubCategory(
    FilterByDongengSubCategory event,
    Emitter<DongengListState> emit,
  ) {
    _activeSubCategoryId = event.subCategoryId;
    emit(_loadedState());
  }
}
