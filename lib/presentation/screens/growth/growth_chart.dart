import 'dart:math' as math;

import 'package:arunika_app/constants/app_colors.dart';
import 'package:arunika_app/constants/app_text_styles.dart';
import 'package:arunika_app/core/growth/growth_engine.dart';
import 'package:arunika_app/core/growth/growth_format.dart';
import 'package:arunika_app/data/models/response/growth_response.dart';
import 'package:flutter/material.dart';

/// One plotted measurement: age in days and the value used for the z-score
/// (height adjusted for position).
class ChartPoint {
  final int ageDays;
  final double value;
  const ChartPoint(this.ageDays, this.value);
}

/// Zone cut-offs (SD lines) per indicator, bottom to top, and the colour of
/// the band below each line; [topZone] fills above the last line.
class _Zones {
  final List<double> cutoffs;
  final List<Color> below;
  final Color topZone;
  const _Zones(this.cutoffs, this.below, this.topZone);
}

const _heightZones = _Zones(
  [-3, -2, 3],
  [GrowthPalette.zoneRed, GrowthPalette.zoneAmber, GrowthPalette.zoneGreen],
  GrowthPalette.zoneBlue,
);
const _weightZones = _Zones(
  [-3, -2, 1],
  [GrowthPalette.zoneRed, GrowthPalette.zoneAmber, GrowthPalette.zoneGreen],
  GrowthPalette.zoneAmber,
);

/// The x-window of the chart: 3 months either side of the measurements,
/// within 0–60 months.
(int, int) chartWindowDays(List<int> ages) {
  const pad = 91; // ≈ 3 months
  if (ages.isEmpty) return (0, 365);
  final lo = math.max(0, ages.reduce(math.min) - pad);
  final hi = math.min(maxAgeDays, ages.reduce(math.max) + pad);
  return (lo, math.max(hi, lo + 2 * pad));
}

/// Points for [indicator], oldest first, skipping values past five years.
List<ChartPoint> chartPoints(
  List<GrowthMeasurement> measurements,
  Indicator indicator,
) {
  final out = <ChartPoint>[];
  for (final m in measurements.reversed) {
    if (m.ageDays < 0 || m.ageDays > maxAgeDays) continue;
    final v = indicator == Indicator.heightForAge
        ? (m.heightCm == null
              ? null
              : adjustHeight(m.heightCm!, m.position, m.ageDays))
        : m.weightKg;
    if (v != null) out.add(ChartPoint(m.ageDays, v));
  }
  return out;
}

/// "Standar WHO · laki-laki · 2–4 tahun".
String chartSubtitle(Sex sex, (int, int) window) {
  final from = (window.$1 / 365.25).floor();
  final to = (window.$2 / 365.25).ceil();
  final range = from == to ? '$from tahun' : '$from–$to tahun';
  return 'Standar WHO · ${sex == Sex.male ? 'laki-laki' : 'perempuan'} · $range';
}

class GrowthChart extends StatelessWidget {
  final WhoGrowthStandard standard;
  final Indicator indicator;
  final Sex sex;
  final List<ChartPoint> points;
  final (int, int) window;
  final String semanticLabel;

