import 'package:arunika_app/data/models/response/tracing_item.dart';
import 'package:arunika_app/data/repositories/tracing_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class TracingExerciseEvent extends Equatable {
  const TracingExerciseEvent();
  @override
  List<Object?> get props => [];
}

class LoadTracingExercise extends TracingExerciseEvent {
  final TracingItem item;
  final String childId;
  const LoadTracingExercise({required this.item, required this.childId});
  @override
  List<Object?> get props => [item.id, childId];
}

class SubmitTracingResult extends TracingExerciseEvent {
  final int score;
  final bool passed;
  const SubmitTracingResult({required this.score, required this.passed});
  @override
  List<Object?> get props => [score, passed];
}

class RetryTracing extends TracingExerciseEvent {}

// ── States ────────────────────────────────────────────────────────────────────
abstract class TracingExerciseState extends Equatable {
  const TracingExerciseState();
  @override
  List<Object?> get props => [];
}

class TracingExerciseInitial extends TracingExerciseState {}

class TracingExerciseLoading extends TracingExerciseState {}

class TracingExerciseReady extends TracingExerciseState {
  final TracingItem item;
  final String childId;
  const TracingExerciseReady({required this.item, required this.childId});
  @override
  List<Object?> get props => [item.id, childId];
}

class TracingExercisePassed extends TracingExerciseState {
  final int score;
  const TracingExercisePassed({required this.score});
  @override
  List<Object?> get props => [score];
}

class TracingExerciseFailed extends TracingExerciseState {
  final int score;
  const TracingExerciseFailed({required this.score});
  @override
  List<Object?> get props => [score];
}

class TracingExerciseError extends TracingExerciseState {
  final String message;
  const TracingExerciseError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class TracingExerciseBloc
    extends Bloc<TracingExerciseEvent, TracingExerciseState> {
  final TracingRepository repository;

  TracingExerciseBloc({required this.repository})
    : super(TracingExerciseInitial()) {
    on<LoadTracingExercise>(_onLoad);
    on<SubmitTracingResult>(_onSubmit);
    on<RetryTracing>(_onRetry);
  }

  void _onLoad(LoadTracingExercise event, Emitter<TracingExerciseState> emit) {
    emit(TracingExerciseReady(item: event.item, childId: event.childId));
  }

  Future<void> _onSubmit(
    SubmitTracingResult event,
    Emitter<TracingExerciseState> emit,
  ) async {
    final current = state;
    if (current is! TracingExerciseReady) return;

    emit(TracingExerciseLoading());
    try {
      await repository.saveProgress(
        childId: current.childId,
        itemId: current.item.id,
        score: event.score,
        passed: event.passed,
      );
      if (event.passed) {
        emit(TracingExercisePassed(score: event.score));
      } else {
        emit(TracingExerciseFailed(score: event.score));
      }
    } catch (e) {
      emit(TracingExerciseError(e.toString()));
    }
  }

  void _onRetry(RetryTracing event, Emitter<TracingExerciseState> emit) {
    final current = state;
    if (current is TracingExerciseFailed) {
      // Reload back to ready — item/childId not stored here; caller must re-push.
    }
    emit(TracingExerciseInitial());
  }
}
