import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _isMuted = false;
  
  bool get isMuted => _isMuted;
  
  Future<void> init() async {
    await _player.setReleaseMode(ReleaseMode.stop);
  }
  
  void toggleMute() {
    _isMuted = !_isMuted;
  }
  
  /// Play water drop sound
  Future<void> playWaterDrop() async {
    if (_isMuted) return;
    await _player.play(AssetSource('audio/water_drop.mp3'));
  }
  
  /// Play water pour sound
  Future<void> playWaterPour() async {
    if (_isMuted) return;
    await _player.play(AssetSource('audio/water_pour.mp3'));
  }
  
  /// Play revival success chord
  Future<void> playRevivalSuccess() async {
    if (_isMuted) return;
    await _player.play(AssetSource('audio/revival_success.mp3'));
  }
  
  /// Play ambient garden sounds
  Future<void> playAmbient() async {
    if (_isMuted) return;
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource('audio/garden_ambient.mp3'));
  }
  
  /// Stop all sounds
  Future<void> stop() async {
    await _player.stop();
  }
  
  void dispose() {
    _player.dispose();
  }
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});
