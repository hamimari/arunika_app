/// Which way a page is turning.
enum TurnDirection { forward, backward }

/// Gesture rules for turning book pages, kept free of Flutter so they can be
/// unit-tested. `PageCurl` feeds it drags and arrow taps, animates [progress],
/// and calls [settle] when the animation lands.
///
/// [progress] runs 0 → 1 as a turn goes from "not started" to "done", in
/// either direction.
class PageTurnController {
  /// A released drag completes the turn past this share of the width…
  static const double completeAt = 0.35;

  /// …or when flung at least this fast (px/s) in the turn's direction.
  static const double flingVelocity = 800;

  PageTurnController({required this.pageCount, this.index = 0});

  final int pageCount;
  int index;

  TurnDirection? _direction;
  double _progress = 0;
  bool _animating = false;

  TurnDirection? get direction => _direction;
  double get progress => _progress;

  /// True from the first drag movement (or arrow tap) until [settle].
  bool get isTurning => _direction != null;

  /// True once the turn has been released and is animating to its end.
  bool get isAnimating => _animating;

  bool canTurn(TurnDirection d) => d == TurnDirection.forward
      ? index < pageCount - 1
      : index > 0;

  /// Index of the page the current turn is heading to.
  int? get targetIndex => switch (_direction) {
    TurnDirection.forward => index + 1,
    TurnDirection.backward => index - 1,
    null => null,
  };

  /// A horizontal drag moved by [dx] px on a page [width] px wide. The first
  /// movement picks the direction: right-to-left turns forward. Returns
  /// whether the drag is driving a turn.
  bool dragUpdate(double dx, double width) {
    if (_animating || width <= 0) return false;
    if (_direction == null) {
      if (dx == 0) return false;
      final d = dx < 0 ? TurnDirection.forward : TurnDirection.backward;
      if (!canTurn(d)) return false;
      _direction = d;
    }
    final signed = _direction == TurnDirection.forward ? -dx : dx;
    _progress = (_progress + signed / width).clamp(0.0, 1.0);
    return true;
  }

  /// The finger lifted with horizontal [velocity] px/s (negative = leftward).
  /// Returns true to finish the turn, false to spring back, or null when no
  /// turn was in progress.
  bool? dragEnd(double velocity) {
    if (_direction == null || _animating) return null;
    _animating = true;
    final along = _direction == TurnDirection.forward ? -velocity : velocity;
    return _progress >= completeAt || along >= flingVelocity;
  }

  /// Starts an animated turn from an arrow tap. Ignored mid-turn and at the
  /// ends of the book.
  bool startTurn(TurnDirection d) {
    if (isTurning || !canTurn(d)) return false;
    _direction = d;
    _progress = 0;
    _animating = true;
    return true;
  }

  /// Lets the animation report where it is.
  void setProgress(double p) => _progress = p.clamp(0.0, 1.0);

  /// The animation landed. When [completed], moves to the target page and
  /// returns its direction; otherwise (spring-back) returns null.
  TurnDirection? settle({required bool completed}) {
    final d = _direction;
    if (completed && d != null) index = targetIndex!;
    _direction = null;
    _progress = 0;
    _animating = false;
    return completed ? d : null;
  }
}
