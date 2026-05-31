import 'package:arunika_app/data/models/response/counting_question.dart';
import 'package:arunika_app/data/repositories/counting_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class CountingListEvent extends Equatable {
  const CountingListEvent();
  @override
  List<Object?> get props => [];
}

class LoadCountingQuestions extends CountingListEvent {
  final String? level;
  const LoadCountingQuestions({this.level});
  @override
  List<Object?> get props => [level];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class CountingListState extends Equatable {
  const CountingListState();
  @override
  List<Object?> get props => [];
}

class CountingListInitial extends CountingListState {}

class CountingListLoading extends CountingListState {}

class CountingListLoaded extends CountingListState {
  final List<CountingQuestion> questions;
  final String? activeLevel;
  const CountingListLoaded({required this.questions, this.activeLevel});
  @override
  List<Object?> get props => [questions, activeLevel];
}

class CountingListError extends CountingListState {
  final String message;
  const CountingListError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class CountingListCubit extends Cubit<CountingListState> {
  final CountingRepository repository;
  CountingListCubit({required this.repository}) : super(CountingListInitial());

  Future<void> load({String? level}) async {
    emit(CountingListLoading());
    try {
      final questions = await repository.getQuestions(level: level);
      emit(CountingListLoaded(questions: questions, activeLevel: level));
    } catch (e) {
      emit(CountingListError(e.toString()));
    }
  }
}
