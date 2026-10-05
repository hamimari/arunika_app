import 'package:arunika_app/core/angka/prng.dart';
import 'package:equatable/equatable.dart';

/// Belajar Angka "Hitung Benda" question generator — a line-for-line port of
/// the backend's `angkagen` package. Questions are never downloaded: a
/// session's seed, its level settings and its object snapshot regenerate
/// them, here and on the server that scores them.
/// test/fixtures/angka_generator_golden.json pins the two together.
class AngkaGenerator {
  /// The logical box pictures are placed in; the UI scales it to fit.
  static const areaWidth = 320;
  static const areaHeight = 180;

  /// Minimum free space between two pictures.
  static const gap = 12;

  /// Candidates per picture before a scatter question falls back to rows.
  static const scatterTries = 30;

  /// The most pictures in one row.
  static const rowMax = 5;

  static const layoutScatter = 'scatter';
  static const layoutRows = 'rows';

  /// Picture side for a question with [n] pictures.
  static int pictureSize(int n) {
    if (n <= 5) return 52;
    if (n <= 10) return 38;
    if (n <= 15) return 30;
    return 26;
  }

  /// [count] questions for counts [min]..[max]. The PRNG is used in a fixed
  /// order: the remainder shuffle, the bag shuffle, then per question its
  /// object and its positions.
  static List<AngkaQuestion> generate({
    required int min,
    required int max,
    required int count,
    required List<String> objectIds,
    required String layout,
    required int seed,
  }) {
    final r = Mulberry32(seed);
    final counts = _countBag(r, min, max, count);
    final out = <AngkaQuestion>[];
    var prev = -1;
    for (final n in counts) {
      var object = '';
      if (objectIds.isNotEmpty) {
        var idx = r.intn(objectIds.length);
        if (idx == prev && objectIds.length > 1) {
          idx = (idx + 1) % objectIds.length;
        }
        prev = idx;
        object = objectIds[idx];
      }
      final size = pictureSize(n);
      var actual = layoutRows;
      List<AngkaPoint>? points;
      if (layout == layoutScatter) {
        points = _scatter(r, n, size);
        if (points != null) actual = layoutScatter;
      }
      points ??= _rows(n, size);
      out.add(
        AngkaQuestion(
          count: n,
          objectId: object,
          size: size,
          layout: actual,
          points: points,
        ),
      );
    }
    return out;
  }

  static List<int> _countBag(Mulberry32 r, int min, int max, int n) {
    if (n <= 0 || max < min) return const [];
    final span = max - min + 1;
    final full = [for (var i = 0; i < span; i++) min + i];
    final bag = <int>[];
    for (var c = 0; c < n ~/ span; c++) {
      bag.addAll(full);
    }
    final rem = n % span;
    if (rem > 0) {
      final extra = [...full];
      r.shuffle(extra);
      bag.addAll(extra.take(rem));
    }
    r.shuffle(bag);
    return _spreadRepeats(bag);
  }

  /// Re-reads [bag] in order, each step taking the first remaining value that
  /// differs from the previous one — unless one value fills more than half
  /// of what remains, which must then go next.
  static List<int> _spreadRepeats(List<int> bag) {
    final rest = [...bag];
    final out = <int>[];
    while (rest.isNotEmpty) {
      final counts = <int, int>{};
      for (final v in rest) {
        counts[v] = (counts[v] ?? 0) + 1;
      }
      var pick = -1;
      for (var i = 0; i < rest.length; i++) {
        if (counts[rest[i]]! * 2 > rest.length) {
          pick = i;
          break;
        }
      }
      if (pick < 0) {
        pick = 0;
        for (var i = 0; i < rest.length; i++) {
          if (out.isEmpty || rest[i] != out.last) {
            pick = i;
            break;
          }
        }
      }
      out.add(rest.removeAt(pick));
    }
    return out;
  }

  static List<AngkaPoint>? _scatter(Mulberry32 r, int n, int size) {
    final minDist = (size + gap) * (size + gap);
    final half = size ~/ 2;
    final pts = <AngkaPoint>[];
    for (var k = 0; k < n; k++) {
      var placed = false;
      for (var t = 0; t < scatterTries; t++) {
        final c = AngkaPoint(
          half + r.intn(areaWidth - size + 1),
          half + r.intn(areaHeight - size + 1),
        );
        var free = true;
        for (final q in pts) {
          final dx = c.x - q.x, dy = c.y - q.y;
          if (dx * dx + dy * dy < minDist) {
            free = false;
            break;
          }
        }
        if (free) {
          pts.add(c);
          placed = true;
          break;
        }
      }
      if (!placed) return null;
    }
    return pts;
  }

  static List<AngkaPoint> _rows(int n, int size) {
    if (n <= 0) return const [];
    final lines = (n + rowMax - 1) ~/ rowMax;
    final base = n ~/ lines, extra = n % lines;
    final height = lines * size + (lines - 1) * gap;
    var y = (areaHeight - height) ~/ 2 + size ~/ 2;
    final pts = <AngkaPoint>[];
    for (var l = 0; l < lines; l++) {
      final k = base + (l < extra ? 1 : 0);
      final width = k * size + (k - 1) * gap;
      final x = (areaWidth - width) ~/ 2 + size ~/ 2;
      for (var i = 0; i < k; i++) {
        pts.add(AngkaPoint(x + i * (size + gap), y));
      }
      y += size + gap;
    }
    return pts;
  }
}

/// A picture centre in the 320 × 180 box.
class AngkaPoint extends Equatable {
  final int x;
  final int y;

  const AngkaPoint(this.x, this.y);

  @override
  List<Object?> get props => [x, y];
}

/// One generated question: [count] pictures of [objectId].
class AngkaQuestion extends Equatable {
  final int count;
  final String objectId;
  final int size;
  final String layout;
  final List<AngkaPoint> points;

  const AngkaQuestion({
    required this.count,
    required this.objectId,
    required this.size,
    required this.layout,
    required this.points,
  });

  @override
  List<Object?> get props => [count, objectId, size, layout, points];
}
