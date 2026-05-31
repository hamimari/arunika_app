import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:arunika_app/data/repositories/ar_repository.dart';
import 'package:arunika_app/presentation/screens/vocab/collection_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CollectionBlocHandler extends Bloc<CollectionEvent, CollectionState> {
  final ArRepository repository;

  CollectionBlocHandler({required this.repository})
    : super(CollectionInitial()) {
    on<LoadArCards>(_onLoad);
    on<FilterByCategory>(_onFilterCategory);
    on<FilterBySubCategory>(_onFilterSubCategory);
    on<SearchArCards>(_onSearch);
  }

  Future<void> _onLoad(LoadArCards event, Emitter<CollectionState> emit) async {
    emit(CollectionLoading());
    try {
      final results = await Future.wait([
        repository.findAll(),
        repository.getCategories(),
      ]);
      final cards = results[0] as List<ArCardResponse>;
      final cats = results[1] as dynamic; // List<ArCardCategory>
      final initCatId = event.initialCategoryId;
      final displayed = (initCatId != null && initCatId.isNotEmpty)
          ? cards.where((c) => c.categoryId == initCatId).toList()
          : cards;
      emit(
        CollectionLoaded(
          all: cards,
          displayed: displayed,
          categories: cats,
          activeCategoryId: initCatId,
        ),
      );
    } catch (_) {
      emit(CollectionError('Gagal memuat koleksi kartu AR. Coba lagi.'));
    }
  }

  void _onFilterCategory(
    FilterByCategory event,
    Emitter<CollectionState> emit,
  ) {
    if (state is! CollectionLoaded) return;
    final s = state as CollectionLoaded;
    emit(
      s.copyWith(
        clearCategoryId: event.categoryId == null,
        clearSubCategoryId: true,
        activeCategoryId: event.categoryId,
        displayed: _apply(s.all, event.categoryId, null, s.searchQuery),
      ),
    );
  }

  void _onFilterSubCategory(
    FilterBySubCategory event,
    Emitter<CollectionState> emit,
  ) {
    if (state is! CollectionLoaded) return;
    final s = state as CollectionLoaded;
    emit(
      s.copyWith(
        clearSubCategoryId: event.subCategoryId == null,
        activeSubCategoryId: event.subCategoryId,
        displayed: _apply(
          s.all,
          s.activeCategoryId,
          event.subCategoryId,
          s.searchQuery,
        ),
      ),
    );
  }

  void _onSearch(SearchArCards event, Emitter<CollectionState> emit) {
    if (state is! CollectionLoaded) return;
    final s = state as CollectionLoaded;
    emit(
      s.copyWith(
        searchQuery: event.query,
        displayed: _apply(
          s.all,
          s.activeCategoryId,
          s.activeSubCategoryId,
          event.query,
        ),
      ),
    );
  }

  List<ArCardResponse> _apply(
    List<ArCardResponse> all,
    String? categoryId,
    String? subCategoryId,
    String query,
  ) {
    List<ArCardResponse> result = all;
    if (categoryId != null && categoryId.isNotEmpty) {
      result = result.where((c) => c.categoryId == categoryId).toList();
    }
    if (subCategoryId != null && subCategoryId.isNotEmpty) {
      result = result.where((c) => c.subCategoryId == subCategoryId).toList();
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result
          .where((c) => (c.title ?? '').toLowerCase().contains(q))
          .toList();
    }
    return result;
  }
}
