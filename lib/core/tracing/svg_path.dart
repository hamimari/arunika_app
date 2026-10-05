import 'dart:ui' show Offset;

/// Belajar Huruf tracing guide strokes: one open subpath of absolute `M`,
/// `L`, `Q` and `C` commands on the 300 × 300 grid.
///
/// A port of the backend's `hurufpath` package. Both (and the backoffice)
/// must accept and reject exactly the paths in `svg_paths.json`, so a stroke
/// that publishes always parses on the device.
const double kTraceGrid = 300;

/// One drawing command after the initial `M`: `L` (end), `Q` (control, end)
/// or `C` (control 1, control 2, end).
class PathSegment {
  final String cmd;
  final List<Offset> points;

  const PathSegment(this.cmd, this.points);

  Offset get end => points.last;
}

class TracePath {
  final Offset start;
  final List<PathSegment> segments;

  const TracePath(this.start, this.segments);
}

class SvgPathException implements Exception {
  final String message;

  const SvgPathException(this.message);

  @override
  String toString() => 'SvgPathException: $message';
}

const _arity = {'M': 1, 'L': 1, 'Q': 2, 'C': 3};

/// A command letter (`cmd` set) or a number (`num` set).
class _Token {
  final String? cmd;
  final double? num;

  const _Token.cmd(this.cmd) : num = null;
  const _Token.num(this.num) : cmd = null;
}

List<_Token> _tokenize(String s) {
  final out = <_Token>[];
  var i = 0;
  bool isDigit(int c) => c >= 0x30 && c <= 0x39;
  while (i < s.length) {
    final c = s[i];
    if (c == ' ' || c == ',' || c == '\t' || c == '\n' || c == '\r') {
      i++;
    } else if (_arity.containsKey(c)) {
      out.add(_Token.cmd(c));
      i++;
    } else if (c == '-' || c == '+' || c == '.' || isDigit(c.codeUnitAt(0))) {
      var j = i;
      if (s[j] == '-' || s[j] == '+') j++;
      var digits = 0;
      while (j < s.length && isDigit(s.codeUnitAt(j))) {
        j++;
        digits++;
      }
      if (j < s.length && s[j] == '.') {
        j++;
        while (j < s.length && isDigit(s.codeUnitAt(j))) {
          j++;
          digits++;
        }
      }
      if (digits == 0) throw SvgPathException('bad number at $i');
      final v = double.tryParse(s.substring(i, j));
      if (v == null) throw SvgPathException('bad number at $i');
      out.add(_Token.num(v));
      i = j;
    } else {
      throw SvgPathException('unsupported character "$c" at $i');
    }
  }
  return out;
}

/// Parses and validates a stroke path; throws [SvgPathException].
TracePath parseTracePath(String s) {
  final toks = _tokenize(s);
  if (toks.isEmpty) throw const SvgPathException('empty path');
  if (toks.first.cmd != 'M') {
    throw const SvgPathException('path must start with M');
  }
  Offset? start;
  final segments = <PathSegment>[];
  String? cmd;
  var i = 0;
  while (i < toks.length) {
    if (toks[i].cmd != null) {
      cmd = toks[i].cmd;
      if (cmd == 'M' && start != null) {
        throw const SvgPathException('only one subpath is allowed');
      }
      i++;
    } else if (cmd == 'M') {
      // Extra coordinate pairs after M are implicit L commands (SVG).
      cmd = 'L';
    }
    final n = _arity[cmd]!;
    if (i + 2 * n > toks.length) {
      throw SvgPathException('$cmd needs ${2 * n} coordinates');
    }
    final pts = <Offset>[];
    for (var k = 0; k < n; k++) {
      final x = toks[i + 2 * k].num;
      final y = toks[i + 2 * k + 1].num;
      if (x == null || y == null) {
        throw SvgPathException('$cmd needs ${2 * n} coordinates');
      }
      if (x < 0 || x > kTraceGrid || y < 0 || y > kTraceGrid) {
        throw SvgPathException('($x, $y) is outside the grid');
      }
      pts.add(Offset(x, y));
    }
    i += 2 * n;
    if (cmd == 'M') {
      start = pts.first;
    } else {
      segments.add(PathSegment(cmd!, pts));
    }
  }
  if (segments.isEmpty) {
    throw const SvgPathException('path needs a segment after M');
  }
  return TracePath(start!, segments);
}

/// Whether [s] is a valid stroke path.
bool isValidTracePath(String s) {
  try {
    parseTracePath(s);
    return true;
  } on SvgPathException {
    return false;
  }
}
