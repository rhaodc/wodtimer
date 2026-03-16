import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final _player = AudioPlayer();

  void unlockAudio() {}

  Future<void> playBeep() async {
    await _player.play(AssetSource('beep.mp3'));
  }

  Future<void> playLongBeep() async {
    await _player.play(AssetSource('longbeep.mp3'));
  }

  void dispose() {
    _player.dispose();
  }
}
