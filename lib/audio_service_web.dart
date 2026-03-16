import 'dart:js_interop';

@JS('window._wodUnlockAudio')
external void _wodUnlockAudio();

@JS('window._wodPlayBeep')
external void _wodPlayBeep();

@JS('window._wodPlayLongBeep')
external void _wodPlayLongBeep();

class AudioService {
  void unlockAudio() => _wodUnlockAudio();

  Future<void> playBeep() async => _wodPlayBeep();

  Future<void> playLongBeep() async => _wodPlayLongBeep();

  void dispose() {}
}
