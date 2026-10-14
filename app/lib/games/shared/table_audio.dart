import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../shell/settings.dart';

/// Two bounded voices let reward notes ring over quiet touch feedback.
class TableAudio with WidgetsBindingObserver {
  final AppSettings settings;
  final Map<String, AudioPlayer> _voices = {};
  final Set<String> _busy = {};
  final String theme;
  bool _disposed = false;
  int _generation = 0;
  TableAudio(this.settings, this.theme) {
    settings.soundOn.addListener(_soundChanged);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) stop();
  }

  void _soundChanged() {
    if (!settings.soundOn.value) stop();
  }

  void play(String sound, {bool reward = false}) {
    if (_disposed || !settings.soundOn.value) return;
    final lane = reward ? 'reward' : 'touch';
    if (!_busy.add(lane)) return;
    final generation = _generation;
    unawaited(() async {
      try {
        final player = _voices.putIfAbsent(lane, AudioPlayer.new);
        await player.play(AssetSource('$theme/$sound.wav'), volume: .55);
        if (_disposed || generation != _generation) await player.stop();
      } catch (_) {
        // Missing audio devices and interruptions must not interrupt a puzzle.
      } finally {
        _busy.remove(lane);
      }
    }());
  }

  void stop() {
    _generation++;

    for (final player in _voices.values) {
      unawaited(player.stop().catchError((Object _) {}));
    }
  }

  void dispose() {
    _disposed = true;
    settings.soundOn.removeListener(_soundChanged);
    WidgetsBinding.instance.removeObserver(this);
    stop();
    for (final player in _voices.values) {
      unawaited(player.dispose().catchError((Object _) {}));
    }
  }
}
