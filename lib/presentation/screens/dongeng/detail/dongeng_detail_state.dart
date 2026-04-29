import 'package:arunika_app/data/models/response/dongeng_page.dart';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:equatable/equatable.dart';

class DongengDetailState extends Equatable {
  final DongengResponse dongeng;
  final int currentPageIndex;

  const DongengDetailState({
    required this.dongeng,
    this.currentPageIndex = 0,
  });

  List<DongengPage> get pages => dongeng.pages;
  DongengPage? get currentPage =>
      pages.isNotEmpty ? pages[currentPageIndex] : null;
  bool get isFirstPage => currentPageIndex == 0;
  bool get isLastPage =>
      pages.isEmpty || currentPageIndex == pages.length - 1;

  DongengDetailState copyWith({int? currentPageIndex}) {
    return DongengDetailState(
      dongeng: dongeng,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
    );
  }

  @override
  List<Object?> get props => [dongeng, currentPageIndex];
}
