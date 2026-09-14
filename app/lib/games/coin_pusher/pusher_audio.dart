import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import '../../shell/settings.dart';

/// Batches nearby physics events into a single, fuller cascade sound.
class PusherSoundMixer {
  final void Function(String asset) play;
  final List<String> _pending = [];
  double _elapsed = 0, _sinceCollection = 2;
  int _chain = 0;
  PusherSoundMixer(this.play);

  void clear() {
    _pending.clear();
    _elapsed = 0;
    _sinceCollection = 2;
    _chain = 0;
  }

  void update(double dt, List<String> events) {
    _pending.addAll(events);
    _elapsed += dt;
    _sinceCollection += dt;
    if (_elapsed < .09) return;
    _elapsed = 0;
    final coins = _pending
        .where((e) => e == 'collect' || e == 'valuable')
        .length;
    if (coins > 0) {
      _chain = (_sinceCollection < .65 ? _chain : 0) + coins;
      _sinceCollection = 0;
      play(
        _chain >= 5
            ? 'cascade_big'
            : _chain >= 2
            ? 'cascade'
            : _pending.contains('valuable')
            ? 'valuable'
            : 'collect',
      );
    }
    for (final event in _pending.toSet()) {
      if (event != 'collect' && event != 'valuable') play(event);
    }
    _pending.clear();
  }
}

/// Separate bounded voices let tray, chute, and toy sounds ring together.
class PusherAudio {
  final AppSettings settings;
  final Map<String, AudioPlayer> _voices = {};
  final Set<String> _busy = {};
  late final mixer = PusherSoundMixer(_play);
  bool _disposed = false;
  int _generation = 0;
  PusherAudio(this.settings) {
    settings.soundOn.addListener(_soundChanged);
  }

  void _soundChanged() {
    if (!settings.soundOn.value) stop();
  }

  void update(double dt, List<String> events) {
    if (!settings.soundOn.value || _disposed) {
      mixer.clear();
      return;
    }
    mixer.update(dt, events);
  }

  void _play(String sound) {
    if (_disposed || !settings.soundOn.value) return;
    final lane = switch (sound) {
      'insert' => 'chute',
      'side' || 'toy_side' => 'side',
      'toy_collect' || 'toy_spawn' => 'toy',
      'bonus' || 'unlock' || 'reward_spawn' => 'reward',
      _ => 'tray',
    };
    if (!_busy.add(lane)) return;
    final generation = _generation;
    unawaited(() async {
      try {
        final player = _voices.putIfAbsent(lane, AudioPlayer.new);
        await player.play(
          AssetSource('pusher/$sound.wav'),
          volume: lane == 'side' ? .25 : .5,
        );
        if (_disposed || generation != _generation) await player.stop();
      } catch (_) {
        // Missing audio devices and interruptions must not affect the machine.
      } finally {
        _busy.remove(lane);
      }
    }());
  }

  void stop() {
    _generation++;
    mixer.clear();
    for (final player in _voices.values) {
      unawaited(player.stop().catchError((Object _) {}));
    }
  }

  void dispose() {
    _disposed = true;
    settings.soundOn.removeListener(_soundChanged);
    stop();
    for (final player in _voices.values) {
      unawaited(player.dispose().catchError((Object _) {}));
    }
  }
}