  const GrowthChart({
    super.key,
    required this.standard,
    required this.indicator,
    required this.sex,
    required this.points,
    required this.window,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: 1.15,
        child: CustomPaint(
          painter: GrowthChartPainter(
            standard: standard,
            indicator: indicator,
            sex: sex,
            points: points,
            window: window,
            labelStyle: AppTextStyles.caption.copyWith(
              fontSize: 10,
              color: AppColors.textMedium,
            ),
            bubbleStyle: AppTextStyles.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class GrowthChartPainter extends CustomPainter {
  final WhoGrowthStandard standard;
  final Indicator indicator;
  final Sex sex;
  final List<ChartPoint> points;
  final (int, int) window;
  final TextStyle labelStyle;
  final TextStyle bubbleStyle;

  static const _lineColor = AppColors.ctaRust;
  static const _stepDays = 7;

  GrowthChartPainter({
    required this.standard,
    required this.indicator,
    required this.sex,
    required this.points,
    required this.window,
    required this.labelStyle,
    required this.bubbleStyle,
  });

  bool get _height => indicator == Indicator.heightForAge;
  _Zones get _zones => _height ? _heightZones : _weightZones;

  List<int> get _days {
    final (lo, hi) = window;
    return [for (var d = lo; d < hi; d += _stepDays) d, hi];
  }

  double _sd(int day, double k) => standard.sdValue(indicator, sex, day, k)!;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0, top = 20.0, right = 6.0, bottom = 22.0;
    final plot = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final (lo, hi) = window;
    final days = _days;

    // y fits the −3 and +3 SD curves (and the child's points) plus a margin.
    final pad = _height ? 2.0 : 0.5;
    var yMin = days.map((d) => _sd(d, -3)).reduce(math.min) - pad;
    var yMax = days.map((d) => _sd(d, 3)).reduce(math.max) + pad;
    for (final p in points) {
      yMin = math.min(yMin, p.value - pad);
      yMax = math.max(yMax, p.value + pad);
    }
    final step = _niceStep(yMax - yMin);
    yMin = (yMin / step).floorToDouble() * step;
    yMax = (yMax / step).ceilToDouble() * step;

    double x(num day) => plot.left + (day - lo) / (hi - lo) * plot.width;
    double y(double v) =>
        plot.bottom - (v - yMin) / (yMax - yMin) * plot.height;

    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(plot, const Radius.circular(6)));

    // Zones: top colour everywhere, then each band below its SD line.
    canvas.drawRect(plot, Paint()..color = _zones.topZone);
    for (var i = _zones.cutoffs.length - 1; i >= 0; i--) {
      final k = _zones.cutoffs[i];
      final path = Path()..moveTo(x(days.first), plot.bottom);
      for (final d in days) {
        path.lineTo(x(d), y(_sd(d, k)));
      }
      path
        ..lineTo(x(days.last), plot.bottom)
        ..close();
      canvas.drawPath(path, Paint()..color = _zones.below[i]);
    }

    // Grid.
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 1;
    for (final d in _xTicks()) {
      canvas.drawLine(Offset(x(d), plot.top), Offset(x(d), plot.bottom), grid);
    }
    for (var v = yMin + step; v < yMax; v += step) {
      canvas.drawLine(Offset(plot.left, y(v)), Offset(plot.right, y(v)), grid);
    }

    // Median, dashed.
    final median = Path()..moveTo(x(days.first), y(_sd(days.first, 0)));
    for (final d in days.skip(1)) {
      median.lineTo(x(d), y(_sd(d, 0)));
    }
    _drawDashed(
      canvas,
      median,
      Paint()
        ..color = const Color(0xFF3A3A3A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // The child's series.
    if (points.isNotEmpty) {
      final line = Path()
        ..moveTo(x(points.first.ageDays), y(points.first.value));
      for (final p in points.skip(1)) {
        line.lineTo(x(p.ageDays), y(p.value));
      }
      canvas.drawPath(
        line,
        Paint()
          ..color = _lineColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );
      for (final p in points.take(points.length - 1)) {
        final c = Offset(x(p.ageDays), y(p.value));
        canvas.drawCircle(c, 4.5, Paint()..color = Colors.white);
        canvas.drawCircle(
          c,
          4.5,
          Paint()
            ..color = _lineColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
    canvas.restore();

    // Latest point and its label (drawn unclipped so the bubble can overhang).
    if (points.isNotEmpty) {
      final last = points.last;
      final c = Offset(x(last.ageDays), y(last.value));
      canvas.drawCircle(c, 7, Paint()..color = Colors.white);
      canvas.drawCircle(c, 5.5, Paint()..color = _lineColor);
      _drawBubble(canvas, c, formatDecimal(last.value), plot);
    }

    // Axis labels.
    _text(canvas, _height ? 'cm' : 'kg', Offset(2, plot.top - 16));
    for (var v = yMin + step; v < yMax; v += step) {
      _text(canvas, _fmtTick(v), Offset(2, y(v) - 6));
    }
    for (final d in _xTicks()) {
      final label = _ageTick(d);
      final tp = _layout(label);
      final dx = (x(d) - tp.width / 2).clamp(
        plot.left - 4,
        size.width - tp.width,
      );
      tp.paint(canvas, Offset(dx, plot.bottom + 5));
    }
  }

  /// Ticks every 3 or 6 months depending on the window.
  List<int> _xTicks() {
    final (lo, hi) = window;
    final spanMonths = (hi - lo) / 30.4375;
    final every = spanMonths > 30 ? 12 : (spanMonths > 15 ? 6 : 3);
    final ticks = <int>[];
    for (
      var m = (lo / 30.4375 / every).ceil() * every;
      m * 30.4375 <= hi;
      m += every
    ) {
      ticks.add((m * 30.4375).round());
    }
    return ticks;
  }

  /// "2 th", "2,5", "9 bln".
  String _ageTick(int day) {
    final months = (day / 30.4375).round();
    if (months < 12) return '$months bln';
    if (months % 12 == 0) return '${months ~/ 12} th';
    final years = months / 12;
    return years.toStringAsFixed(1).replaceAll('.', ',');
  }

  String _fmtTick(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : formatDecimal(v);

  double _niceStep(double range) {
    final raw = range / 4;
    for (final s in [0.5, 1.0, 2.0, 2.5, 5.0, 10.0, 20.0]) {
      if (raw <= s) return s;
    }
    return 25;
  }

  TextPainter _layout(String s, [TextStyle? style]) => TextPainter(
    text: TextSpan(text: s, style: style ?? labelStyle),
    textDirection: TextDirection.ltr,
  )..layout();

  void _text(Canvas canvas, String s, Offset at) =>
      _layout(s).paint(canvas, at);

  void _drawBubble(Canvas canvas, Offset point, String label, Rect plot) {
    final tp = _layout(label, bubbleStyle);
    final w = tp.width + 16, h = tp.height + 8;
    var dx = point.dx - w / 2;
    dx = dx.clamp(plot.left, plot.right - w);
    final dy = math.max(2.0, point.dy - h - 10);
    final r = RRect.fromRectAndRadius(
      Rect.fromLTWH(dx, dy, w, h),
      const Radius.circular(9),
    );
    canvas.drawRRect(r, Paint()..color = const Color(0xFF2B2522));
    tp.paint(canvas, Offset(dx + 8, dy + 4));
  }

  void _drawDashed(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(GrowthChartPainter old) =>
      old.indicator != indicator ||
      old.sex != sex ||
      old.window != window ||
      old.points.length != points.length ||
      !_samePoints(old.points, points);

  static bool _samePoints(List<ChartPoint> a, List<ChartPoint> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i].ageDays != b[i].ageDays || a[i].value != b[i].value) {
        return false;
      }
    }
    return true;
  }
}
