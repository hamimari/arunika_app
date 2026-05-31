import 'package:arunika_app/data/models/response/tracing_item.dart';
import 'package:equatable/equatable.dart';

abstract class TracingListEvent extends Equatable {
  const TracingListEvent();
  @override
  List<Object?> get props => [];
}

class LoadTracingItems extends TracingListEvent {
  final String? type;
  const LoadTracingItems({this.type});
  @override
  List<Object?> get props => [type];
}

abstract class TracingListState extends Equatable {
  const TracingListState();
  @override
  List<Object?> get props => [];
}

class TracingListInitial extends TracingListState {}

class TracingListLoading extends TracingListState {}

class TracingListLoaded extends TracingListState {
  final List<TracingItem> items;
  final String? activeType;
  const TracingListLoaded({required this.items, this.activeType});
  @override
  List<Object?> get props => [items, activeType];
}

class TracingListError extends TracingListState {
  final String message;
  const TracingListError(this.message);
  @override
  List<Object?> get props => [message];
}
