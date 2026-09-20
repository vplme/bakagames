// Original procedural score and toy effects, authored for Baka Games.
// Run from app/: dart run tool/mergefront_audio.dart
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const sampleRate = 22050;
void writeWave(String name, double seconds, double Function(double) synth) {
  final length = (seconds * sampleRate).round();
  final data = ByteData(44 + length * 2);
  void tag(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      data.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  tag(0, 'RIFF');
  data.setUint32(4, 36 + length * 2, Endian.little);
  tag(8, 'WAVE');
  tag(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, sampleRate, Endian.little);
  data.setUint32(28, sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  tag(36, 'data');
  data.setUint32(40, length * 2, Endian.little);
  for (var i = 0; i < length; i++) {
    data.setInt16(
      44 + i * 2,
      (synth(i / sampleRate).clamp(-1, 1) * 28000).round(),
      Endian.little,
    );
  }
  File(
    'assets/mergefront/$name.wav',
  ).writeAsBytesSync(data.buffer.asUint8List());
}

double note(double time, double frequency, double decay) =>
    sin(2 * pi * frequency * time) * exp(-time * decay) * min(1, time * 300);
void main() {
  Directory('assets/mergefront').createSync(recursive: true);
  const beat = 60 / 128;
  // Eight bars; every voice releases within its step, giving a clean seam.
  const melody = [0, 7, 12, 7, 4, 9, 7, 4, 2, 7, 11, 14, 7, 4, 2, 7];
  for (final boss in [false, true]) {
    writeWave(boss ? 'boss_loop' : 'coast_loop', beat * 32, (t) {
      final step = (t / (beat / 2)).floor();
      final local = t % (beat / 2);
      final freq = 261.6256 * pow(2, melody[step % melody.length] / 12);
      final fade = min(1.0, (beat / 2 - local) * 90);
      final pluck =
          (note(local, freq, 18) + .24 * note(local, freq * 3, 28)) *
          .18 *
          fade;
      final bassT = t % beat;
      final root = [130.81, 110.0, 87.31, 98.0][(t / (beat * 8)).floor() % 4];
      final bass = note(bassT, root, 10) * .20 * min(1, (beat - bassT) * 90);
      final drum = note(bassT, 74 - bassT * 50, 30) * .24;
      final tick = note(local, 1831, 130) * .045;
      final accents = boss
          ? note(local, 196, 24) * .12 + note(local, 392, 28) * .06
          : 0;
      return pluck + bass + drum + tick + accents;
    });
  }
  writeWave('gate', .45, (t) => note(t, t < .12 ? 660 : 990, 10) * .55);
  writeWave(
    'merge',
    .85,
    (t) => t < .2
        ? note(t % .1, 230, 40) * .45
        : (note(t - .2, 392, 6) + note(t - .2, 494, 7) + note(t - .2, 587, 8)) *
              .22,
  );
  writeWave('snap', .10, (t) => (note(t, 760, 80) + note(t, 1190, 100)) * .24);
  writeWave(
    'heavy',
    .24,
    (t) => note(t, 95, 20) * .50 + note(t, 950, 90) * .15,
  );
  writeWave(
    'scatter',
    .18,
    (t) => (note(t, 510, 35) + note(t, 847, 38) + note(t, 1387, 42)) * .16,
  );
  writeWave('shield', .4, (t) => (note(t, 1047, 13) + note(t, 1568, 17)) * .22);
  writeWave('coin', .18, (t) => (note(t, 1319, 28) + note(t, 1976, 35)) * .24);
  writeWave('preview', .30, (t) => note(t % .15, t < .15 ? 440 : 587, 22) * .2);
  writeWave(
    'recruit',
    .3,
    (t) => note(t % .1, 440 + (t / .1).floor() * 110, 30) * .32,
  );
  writeWave('ui', .07, (t) => (note(t, 340, 90) + note(t, 791, 110)) * .25);
  writeWave('enemy', .15, (t) => note(t, 160 + t * 200, 35) * .36);
  writeWave('pulse', .6, (t) => note(t % .3, 147, 16) * .5);
  writeWave('victory', 1.5, (t) {
    final i = min(3, (t / .25).floor());
    return note(t - i * .25, [392.0, 494.0, 587.0, 784.0][i], 5) * .5;
  });
  writeWave(
    'defeat',
    .8,
    (t) =>
        note(
          t % .25,
          [392.0, 330.0, 261.0, 196.0][min(3, (t / .25).floor())],
          12,
        ) *
        .4,
  );
}
