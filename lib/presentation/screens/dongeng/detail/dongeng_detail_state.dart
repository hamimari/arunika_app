import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:equatable/equatable.dart';

class DongengDetailState extends Equatable {
  final bool isPlaying;
  final Duration position;
  final Duration duration;
  final DongengResponse dongeng;

  const DongengDetailState({
    required this.isPlaying,
    required this.position,
    required this.duration,
    required this.dongeng,
  });

  factory DongengDetailState.initial(DongengResponse selectedDongeng) => DongengDetailState(
    isPlaying: false,
    position: Duration.zero,
    duration: Duration.zero,
    dongeng: selectedDongeng,
  );

  DongengDetailState copyWith({
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    DongengResponse? dongeng,
  }) {
    return DongengDetailState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      dongeng: dongeng ?? this.dongeng,
    );
  }

  @override
  List<Object?> get props => [isPlaying, position, duration, dongeng];
}
