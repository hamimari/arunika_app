import 'dart:ui' show Offset;

/// Tracing thresholds, tunable from the server (`tracing_thresholds` in the
/// Huruf manifest). Defaults are the RFC's.
class TracingThresholds {
  /// Distance (grid units) within which the finger covers a guide sample.
  final double radius;

  /// Share of guide samples that must be covered.
  final double coverage;

  /// Share of touch points that must lie within 2 × [radius] of the guide.
  final double accuracy;

  /// Share of projected steps that must move forward along the guide.
  final double direction;

  /// How far from the stroke's start (or end) a touch may begin.
  final double startTolerance;

  /// Failed attempts on one stroke before the retry pop-up.
  final int maxFailures;

  const TracingThresholds({
    this.radius = 22,
    this.coverage = 0.80,
    this.accuracy = 0.85,
    this.direction = 0.70,
    this.startTolerance = 30,
    this.maxFailures = 3,
  });

  factory TracingThresholds.fromJson(Map<String, dynamic>? json) {
    const d = TracingThresholds();
    if (json == null) return d;
    double f(String k, double def) {
      final v = json[k];
      return v is num && v > 0 ? v.toDouble() : def;
    }

    return TracingThresholds(
      radius: f('radius', d.radius),
      coverage: f('coverage', d.coverage),
      accuracy: f('accuracy', d.accuracy),
      direction: f('direction', d.direction),
      startTolerance: f('start_tolerance', d.startTolerance),
      maxFailures: f('max_failures', d.maxFailures.toDouble()).round(),
    );
  }
}

enum StrokeFailure { offPath, tooShort, wrongDirection }

class StrokeResult {
  final bool passed;
  final StrokeFailure? failure;
  final double coverage;
  final double accuracy;
  final double direction;

  const StrokeResult({
    required this.passed,
    this.failure,
    required this.coverage,
    required this.accuracy,
    required this.direction,
  });

  /// This stroke's contribution to the letter score.
  double get score => coverage * accuracy;
}

/// One attempt at tracing one guide stroke, fed finger positions already
/// mapped to the grid.
class StrokeAttempt {
  final List<Offset> guide;
  final TracingThresholds thresholds;
  final List<bool> covered;
  final List<Offset> touches = [];

  StrokeAttempt(this.guide, this.thresholds)
    : covered = List.filled(guide.length, false);

  /// Starts the attempt at [p]. A touch far from both ends of the stroke is
  /// ignored (returns false) — the caller shakes the start marker. Starting
  /// at the far end is accepted, so tracing backwards gets judged as
  /// `wrongDirection` instead of silently doing nothing.
  bool begin(Offset p) {
    final tol = thresholds.startTolerance;
    if ((p - guide.first).distance > tol && (p - guide.last).distance > tol) {
      return false;
    }
    touches.add(p);
    _cover(p);
    return true;
  }

  /// Adds a finger position, dropping points closer than 2 units to the
  /// previous one. Returns whether any new guide sample got covered.
  bool move(Offset p) {
    if (touches.isNotEmpty && (p - touches.last).distance < 2) return false;
    touches.add(p);
    return _cover(p);
  }

  bool _cover(Offset p) {
    var changed = false;
    final r = thresholds.radius;
    for (var i = 0; i < guide.length; i++) {
      if (!covered[i] && (guide[i] - p).distance <= r) {
        covered[i] = true;
        changed = true;
      }
    }
    return changed;
  }

  int _nearest(Offset p) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < guide.length; i++) {
      final d = (guide[i] - p).distanceSquared;
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  double _distanceToGuide(Offset p) => (guide[_nearest(p)] - p).distance;

  /// Judges the attempt when the finger lifts.
  StrokeResult end() {
    final coverage = covered.where((c) => c).length / guide.length;
    final near = touches
        .where((p) => _distanceToGuide(p) <= 2 * thresholds.radius)
        .length;
    final accuracy = touches.isEmpty ? 0.0 : near / touches.length;

    // Steps are counted between projections at least 2 samples (8 units)
    // apart, so a wobbling finger doesn't read as moving backwards.
    var forward = 0;
    var backward = 0;
    var last = touches.isEmpty ? 0 : _nearest(touches.first);
    for (final p in touches.skip(1)) {
      final idx = _nearest(p);
      if ((idx - last).abs() < 2) continue;
      if (idx > last) {
        forward++;
      } else {
        backward++;
      }
      last = idx;
    }
    final steps = forward + backward;
    final direction = steps == 0 ? 0.0 : forward / steps;

    StrokeFailure? failure;
    if (steps > 0 && direction < thresholds.direction) {
      failure = StrokeFailure.wrongDirection;
    } else if (accuracy < thresholds.accuracy) {
      failure = StrokeFailure.offPath;
    } else if (coverage < thresholds.coverage || steps == 0) {
      failure = StrokeFailure.tooShort;
    }
    return StrokeResult(
      passed: failure == null,
      failure: failure,
      coverage: coverage,
      accuracy: accuracy,
      direction: direction,
    );
  }
}
