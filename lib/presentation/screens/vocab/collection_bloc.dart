import 'package:arunika_app/data/models/response/ar_card_category.dart';
import 'package:arunika_app/data/models/response/ar_card_response.dart';
import 'package:equatable/equatable.dart';

abstract class CollectionEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadArCards extends CollectionEvent {
  final String? initialCategoryId;
  LoadArCards({this.initialCategoryId});
  @override
  List<Object?> get props => [initialCategoryId];
}

class FilterByCategory extends CollectionEvent {
  final String? categoryId; // null = show all
  FilterByCategory(this.categoryId);
  @override
  List<Object?> get props => [categoryId];
}

class FilterBySubCategory extends CollectionEvent {
  final String? subCategoryId; // null = show all
  FilterBySubCategory(this.subCategoryId);
  @override
  List<Object?> get props => [subCategoryId];
}

class SearchArCards extends CollectionEvent {
  final String query;
  SearchArCards(this.query);
  @override
  List<Object?> get props => [query];
}

// ─────────────────────────────────────────────────────────────────────────────

abstract class CollectionState extends Equatable {
  @override
  List<Object?> get props => [];
}

class CollectionInitial extends CollectionState {}

class CollectionLoading extends CollectionState {}

class CollectionLoaded extends CollectionState {
  final List<ArCardResponse> all;
  final List<ArCardResponse> displayed;
  final String? activeCategoryId;
  final String? activeSubCategoryId;
  final String searchQuery;
  final List<ArCardCategory>
  categories; // top-level categories with children preloaded

  CollectionLoaded({
    required this.all,
    required this.displayed,
    this.activeCategoryId,
    this.activeSubCategoryId,
    this.searchQuery = '',
    this.categories = const [],
  });

  @override
  List<Object?> get props => [
    all,
    displayed,
    activeCategoryId,
    activeSubCategoryId,
    searchQuery,
    categories,
  ];

  CollectionLoaded copyWith({
    List<ArCardResponse>? all,
    List<ArCardResponse>? displayed,
    String? activeCategoryId,
    String? activeSubCategoryId,
    String? searchQuery,
    List<ArCardCategory>? categories,
    bool clearCategoryId = false,
    bool clearSubCategoryId = false,
  }) {
    return CollectionLoaded(
      all: all ?? this.all,
      displayed: displayed ?? this.displayed,
      activeCategoryId: clearCategoryId
          ? null
          : (activeCategoryId ?? this.activeCategoryId),
      activeSubCategoryId: clearSubCategoryId
          ? null
          : (activeSubCategoryId ?? this.activeSubCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      categories: categories ?? this.categories,
    );
  }
}

class CollectionError extends CollectionState {
  final String message;
  CollectionError(this.message);
  @override
  List<Object?> get props => [message];
}
