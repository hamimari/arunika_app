import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:arunika_app/core/tracing/guide_sampler.dart';
import 'package:arunika_app/core/tracing/letter_trace_session.dart';
import 'package:arunika_app/core/tracing/stroke_evaluator.dart';
import 'package:arunika_app/core/tracing/svg_path.dart';
import 'package:flutter_test/flutter_test.dart';

GuideStroke stroke(int order, String path) => GuideStroke(
  order: order,
  label: 'garis $order',
  path: parseTracePath(path),
);

final letterA = [
  stroke(1, 'M150 30 L70 260'),
  stroke(2, 'M150 30 L230 260'),
  stroke(3, 'M99 170 L201 170'),
];

// B: a stem and two bowls (quadratic curves).
final letterB = [
  stroke(1, 'M90 40 L90 260'),
  stroke(2, 'M90 40 Q200 40 200 95 Q200 150 90 150'),
  stroke(3, 'M90 150 Q215 150 215 205 Q215 260 90 260'),
];

// O: one closed-looking cubic loop.
final letterO = [
  stroke(1, 'M150 40 C60 40 60 260 150 260 C240 260 240 40 151 40'),
];

// Lowercase a: bowl then stem.
final lowerA = [
  stroke(1, 'M200 140 C120 100 80 200 140 230 C180 245 200 210 200 190'),
  stroke(2, 'M200 140 L200 240'),
];

/// Points along [s]'s guide with a smooth, deterministic wobble of up to
/// [noise] units — the way a finger drifts, not per-point jitter.
List<Offset> follow(
  GuideStroke s, {
  double from = 0,
  double to = 1,
  double noise = 0,
  bool reversed = false,
}) {
  final pts = s.samples;
  final a = (from * (pts.length - 1)).round();
  final b = (to * (pts.length - 1)).round();
  var out = [
    for (var i = a; i <= b; i++)
      pts[i] + Offset(math.sin(i * 0.35) * noise, math.cos(i * 0.27) * noise),
  ];
  if (reversed) out = out.reversed.toList();
  return out;
}

TraceEvent trace(LetterTraceSession session, List<Offset> pts) {
  if (!session.down(pts.first)) return TraceEvent.ignored;
  for (final p in pts.skip(1)) {
    session.move(p);
  }
  return session.up();
}

StrokeResult judge(GuideStroke s, List<Offset> pts) {
  final a = StrokeAttempt(s.samples, const TracingThresholds());
  expect(a.begin(pts.first), isTrue, reason: 'attempt should start');
  for (final p in pts.skip(1)) {
    a.move(p);
  }
  return a.end();
}

