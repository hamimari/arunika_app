import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:arunika_app/core/tracing/svg_path.dart';

/// Spacing of guide samples along a stroke, in grid units.
const double kSampleSpacing = 4;

/// Flattens [path] into a dense polyline: lines as-is, curves subdivided
/// finely enough (≤ 1 unit per step) for arc-length resampling.
List<Offset> flattenPath(TracePath path) {
  final pts = <Offset>[path.start];
  var current = path.start;
  for (final seg in path.segments) {
    switch (seg.cmd) {
      case 'L':
        pts.add(seg.end);
      case 'Q':
        final c = seg.points[0];
        final e = seg.points[1];
        final steps = _steps([current, c, e]);
        for (var i = 1; i <= steps; i++) {
          final t = i / steps;
          final u = 1 - t;
          pts.add(current * (u * u) + c * (2 * u * t) + e * (t * t));
        }
      case 'C':
        final c1 = seg.points[0];
        final c2 = seg.points[1];
        final e = seg.points[2];
        final steps = _steps([current, c1, c2, e]);
        for (var i = 1; i <= steps; i++) {
          final t = i / steps;
          final u = 1 - t;
          pts.add(
            current * (u * u * u) +
                c1 * (3 * u * u * t) +
                c2 * (3 * u * t * t) +
                e * (t * t * t),
          );
        }
    }
    current = seg.end;
  }
  return pts;
}

/// Subdivisions for a curve: its control polygon length bounds its arc
/// length, so one step per unit of that is always fine enough.
int _steps(List<Offset> control) {
  var len = 0.0;
  for (var i = 1; i < control.length; i++) {
    len += (control[i] - control[i - 1]).distance;
  }
  return math.max(8, len.ceil());
}

/// Resamples [path] into points every [spacing] units along its length,
/// always including both ends.
List<Offset> sampleGuide(TracePath path, {double spacing = kSampleSpacing}) {
  final poly = flattenPath(path);
  final out = <Offset>[poly.first];
  var carried = 0.0; // distance travelled since the last emitted sample
  for (var i = 1; i < poly.length; i++) {
    final a = poly[i - 1];
    final b = poly[i];
    final segLen = (b - a).distance;
    if (segLen == 0) continue;
    var along = spacing - carried;
    while (along <= segLen) {
      out.add(Offset.lerp(a, b, along / segLen)!);
      along += spacing;
    }
    carried = segLen - (along - spacing);
  }
  if ((out.last - poly.last).distance > 0.5) out.add(poly.last);
  return out;
}

/// Total length of a sampled stroke.
double polylineLength(List<Offset> pts) {
  var len = 0.0;
  for (var i = 1; i < pts.length; i++) {
    len += (pts[i] - pts[i - 1]).distance;
  }
  return len;
}
