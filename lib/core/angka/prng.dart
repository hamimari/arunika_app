/// mulberry32, bit-identical to the backend's `angkagen.Rand`.
///
/// Every step stays within 32 bits (multiplications are split into 16-bit
/// halves like JavaScript's `Math.imul`), so the sequence is the same on
/// every platform Dart runs on.
class Mulberry32 {
  int _state;

  Mulberry32(int seed) : _state = seed & _mask;

  static const _mask = 0xFFFFFFFF;

  /// The next value in [0, 2^32).
  int next() {
    _state = (_state + 0x6D2B79F5) & _mask;
    var t = _state;
    t = imul32(t ^ (t >> 15), t | 1);
    t = ((t + imul32(t ^ (t >> 7), t | 61)) & _mask) ^ t;
    return (t ^ (t >> 14)) & _mask;
  }

  /// A value in [0, n).
  int intn(int n) => next() % n;

  /// Fisher–Yates, consuming the PRNG from the end of [list] backwards.
  void shuffle<T>(List<T> list) {
    for (var i = list.length - 1; i > 0; i--) {
      final j = intn(i + 1);
      final tmp = list[i];
      list[i] = list[j];
      list[j] = tmp;
    }
  }
}

/// The low 32 bits of a × b for 32-bit unsigned a and b.
int imul32(int a, int b) {
  final ah = (a >> 16) & 0xFFFF, al = a & 0xFFFF;
  final bh = (b >> 16) & 0xFFFF, bl = b & 0xFFFF;
  return (al * bl + ((((ah * bl + al * bh) & 0xFFFF) << 16))) & 0xFFFFFFFF;
}
