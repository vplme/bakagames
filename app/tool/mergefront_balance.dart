import 'dart:io';
import 'package:baka_games/games/mergefront/model.dart';

// Deterministic sanity report; this is not a substitute for human playtesting.
void main() {
  for (var level = 0; level < 5; level++) {
    for (final lane in [.25, .5, .75]) {
      final r = Run(Level.all[level], Profile().loadout)..steer(lane);
      for (var frame = 0; frame < 180 * 60 && !r.finished; frame++) {
        r.step(1 / 60);
      }
      stdout.writeln(
        'Mission ${level + 1}, fixed lane $lane: ${r.won ? "WIN" : "LOSS"}, '
        '${r.time.round()}s, ${r.squad.length} units, ${r.kills} targets, '
        'boss health ${r.boss?.hp.round() ?? 0}',
      );
    }
  }
}
