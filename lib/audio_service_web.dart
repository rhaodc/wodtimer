import 'dart:js_interop';

@JS('window._wodUnlockAudio')
external void _wodUnlockAudio();

@JS('window._wodPlayBeep')
external void _wodPlayBeep();

class AudioService {
  void unlockAudio() => _wodUnlockAudio();

  Future<void> playBeep() async => _wodPlayBeep();

  void dispose() {}
}
