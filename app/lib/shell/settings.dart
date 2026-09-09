import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide persisted preferences and short, locally bundled flock calls.
class AppSettings {
  final SharedPreferencesAsync _prefs;

  final ValueNotifier<bool> soundOn = ValueNotifier(true);
  final ValueNotifier<bool> hapticsOn = ValueNotifier(true);
  final ValueNotifier<bool> reducedMotion = ValueNotifier(false);
  AudioPlayer? _player;

  AppSettings([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  Future<void> load() async {
    soundOn.value = await _prefs.getBool('settings.sound') ?? true;
    hapticsOn.value = await _prefs.getBool('settings.haptics') ?? true;
    reducedMotion.value =
        await _prefs.getBool('settings.reducedMotion') ?? false;
  }

  Future<void> setSound(bool on) async {
    soundOn.value = on;
    if (!on) await _player?.stop();
    await _prefs.setBool('settings.sound', on);
  }

  Future<void> setHaptics(bool on) async {
    hapticsOn.value = on;
    await _prefs.setBool('settings.haptics', on);
  }

  Future<void> setReducedMotion(bool on) async {
    reducedMotion.value = on;
    await _prefs.setBool('settings.reducedMotion', on);
  }

  Future<void> chirp({bool celebration = false}) async {
    if (!soundOn.value) return;
    try {
      _player ??= AudioPlayer();
      await _player!.play(
        AssetSource('aviary/${celebration ? 'celebrate' : 'chirp'}.wav'),
        volume: .45,
      );
    } catch (_) {
      // Audio interruptions must never interrupt a puzzle or progress save.
    }
  }

  void hapticTap() {
    if (hapticsOn.value) HapticFeedback.selectionClick();
  }

  void hapticError() {
    if (hapticsOn.value) HapticFeedback.mediumImpact();
  }
}
