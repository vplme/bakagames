import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../../shell/settings.dart';
import 'model.dart';

class MergefrontAudio {
  final AppSettings settings;
  final Profile profile;
  AudioPlayer? _music, _effect;
  bool active = false, disposed = false, boss = false;
  bool focused = true;
  int _generation = 0;
  DateTime _last = DateTime(2000);
  DateTime _quietUntil = DateTime(2000);
  MergefrontAudio(this.settings, this.profile) {
    settings.soundOn.addListener(sync);
  }
  Future<void> sync() async {
    final generation = ++_generation;
    try {
      if (disposed || !focused || !active || !settings.soundOn.value) {
        await _music?.stop();
        await _effect?.stop();
        return;
      }
      if (!profile.music) {
        await _music?.stop();
        return;
      }
      _music ??= AudioPlayer();
      await _music!.setReleaseMode(ReleaseMode.loop);
      if (generation != _generation || disposed) return;
      await _music!.play(
        AssetSource('mergefront/${boss ? 'boss' : 'coast'}_loop.wav'),
        volume: .18,
      );
      if (generation != _generation || disposed || !active) {
        await _music?.stop();
      }
    } catch (_) {
      /* A missing audio device never blocks play. */
    }
  }

  void setActive(bool value) {
    active = value;
    unawaited(sync());
  }

  Future<void> finish(String kind) async {
    active = false;
    await sync();
    await event(kind);
  }

  Future<void> event(String kind) async {
    if (disposed || !focused) return;
    if (kind == 'boss') {
      boss = true;
      unawaited(sync());
    }
    if (settings.hapticsOn.value) {
      if (kind == 'merge') {
        unawaited(HapticFeedback.mediumImpact());
      } else if (kind == 'gate' || kind == 'risk' || kind == 'recruit') {
        unawaited(HapticFeedback.lightImpact());
      } else if (kind == 'hurt') {
        unawaited(HapticFeedback.lightImpact());
      } else if (kind == 'victory') {
        unawaited(_successPattern());
      }
    }
    if (!settings.soundOn.value || !profile.effects) return;
    final now = DateTime.now();
    final repetitive = [
      'shot',
      'heavy',
      'scatter',
      'coin',
      'enemy',
      'shield',
    ].contains(kind);
    if (repetitive && now.isBefore(_quietUntil)) return;
    if (repetitive && now.difference(_last).inMilliseconds < 140) return;
    _last = now;
    if (!repetitive) _quietUntil = now.add(const Duration(milliseconds: 650));
    try {
      _effect ??= AudioPlayer();
      final sound = switch (kind) {
        'merge' => 'merge',
        'victory' => 'victory',
        'defeat' => 'defeat',
        'boss' || 'hurt' || 'risk' || 'miss' => 'pulse',
        'shot' => 'snap',
        'heavy' ||
        'scatter' ||
        'coin' ||
        'shield' ||
        'preview' ||
        'recruit' ||
        'ui' ||
        'enemy' => kind,
        _ => 'gate',
      };
      await _effect!.setPlaybackRate(.97 + now.millisecond % 7 * .01);
      if (disposed || !focused || !settings.soundOn.value || !profile.effects) {
        return;
      }
      await _effect!.play(
        AssetSource('mergefront/$sound.wav'),
        volume: (repetitive ? .10 : .36) + now.millisecond % 4 * .01,
      );
      if (!repetitive && kind != 'preview' && kind != 'ui') {
        await _music?.setVolume(.08);
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!disposed && active) await _music?.setVolume(.18);
      }
    } catch (_) {
      /* Playback is optional. */
    }
  }

  Future<void> _successPattern() async {
    await HapticFeedback.mediumImpact();
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!disposed && focused && settings.hapticsOn.value) {
      await HapticFeedback.lightImpact();
    }
  }

  void dispose() {
    disposed = true;
    _generation++;
    settings.soundOn.removeListener(sync);
    unawaited(_music?.dispose());
    unawaited(_effect?.dispose());
  }
}
