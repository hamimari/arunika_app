import 'package:equatable/equatable.dart';

abstract class DongengDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Navigate forward one page (no-op on the last page).
class NextPage extends DongengDetailEvent {}

/// Navigate back one page (no-op on the first page).
class PreviousPage extends DongengDetailEvent {}

/// Jump directly to the page at [pageIndex] (0-based).
class GoToPage extends DongengDetailEvent {
  final int pageIndex;
  GoToPage(this.pageIndex);

  @override
  List<Object?> get props => [pageIndex];
}
