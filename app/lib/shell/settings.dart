import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide settings, persisted in shared_preferences. Sound is stubbed —
/// the toggle persists but no audio ships yet.
class AppSettings {
  final SharedPreferencesAsync _prefs;

  final ValueNotifier<bool> soundOn = ValueNotifier(true);
  final ValueNotifier<bool> hapticsOn = ValueNotifier(true);

  AppSettings([SharedPreferencesAsync? prefs])
      : _prefs = prefs ?? SharedPreferencesAsync();

  Future<void> load() async {
    soundOn.value = await _prefs.getBool('settings.sound') ?? true;
    hapticsOn.value = await _prefs.getBool('settings.haptics') ?? true;
  }

  Future<void> setSound(bool on) async {
    soundOn.value = on;
    await _prefs.setBool('settings.sound', on);
  }

  Future<void> setHaptics(bool on) async {
    hapticsOn.value = on;
    await _prefs.setBool('settings.haptics', on);
  }

  void hapticTap() {
    if (hapticsOn.value) HapticFeedback.selectionClick();
  }

  void hapticError() {
    if (hapticsOn.value) HapticFeedback.mediumImpact();
  }
}
