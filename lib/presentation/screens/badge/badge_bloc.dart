import 'package:arunika_app/data/models/response/badge_item.dart';
import 'package:arunika_app/data/repositories/badge_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class BadgeState extends Equatable {
  const BadgeState();
  @override
  List<Object?> get props => [];
}

class BadgeInitial extends BadgeState {}

class BadgeLoading extends BadgeState {}

class BadgeLoaded extends BadgeState {
  final List<BadgeItem> badges;
  const BadgeLoaded(this.badges);
  @override
  List<Object?> get props => [badges];
}

class BadgeError extends BadgeState {
  final String message;
  const BadgeError(this.message);
  @override
  List<Object?> get props => [message];
}

class BadgeCubit extends Cubit<BadgeState> {
  final BadgeRepository repository;
  BadgeCubit({required this.repository}) : super(BadgeInitial());

  Future<void> load() async {
    emit(BadgeLoading());
    try {
      final badges = await repository.getBadges();
      emit(BadgeLoaded(badges));
    } catch (e) {
      emit(BadgeError(e.toString()));
    }
  }
}