void main() {
  group('svg path parity', () {
    final fixture =
        jsonDecode(File('test/fixtures/svg_paths.json').readAsStringSync())
            as Map<String, dynamic>;

    for (final c in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
      test('"${c['path']}" is ${c['valid'] ? 'valid' : 'invalid'}', () {
        if (c['valid'] as bool) {
          final p = parseTracePath(c['path'] as String);
          expect(p.segments, hasLength(c['segments']));
        } else {
          expect(
            () => parseTracePath(c['path'] as String),
            throwsA(isA<SvgPathException>()),
          );
        }
      });
    }

    test('points are read in order', () {
      final p = parseTracePath('M200 80 C180 30 80 30 80 150');
      expect(p.start, const Offset(200, 80));
      expect(p.segments.single.cmd, 'C');
      expect(p.segments.single.points, const [
        Offset(180, 30),
        Offset(80, 30),
        Offset(80, 150),
      ]);
      expect(isValidTracePath('M1 1 L2 2'), isTrue);
      expect(isValidTracePath('M1 1'), isFalse);
    });
  });

  group('guide sampling', () {
    test('straight stroke is sampled every 4 units, ends included', () {
      final s = sampleGuide(parseTracePath('M150 30 L70 260'));
      expect(s.first, const Offset(150, 30));
      expect((s.last - const Offset(70, 260)).distance, lessThan(0.5));
      for (var i = 1; i < s.length - 1; i++) {
        expect((s[i] - s[i - 1]).distance, closeTo(4, 0.5));
      }
    });

    test('curves are flattened along their arc', () {
      final s = sampleGuide(parseTracePath('M50 150 Q150 0 250 150'));
      for (var i = 1; i < s.length - 1; i++) {
        expect((s[i] - s[i - 1]).distance, closeTo(4, 0.5));
      }
      // The apex of this quadratic is at y = 75.
      final top = s.map((p) => p.dy).reduce(math.min);
      expect(top, closeTo(75, 1));
      expect(polylineLength(s), greaterThan(200));
    });
  });

  group('stroke evaluation', () {
    for (final entry in {
      'A': letterA,
      'B': letterB,
      'O': letterO,
      'a': lowerA,
    }.entries) {
      test('exact and noisy traces pass for ${entry.key}', () {
        for (final s in entry.value) {
          expect(
            judge(s, follow(s)).passed,
            isTrue,
            reason: 'exact ${s.order}',
          );
          expect(
            judge(s, follow(s, noise: 10)).passed,
            isTrue,
            reason: 'noisy ${s.order}',
          );
        }
      });
    }

    test('a reversed trace fails with wrongDirection', () {
      final r = judge(letterA[0], follow(letterA[0], reversed: true));
      expect(r.passed, isFalse);
      expect(r.failure, StrokeFailure.wrongDirection);
    });

    test('a half trace fails with tooShort', () {
      final r = judge(letterA[0], follow(letterA[0], to: 0.5));
      expect(r.failure, StrokeFailure.tooShort);
      expect(r.coverage, lessThan(0.8));
    });

    test('a scribble away from the guide fails with offPath', () {
      final s = letterA[0];
      final pts = [
        s.start,
        for (var i = 0; i < 40; i++)
          Offset(150 + 60 * math.sin(i / 3), 30 + i * 6.0),
      ];
      expect(judge(s, pts).failure, StrokeFailure.offPath);
    });

    test('a touch far from the start is ignored', () {
      final a = StrokeAttempt(letterA[0].samples, const TracingThresholds());
      expect(a.begin(letterA[0].start + const Offset(60, 0)), isFalse);
      expect(a.touches, isEmpty);
    });

    test('points closer than 2 units are dropped', () {
      final a = StrokeAttempt(letterA[2].samples, const TracingThresholds());
      a.begin(const Offset(99, 170));
      a.move(const Offset(100, 170));
      expect(a.touches, hasLength(1));
      expect(a.move(const Offset(130, 170)), isTrue, reason: 'new coverage');
      expect(a.touches, hasLength(2));
    });

    test('thresholds come from the manifest, with defaults', () {
      final t = TracingThresholds.fromJson({
        'radius': 30,
        'coverage': 0.7,
        'max_failures': 5,
        'accuracy': 'bad',
      });
      expect(t.radius, 30);
      expect(t.coverage, 0.7);
      expect(t.maxFailures, 5);
      expect(t.accuracy, 0.85);
      expect(TracingThresholds.fromJson(null).direction, 0.70);
    });

    test('a looser coverage threshold lets a 70% trace pass', () {
      final s = letterA[0];
      final pts = follow(s, to: 0.7);
      final strict = StrokeAttempt(s.samples, const TracingThresholds());
      final loose = StrokeAttempt(
        s.samples,
        const TracingThresholds(coverage: 0.7),
      );
      for (final a in [strict, loose]) {
        a.begin(pts.first);
        pts.skip(1).forEach(a.move);
      }
      expect(strict.end().passed, isFalse);
      expect(loose.end().passed, isTrue);
    });
  });

  group('letter session', () {
    test('strokes are traced in order and the letter completes', () {
      final session = LetterTraceSession(upper: letterA);
      // Stroke 3 first is ignored: it isn't active.
      expect(trace(session, follow(letterA[2])), TraceEvent.ignored);
      expect(trace(session, follow(letterA[0])), TraceEvent.strokePassed);
      expect(session.activeIndex, 1);
      expect(trace(session, follow(letterA[1])), TraceEvent.strokePassed);
      expect(trace(session, follow(letterA[2])), TraceEvent.letterDone);
      expect(session.letterComplete, isTrue);
      expect(session.score, greaterThan(0.9));
    });

    test('lowercase is required after uppercase when set', () {
      final session = LetterTraceSession(
        upper: letterA,
        lower: lowerA,
        lowerRequired: true,
      );
      for (final s in letterA.take(2)) {
        trace(session, follow(s));
      }
      expect(trace(session, follow(letterA[2])), TraceEvent.caseDone);
      expect(session.currentCase, LetterCase.lower);
      expect(session.letterComplete, isFalse);
      trace(session, follow(lowerA[0]));
      expect(trace(session, follow(lowerA[1])), TraceEvent.letterDone);
    });

    test('three failures on a stroke ask for help', () {
      final session = LetterTraceSession(upper: letterA);
      final half = follow(letterA[0], to: 0.5);
      expect(trace(session, half), TraceEvent.strokeFailed);
      expect(session.lastFailure, StrokeFailure.tooShort);
      expect(trace(session, half), TraceEvent.strokeFailed);
      expect(trace(session, half), TraceEvent.needsHelp);
      // The counter restarts after the pop-up.
      expect(trace(session, half), TraceEvent.strokeFailed);
      expect(session.activeIndex, 0);
    });

    test('Ulangi clears the current case; restart clears everything', () {
      final session = LetterTraceSession(upper: letterA);
      trace(session, follow(letterA[0]));
      trace(session, follow(letterA[1]));
      session.resetCase();
      expect(session.activeIndex, 0);
      expect(session.score, 0);
      for (final s in letterA) {
        trace(session, follow(s));
      }
      expect(session.letterComplete, isTrue);
      session.restart();
      expect(session.letterComplete, isFalse);
      expect(session.currentCase, LetterCase.upper);
    });
  });
}
