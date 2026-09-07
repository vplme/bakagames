import 'package:bird_sort/bird_sort.dart';
import 'package:test/test.dart';

void main() {
  test('hash32 golden values (platform stability canary)', () {
    // If these change, every player's levels change. Never edit casually.
    expect(hash32(0), 0x64625032);
    expect(hash32(1), 0x5E2D1772);
    expect(hash32(42), 0x20E44818);
  });

  test('same seed → same sequence; different seed → different', () {
    final a = Rng(123), b = Rng(123), c = Rng(124);
    final sa = List.generate(50, (_) => a.nextInt(1000));
    final sb = List.generate(50, (_) => b.nextInt(1000));
    final sc = List.generate(50, (_) => c.nextInt(1000));
    expect(sa, sb);
    expect(sa, isNot(equals(sc)));
  });

  test('nextInt stays in range and hits all values eventually', () {
    final rng = Rng(7);
    final seen = <int>{};
    for (var i = 0; i < 1000; i++) {
      final v = rng.nextInt(6);
      expect(v, inInclusiveRange(0, 5));
      seen.add(v);
    }
    expect(seen, hasLength(6));
  });

  test('shuffle is a permutation and deterministic', () {
    final l1 = List.generate(20, (i) => i);
    final l2 = List.generate(20, (i) => i);
    Rng(99).shuffle(l1);
    Rng(99).shuffle(l2);
    expect(l1, l2);
    expect(l1.toSet(), hasLength(20));
    expect(l1, isNot(equals(List.generate(20, (i) => i))));
  });
}
