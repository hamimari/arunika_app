import 'dart:async';
import 'package:arunika_app/data/models/response/dongeng_response.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_event.dart';
import 'package:arunika_app/presentation/screens/dongeng/detail/dongeng_detail_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

class DongengDetailBloc extends Bloc<DongengDetailEvent, DongengDetailState> {
  final AudioPlayer _player = AudioPlayer();
  final DongengResponse dongeng;


  StreamSubscription? _posSub;
  StreamSubscription? _durSub;

  DongengDetailBloc(this.dongeng) : super(DongengDetailState.initial(dongeng)) {
    on<LoadAudio>(_onLoad);
    on<PlayPause>(_onPlayPause);
    on<SeekTo>(_onSeek);
    on<Forward10>(_onForward);
    on<Backward10>(_onBackward);

    on<PositionUpdated>((e, emit) {
      emit(state.copyWith(position: e.position));
    });

    on<DurationUpdated>((e, emit) {
      emit(state.copyWith(duration: e.duration));
    });
  }

  Future<void> _onLoad(
    LoadAudio event,
    Emitter<DongengDetailState> emit,
  ) async {
    await _player.setUrl(event.url);

    _durSub = _player.durationStream.listen((d) {
      if (d != null) add(DurationUpdated(d));
    });

    _posSub = _player.positionStream.listen(
          (p) => add(PositionUpdated(p)),
    );
  }

  void _onPlayPause(PlayPause event, Emitter<DongengDetailState> emit) {
    if (_player.playing) {
      _player.pause();
      emit(state.copyWith(isPlaying: false));
    } else {
      _player.play();
      emit(state.copyWith(isPlaying: true));
    }
  }

  void _onSeek(SeekTo event, Emitter<DongengDetailState> emit) {
    _player.seek(event.position);
  }

  void _onForward(Forward10 event, Emitter<DongengDetailState> emit) {
    _player.seek(state.position + const Duration(seconds: 10));
  }

  void _onBackward(Backward10 event, Emitter<DongengDetailState> emit) {
    _player.seek(state.position - const Duration(seconds: 10));
  }

  @override
  Future<void> close() {
    _posSub?.cancel();
    _durSub?.cancel();
    _player.dispose();
    return super.close();
  }
}
