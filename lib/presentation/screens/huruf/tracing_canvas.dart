import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/core/tracing/letter_trace_session.dart';
import 'package:arunika_app/core/tracing/svg_path.dart';
import 'package:arunika_app/presentation/screens/huruf/huruf_widgets.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// The Tebalkan canvas: guide bands with dotted centre lines, numbered start
/// points, direction arrows, and the child's stroke painted in orange as the
/// finger moves. Judging is done by [LetterTraceSession]; this widget only
/// maps touches onto the 300 × 300 grid and paints.
class TracingCanvas extends StatefulWidget {
  final LetterTraceSession session;

  /// Called when the finger lifts with what the session decided.
  final ValueChanged<TraceEvent> onEvent;

  const TracingCanvas({
    super.key,
    required this.session,
    required this.onEvent,
  });

  @override
  State<TracingCanvas> createState() => TracingCanvasState();
}

class TracingCanvasState extends State<TracingCanvas>
    with TickerProviderStateMixin {
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 360),
  );
  late final AnimationController _demo = AnimationController(vsync: this);
  Offset? _finger;
  double _scale = 1;

  /// "Lihat contoh": a dot runs along every stroke in order, 600 ms each,
  /// leaving a trail.
  Future<void> playDemo() async {
    final n = widget.session.currentStrokes.length;
    if (n == 0) return;
    _demo.duration = Duration(milliseconds: 600 * n);
    await _demo.forward(from: 0);
    if (mounted) _demo.value = 0;
  }

  /// Repaint after the session changed outside a gesture (Ulangi, restart).
  void refresh() => setState(() => _finger = null);

  @override
  void dispose() {
    _shake.dispose();
    _demo.dispose();
    super.dispose();
  }

  Offset _toGrid(Offset local) => local / _scale;

  void _down(Offset local) {
    if (_demo.isAnimating) return;
    final ok = widget.session.down(_toGrid(local));
    if (!ok) {
      _shake.forward(from: 0);
      return;
    }
    setState(() => _finger = _toGrid(local));
  }

  void _move(Offset local) {
    if (widget.session.attempt == null) return;
    widget.session.move(_toGrid(local));
    setState(() => _finger = _toGrid(local));
  }

  void _up() {
    if (widget.session.attempt == null) return;
    final event = widget.session.up();
    setState(() => _finger = null);
    widget.onEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, c) {
          _scale = c.maxWidth / kTraceGrid;
          return AnimatedBuilder(
            animation: Listenable.merge([_shake, _demo]),
            builder: (context, _) {
              final dx =
                  math.sin(_shake.value * math.pi * 6) * 6 * (1 - _shake.value);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: RawGestureDetector(
                  key: const ValueKey('tracing-canvas'),
                  behavior: HitTestBehavior.opaque,
                  gestures: {
                    _EagerPanRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          _EagerPanRecognizer
                        >(_EagerPanRecognizer.new, (r) {
                          r.onStart = (d) {
                            _down(d.localPosition);
                          };
                          r.onUpdate = (d) {
                            _move(d.localPosition);
                          };
                          r.onEnd = (_) {
                            _up();
                          };
                          r.onCancel = _up;
                        }),
                  },
                  child: CustomPaint(
                    size: Size.square(c.maxWidth),
                    painter: _TracingPainter(
                      session: widget.session,
                      scale: _scale,
                      finger: _finger,
                      // In stroke units: 1.5 is halfway through stroke 2.
                      demo: _demo.isAnimating
                          ? _demo.value * widget.session.currentStrokes.length
                          : null,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// A pan that wins the gesture arena on touch-down, so tracing a vertical
/// stroke never scrolls the page instead, and reports the touch-down point
/// as the start (needed for the start-point tolerance).
class _EagerPanRecognizer extends PanGestureRecognizer {
  _EagerPanRecognizer() {
    dragStartBehavior = DragStartBehavior.down;
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}

class _TracingPainter extends CustomPainter {
  final LetterTraceSession session;
  final double scale;
  final Offset? finger;
  final double? demo;

  _TracingPainter({
    required this.session,
    required this.scale,
    required this.finger,
    required this.demo,
  });

  static const _band = Color(0xFFE9E0D6);
  static const _dots = Color(0xFF9C9389);
  static const _ink = AppColors.ctaRust;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);

    // Writing lines: top, dashed middle, baseline.
    final line = Paint()
      ..color = const Color(0xFFE2DAD0)
      ..strokeWidth = 1.5;
    canvas.drawLine(const Offset(10, 30), const Offset(290, 30), line);
    canvas.drawLine(const Offset(10, 260), const Offset(290, 260), line);
    for (var x = 10.0; x < 290; x += 10) {
      canvas.drawLine(Offset(x, 150), Offset(x + 5, 150), line);
    }

    final strokes = session.currentStrokes;
    final band = Paint()
      ..color = _band
      ..style = PaintingStyle.stroke
      ..strokeWidth = 34
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final s in strokes) {
      canvas.drawPath(_polyline(s.samples), band);
    }
    final dot = Paint()..color = _dots;
    for (final s in strokes) {
      for (var i = 0; i < s.samples.length; i += 3) {
        canvas.drawCircle(s.samples[i], 1.6, dot);
      }
    }

    // Finished strokes, then the live one's covered samples.
    final ink = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final done = session.letterComplete ? strokes.length : session.activeIndex;
    for (var i = 0; i < done && i < strokes.length; i++) {
      canvas.drawPath(_polyline(strokes[i].samples), ink);
    }
    final attempt = session.attempt;
    if (attempt != null) {
      final path = Path();
      var open = false;
      for (var i = 0; i < attempt.guide.length; i++) {
        if (attempt.covered[i]) {
          final p = attempt.guide[i];
          if (open) {
            path.lineTo(p.dx, p.dy);
          } else {
            path.moveTo(p.dx, p.dy);
            path.lineTo(p.dx + 0.01, p.dy);
            open = true;
          }
        } else {
          open = false;
        }
      }
      canvas.drawPath(path, ink);
    }

    // Direction arrows at 60% of each stroke, then numbered start markers.
    for (final s in strokes) {
      _arrow(canvas, s.samples);
    }
    for (var i = 0; i < strokes.length; i++) {
      final active = i == session.activeIndex && !session.letterComplete;
      _marker(canvas, strokes[i].start, strokes[i].order, active);
    }

    if (demo != null && strokes.isNotEmpty) {
      final idx = demo!.floor().clamp(0, strokes.length - 1);
      final frac = (demo! - idx).clamp(0.0, 1.0);
      final pts = strokes[idx].samples;
      final end = (frac * (pts.length - 1)).round();
      // Leave a trail so the whole letter builds up stroke by stroke.
      final trail = Paint()
        ..color = _ink.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      for (var i = 0; i < idx; i++) {
        canvas.drawPath(_polyline(strokes[i].samples), trail);
      }
      if (end > 0) {
        canvas.drawPath(_polyline(pts.sublist(0, end + 1)), trail);
      }
      final p = pts[end];
      canvas.drawCircle(p, 12, Paint()..color = AppColors.white);
      canvas.drawCircle(
        p,
        12,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }

    if (finger != null) {
      canvas.drawCircle(finger!, 13, Paint()..color = AppColors.white);
      canvas.drawCircle(
        finger!,
        13,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    canvas.restore();
  }

  Path _polyline(List<Offset> pts) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    return path;
  }

  void _arrow(Canvas canvas, List<Offset> pts) {
    if (pts.length < 4) return;
    final i = (pts.length * 0.6).floor().clamp(1, pts.length - 1);
    final dir = pts[i] - pts[i - 1];
    if (dir.distance == 0) return;
    final angle = math.atan2(dir.dy, dir.dx);
    // Beside the band, so it doesn't cover the stroke.
    final normal = Offset(-math.sin(angle), math.cos(angle)) * 30;
    final at = pts[i] + normal;
    final paint = Paint()
      ..color = HurufColors.teal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.save();
    canvas.translate(at.dx, at.dy);
    canvas.rotate(angle);
    canvas.drawLine(const Offset(-9, 0), const Offset(9, 0), paint);
    canvas.drawLine(const Offset(9, 0), const Offset(2, -6), paint);
    canvas.drawLine(const Offset(9, 0), const Offset(2, 6), paint);
    canvas.restore();
  }

  void _marker(Canvas canvas, Offset at, int n, bool active) {
    // The active stroke's start is larger and haloed.
    final r = active ? 15.0 : 12.0;
    canvas.drawCircle(at, r, Paint()..color = HurufColors.teal);
    if (active) {
      canvas.drawCircle(
        at,
        r + 3,
        Paint()
          ..color = HurufColors.teal.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        text: '$n',
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _TracingPainter old) => true;
}
