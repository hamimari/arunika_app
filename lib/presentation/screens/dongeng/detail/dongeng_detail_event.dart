
import 'package:equatable/equatable.dart';

abstract class DongengDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadAudio extends DongengDetailEvent {
  final String url;
  LoadAudio(this.url);

  @override
  List<Object?> get props => [url];
}

class PlayPause extends DongengDetailEvent {}

class SeekTo extends DongengDetailEvent {
  final Duration position;
  SeekTo(this.position);

  @override
  List<Object?> get props => [position];
}

class PositionUpdated extends DongengDetailEvent {
  final Duration position;
  PositionUpdated(this.position);

  @override
  List<Object?> get props => [position];
}

class DurationUpdated extends DongengDetailEvent {
  final Duration duration;
  DurationUpdated(this.duration);

  @override
  List<Object?> get props => [duration];
}

class Forward10 extends DongengDetailEvent {}
class Backward10 extends DongengDetailEvent {}
