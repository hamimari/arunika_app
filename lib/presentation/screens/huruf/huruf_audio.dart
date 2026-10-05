import 'dart:async';

import 'package:arunika_app/core/logger/app_logger.dart';
import 'package:arunika_app/core/media/media_cache.dart';
import 'package:just_audio/just_audio.dart';

/// Plays a letter's sounds. An interface so widget tests can run without a
/// platform audio player.
abstract class HurufAudio {
  /// Starts [url]; returns false when it could not be loaded.
  Future<bool> play(String url);

  void dispose();
}

/// just_audio with the default audio session, which follows the phone's
/// silent mode rather than overriding it.
class JustAudioHurufAudio implements HurufAudio {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<bool> play(String url) async {
    if (url.isEmpty) return false;
    try {
      await _player.stop();
      await MediaCache.setAudioUrl(_player, url);
      // play() completes when playback ends; don't wait for it.
      unawaited(_player.play());
      return true;
    } catch (e) {
      AppLogger.warning('Huruf audio failed', name: 'Huruf', error: e);
      return false;
    }
  }

  @override
  void dispose() => _player.dispose();
}
