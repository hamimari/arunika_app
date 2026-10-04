import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:arunika_app/presentation/screens/dongeng/detail/page_curl/page_turn_controller.dart';
import 'package:flutter/material.dart';

/// Shows page [index] of a book and turns pages with a paper curl that
/// follows the finger. Arrow buttons call [PageCurlState.turn] through a
/// `GlobalKey<PageCurlState>`.
///
/// [onTurned] fires once per completed turn; a turn that springs back never
/// fires it. With reduce motion on, pages change with a cross-fade instead.
class PageCurl extends StatefulWidget {
  const PageCurl({
    super.key,
    required this.pageCount,
    required this.index,
    required this.pageBuilder,
    required this.onTurned,
  });

  final int pageCount;
  final int index;
  final Widget Function(BuildContext context, int index) pageBuilder;
  final ValueChanged<TurnDirection> onTurned;

  @override
  State<PageCurl> createState() => PageCurlState();
}

class PageCurlState extends State<PageCurl>
    with SingleTickerProviderStateMixin {
  static const arrowTurnDuration = Duration(milliseconds: 450);
  static const _releaseDuration = Duration(milliseconds: 350);

  late PageTurnController _turn = PageTurnController(
    pageCount: widget.pageCount,
    index: widget.index,
  );

  // Mirrors _turn.progress so AnimatedBuilder repaints on every change.
  late final AnimationController _anim = AnimationController(vsync: this);

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didUpdateWidget(PageCurl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pageCount != oldWidget.pageCount) {
      _anim.value = 0;
      _turn = PageTurnController(
        pageCount: widget.pageCount,
        index: widget.index,
      );
    } else if (!_turn.isTurning && widget.index != _turn.index) {
      _turn.index = widget.index; // moved from outside, e.g. GoToPage
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  /// Turns one page with the curl animation, as an arrow tap does. Ignored
  /// while a turn is running and at the ends of the book.
  void turn(TurnDirection direction) {
    if (!_turn.startTurn(direction)) return;
    if (_reduceMotion) {
      _finish(completed: true);
      return;
    }
    _anim.value = 0;
    _anim
        .animateTo(1, duration: arrowTurnDuration, curve: Curves.easeInOut)
        .then((_) => _finish(completed: true));
  }

  void _onDragUpdate(DragUpdateDetails d, double width) {
    if (_turn.dragUpdate(d.delta.dx, width)) _anim.value = _turn.progress;
  }

  void _release(double velocity) {
    final complete = _turn.dragEnd(velocity);
    if (complete == null) return;
    if (_reduceMotion) {
      _finish(completed: complete);
      return;
    }
    final target = complete ? 1.0 : 0.0;
    final remaining = (target - _anim.value).abs();
    final ms = math.max(80, (_releaseDuration.inMilliseconds * remaining).round());
    _anim
        .animateTo(
          target,
          duration: Duration(milliseconds: ms),
          curve: Curves.easeOut,
        )
        .then((_) => _finish(completed: complete));
  }

  void _finish({required bool completed}) {
    if (!mounted) return;
    final turned = _turn.settle(completed: completed);
    _anim.value = 0;
    setState(() {});
    if (turned != null) widget.onTurned(turned);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (d) => _onDragUpdate(d, constraints.maxWidth),
        onHorizontalDragEnd: (d) => _release(d.primaryVelocity ?? 0),
        onHorizontalDragCancel: () => _release(0),
        child: AnimatedBuilder(
          animation: _anim,
          builder: (context, _) => _pages(context),
        ),
      ),
    );
  }

  Widget _page(BuildContext context, int i) =>
      KeyedSubtree(key: ValueKey(i), child: widget.pageBuilder(context, i));

  Widget _pages(BuildContext context) {
    if (_reduceMotion) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        child: _page(context, _turn.index),
      );
    }
    final direction = _turn.direction;
    if (direction == null) return _page(context, _turn.index);

    // Turning back is a forward turn of the previous page, played in reverse.
    final forward = direction == TurnDirection.forward;
    return _CurlView(
      curl: forward ? _anim.value : 1 - _anim.value,
      top: _page(context, forward ? _turn.index : _turn.index - 1),
      bottom: _page(context, forward ? _turn.index + 1 : _turn.index),
    );
  }
}

/// [top] curled by [curl] (0 = flat, 1 = turned away) over [bottom].
///
/// The fold is a straight line, tilted mid-turn so the bottom corner leads.
/// Left of it, [top] lies flat. The part of [top] right of it is mirrored
/// across the fold and drawn as the back of the paper. [bottom] shows to
/// the right of the fold.
class _CurlView extends StatelessWidget {
  const _CurlView({
    required this.curl,
    required this.top,
    required this.bottom,
  });

  final double curl;
  final Widget top;
  final Widget bottom;

  static const _paperBack = Color(0xD9FFF8EC);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final f = w * (1 - curl);
        final tilt = h * 0.25 * math.sin(math.pi * curl);
        final a = Offset(f + tilt / 2, 0);
        final b = Offset(f - tilt / 2, h);

        // Unit normal to the fold, pointing at the unturned (right) side.
        final dir = b - a;
        final n = Offset(dir.dy, -dir.dx) / dir.distance;

        final flat = Path()
          ..moveTo(-w, 0)
          ..lineTo(a.dx, 0)
          ..lineTo(b.dx, h)
          ..lineTo(-w, h)
          ..close();
        final beyondFold = Path()
          ..moveTo(a.dx, 0)
          ..lineTo(2 * w, 0)
          ..lineTo(2 * w, h)
          ..lineTo(b.dx, h)
          ..close();

        return IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              bottom,
              // Shadow the flap casts on the page underneath.
              CustomPaint(
                painter: _FoldGradient(
                  origin: a,
                  normal: n,
                  reach: 36,
                  color: Colors.black.withValues(alpha: 0.35),
                ),
              ),
              ClipPath(clipper: _PathClipper(flat), child: top),
              Transform(
                key: const ValueKey('page-curl-flap'),
                transform: _reflectAcross(a, n),
                child: ClipPath(
                  clipper: _PathClipper(beyondFold),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      top,
                      const ColoredBox(color: _paperBack),
                      // Shading where the paper bends.
                      CustomPaint(
                        painter: _FoldGradient(
                          origin: a,
                          normal: n,
                          reach: 60,
                          color: Colors.black.withValues(alpha: 0.18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Mirror across the line through [p] with unit normal [n].
  static Matrix4 _reflectAcross(Offset p, Offset n) {
    final k = 2 * (p.dx * n.dx + p.dy * n.dy);
    return Matrix4(
      1 - 2 * n.dx * n.dx, -2 * n.dx * n.dy, 0, 0, //
      -2 * n.dx * n.dy, 1 - 2 * n.dy * n.dy, 0, 0, //
      0, 0, 1, 0, //
      k * n.dx, k * n.dy, 0, 1,
    );
  }
}

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);
  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper old) => old.path != path;
}

/// A band of [color] along the fold, fading out [reach] px along [normal].
class _FoldGradient extends CustomPainter {
  const _FoldGradient({
    required this.origin,
    required this.normal,
    required this.reach,
    required this.color,
  });

  final Offset origin;
  final Offset normal;
  final double reach;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Runs exactly along the normal, so the band stays parallel to a tilted
    // fold. Clamped: solid behind the fold, clear past [reach].
    final paint = Paint()
      ..shader = ui.Gradient.linear(origin, origin + normal * reach, [
        color,
        color.withValues(alpha: 0),
      ]);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(_FoldGradient old) =>
      old.origin != origin ||
      old.normal != normal ||
      old.reach != reach ||
      old.color != color;
}
