import 'package:arunika_app/data/models/response/growth_record.dart';
import 'package:arunika_app/data/repositories/growth_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ────────────────────────────────────────────────────────────────────
abstract class GrowthEvent extends Equatable {
  const GrowthEvent();
  @override
  List<Object?> get props => [];
}

class LoadGrowthHistory extends GrowthEvent {
  final String childId;
  const LoadGrowthHistory(this.childId);
  @override
  List<Object?> get props => [childId];
}

class SaveGrowthRecord extends GrowthEvent {
  final String childId;
  final double weightKg;
  final double heightCm;
  final DateTime? recordedAt;
  const SaveGrowthRecord({
    required this.childId,
    required this.weightKg,
    required this.heightCm,
    this.recordedAt,
  });
  @override
  List<Object?> get props => [childId, weightKg, heightCm];
}

class UpdateGrowthRecord extends GrowthEvent {
  final String id;
  final String childId;
  final double weightKg;
  final double heightCm;
  final DateTime? recordedAt;
  const UpdateGrowthRecord({
    required this.id,
    required this.childId,
    required this.weightKg,
    required this.heightCm,
    this.recordedAt,
  });
  @override
  List<Object?> get props => [id, childId, weightKg, heightCm];
}

// ── States ────────────────────────────────────────────────────────────────────
abstract class GrowthState extends Equatable {
  const GrowthState();
  @override
  List<Object?> get props => [];
}

class GrowthInitial extends GrowthState {}

class GrowthLoading extends GrowthState {}

class GrowthLoaded extends GrowthState {
  final List<GrowthRecord> records;
  const GrowthLoaded(this.records);
  @override
  List<Object?> get props => [records];
}

class GrowthSaved extends GrowthState {
  final List<GrowthRecord> records;
  const GrowthSaved(this.records);
  @override
  List<Object?> get props => [records];
}

class GrowthUpdated extends GrowthState {
  final List<GrowthRecord> records;
  const GrowthUpdated(this.records);
  @override
  List<Object?> get props => [records];
}

class GrowthError extends GrowthState {
  final String message;
  const GrowthError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ──────────────────────────────────────────────────────────────────────
class GrowthBloc extends Bloc<GrowthEvent, GrowthState> {
  final GrowthRepository repository;

  GrowthBloc({required this.repository}) : super(GrowthInitial()) {
    on<LoadGrowthHistory>(_onLoad);
    on<SaveGrowthRecord>(_onSave);
    on<UpdateGrowthRecord>(_onUpdate);
  }

  Future<void> _onLoad(
    LoadGrowthHistory event,
    Emitter<GrowthState> emit,
  ) async {
    emit(GrowthLoading());
    try {
      final records = await repository.getHistory(event.childId);
      emit(GrowthLoaded(records));
    } catch (e) {
      emit(GrowthError(e.toString()));
    }
  }

  Future<void> _onSave(
    SaveGrowthRecord event,
    Emitter<GrowthState> emit,
  ) async {
    emit(GrowthLoading());
    try {
      await repository.saveRecord(
        childId: event.childId,
        weightKg: event.weightKg,
        heightCm: event.heightCm,
        recordedAt: event.recordedAt,
      );
      final records = await repository.getHistory(event.childId);
      emit(GrowthSaved(records));
    } catch (e) {
      emit(GrowthError(e.toString()));
    }
  }

  Future<void> _onUpdate(
    UpdateGrowthRecord event,
    Emitter<GrowthState> emit,
  ) async {
    emit(GrowthLoading());
    try {
      await repository.updateRecord(
        id: event.id,
        weightKg: event.weightKg,
        heightCm: event.heightCm,
        recordedAt: event.recordedAt,
      );
      final records = await repository.getHistory(event.childId);
      emit(GrowthUpdated(records));
    } catch (e) {
      emit(GrowthError(e.toString()));
    }
  }
}
