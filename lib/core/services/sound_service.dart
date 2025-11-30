import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

final soundServiceProvider = Provider<SoundService>((ref) {
  return SoundService();
});

class SoundService {
  final AudioPlayer _player = AudioPlayer();
  String? _currentUrl;

  // Pre-defined soundscapes (using public domain / free sounds for demo)
  static const Map<String, String> soundscapes = {
    "Brown Noise": "https://actions.google.com/sounds/v1/water/air_conditioner_hum.ogg", // Close approximation
    "Rainy Mood": "https://actions.google.com/sounds/v1/weather/rain_heavy_loud.ogg",
    "Lo-Fi Beats": "https://actions.google.com/sounds/v1/ambiences/piano_bar.ogg", // Jazz/Piano ambience
    "Forest Ambience": "https://actions.google.com/sounds/v1/nature/forest_morning.ogg",
  };

  Future<void> playSound(String title) async {
    final url = soundscapes[title];
    if (url == null) return;

    // If already playing this sound, toggle stop
    if (_player.playing && _currentUrl == url) {
      await stop();
      return;
    }

    try {
      _currentUrl = url;
      await _player.setUrl(url);
      await _player.setLoopMode(LoopMode.one); // Loop indefinitely
      await _player.play();
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  Future<void> stop() async {
    _currentUrl = null;
    await _player.stop();
  }

  bool isPlaying(String title) {
    return _player.playing && _currentUrl == soundscapes[title];
  }

  Stream<bool> get playingStream => _player.playingStream;
  Stream<ProcessingState> get processingStateStream => _player.processingStateStream;
  
  void dispose() {
    _player.dispose();
  }
}
