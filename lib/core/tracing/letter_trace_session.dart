import 'dart:ui' show Offset;

import 'package:arunika_app/core/tracing/guide_sampler.dart';
import 'package:arunika_app/core/tracing/stroke_evaluator.dart';
import 'package:arunika_app/core/tracing/svg_path.dart';

/// A guide stroke ready to trace.
class GuideStroke {
  final int order;
  final String label;
  final TracePath path;
  final List<Offset> samples;

  GuideStroke({required this.order, required this.label, required this.path})
    : samples = sampleGuide(path);

  Offset get start => samples.first;
}

enum LetterCase { upper, lower }

/// What happened when the finger lifted.
enum TraceEvent {
  /// The touch didn't start near the active stroke; nothing was counted.
  ignored,

  /// The stroke passed and the next one is active.
  strokePassed,

  /// The stroke passed and the upper case is done; the lower case begins.
  caseDone,

  /// Every required stroke passed.
  letterDone,

  /// The stroke failed and was reset.
  strokeFailed,

  /// The stroke failed `maxFailures` times in a row: show the retry pop-up.
  needsHelp,
}

/// Tracing one letter: strokes in order, upper case then (when required)
/// lower case.
class LetterTraceSession {
  final Map<LetterCase, List<GuideStroke>> strokes;
  final bool lowerRequired;
  final TracingThresholds thresholds;

  LetterCase _case = LetterCase.upper;
  int _active = 0;
  int _failures = 0;
  StrokeAttempt? _attempt;
  StrokeResult? _lastResult;
  final List<StrokeResult> _passed = [];

  LetterTraceSession({
    required List<GuideStroke> upper,
    List<GuideStroke> lower = const [],
    this.lowerRequired = false,
    this.thresholds = const TracingThresholds(),
  }) : strokes = {
         LetterCase.upper: [...upper]
           ..sort((a, b) => a.order.compareTo(b.order)),
         LetterCase.lower: [...lower]
           ..sort((a, b) => a.order.compareTo(b.order)),
       };

  LetterCase get currentCase => _case;
  List<GuideStroke> get currentStrokes => strokes[_case]!;

  /// Index of the stroke to trace next in [currentStrokes].
  int get activeIndex => _active;
  GuideStroke? get activeStroke =>
      _active < currentStrokes.length ? currentStrokes[_active] : null;

  /// The attempt in progress, for painting its coverage.
  StrokeAttempt? get attempt => _attempt;

  /// Why the last attempt failed, if it did.
  StrokeFailure? get lastFailure => _lastResult?.failure;

  /// Letter score: mean of coverage × accuracy over every passed stroke.
  double get score {
    if (_passed.isEmpty) return 0;
    final sum = _passed.fold<double>(0, (s, r) => s + r.score);
    return double.parse((sum / _passed.length).toStringAsFixed(2));
  }

  bool _letterComplete = false;
  bool get letterComplete => _letterComplete;

  /// Finger down. Returns false when the touch is ignored.
  bool down(Offset p) {
    final stroke = activeStroke;
    if (stroke == null || _letterComplete) return false;
    final a = StrokeAttempt(stroke.samples, thresholds);
    if (!a.begin(p)) {
      _attempt = null;
      return false;
    }
    _attempt = a;
    return true;
  }

  /// Finger moves; returns whether newly covered samples need repainting.
  bool move(Offset p) => _attempt?.move(p) ?? false;

  /// Finger up: judge the attempt.
  TraceEvent up() {
    final a = _attempt;
    if (a == null) return TraceEvent.ignored;
    final r = a.end();
    _lastResult = r;
    _attempt = null;
    if (!r.passed) {
      _failures++;
      if (_failures >= thresholds.maxFailures) {
        _failures = 0;
        return TraceEvent.needsHelp;
      }
      return TraceEvent.strokeFailed;
    }
    _failures = 0;
    _passed.add(r);
    _active++;
    if (_active < currentStrokes.length) return TraceEvent.strokePassed;
    if (_case == LetterCase.upper &&
        lowerRequired &&
        strokes[LetterCase.lower]!.isNotEmpty) {
      _case = LetterCase.lower;
      _active = 0;
      return TraceEvent.caseDone;
    }
    _letterComplete = true;
    return TraceEvent.letterDone;
  }

  /// "Ulangi": clears every stroke of the current case.
  void resetCase() {
    final cleared = currentStrokes.length;
    final keep = _passed.length - (_active.clamp(0, cleared));
    _passed.removeRange(keep.clamp(0, _passed.length), _passed.length);
    _active = 0;
    _failures = 0;
    _attempt = null;
    _lastResult = null;
    _letterComplete = false;
  }

  /// "Tebalkan lagi": start the whole letter over.
  void restart() {
    _case = LetterCase.upper;
    _passed.clear();
    resetCase();
  }
}
