/// Deterministic, platform-stable RNG.
///
/// Implemented with 32-bit arithmetic only (shift/xor plus an emulated
/// 32-bit multiply), so results are identical on VM, AOT and web — we never
/// rely on `dart:math`'s `Random` algorithm being stable across versions.
library;

const int _mask32 = 0xFFFFFFFF;

/// 32-bit multiply without overflowing the 53-bit safe-integer range
/// (same trick as JS `Math.imul`).
int _mul32(int a, int b) {
  final aLo = a & 0xFFFF;
  final aHi = a >>> 16;
  return ((aLo * b) + (((aHi * b) & 0xFFFF) << 16)) & _mask32;
}

/// SplitMix32-style hash; used to derive seeds (e.g. level index → seed,
/// (seed, attempt) → deal seed).
int hash32(int x) {
  var z = (x + 0x9E3779B9) & _mask32;
  z ^= z >>> 16;
  z = _mul32(z, 0x21F0AAAD);
  z ^= z >>> 15;
  z = _mul32(z, 0x735A2D97);
  z ^= z >>> 15;
  return z;
}

/// xorshift128 (Marsaglia). Fast, 32-bit-only state transitions.
class Rng {
  int _x, _y, _z, _w;

  Rng(int seed)
      : _x = hash32(seed),
        _y = hash32(seed ^ 0x6A09E667),
        _z = hash32(seed ^ 0xBB67AE85),
        _w = hash32(seed ^ 0x3C6EF372) {
    // Avoid the all-zero state (astronomically unlikely, but cheap to guard).
    if (_x == 0 && _y == 0 && _z == 0 && _w == 0) _x = 1;
  }

  int _next() {
    final t = (_x ^ (_x << 11)) & _mask32;
    _x = _y;
    _y = _z;
    _z = _w;
    _w = (_w ^ (_w >>> 19)) ^ (t ^ (t >>> 8));
    return _w;
  }

  /// Uniform integer in [0, bound). Rejection-sampled to avoid modulo bias.
  int nextInt(int bound) {
    assert(bound > 0 && bound <= _mask32);
    final limit = _mask32 - (_mask32 + 1) % bound;
    int v;
    do {
      v = _next();
    } while (v > limit);
    return v % bound;
  }

  /// In-place Fisher–Yates shuffle.
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = nextInt(i + 1);
      final t = list[i];
      list[i] = list[j];
      list[j] = t;
    }
  }
}
