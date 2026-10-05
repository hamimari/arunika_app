import 'dart:convert';
import 'dart:io';

import 'package:arunika_app/core/angka/prng.dart';
import 'package:arunika_app/core/angka/question_generator.dart';
import 'package:flutter_test/flutter_test.dart';

/// A question in the golden file's compact form:
/// [count, object_id, size, layout, [x1, y1, …]].
List<Object> compact(AngkaQuestion q) => [
  q.count,
  q.objectId,
  q.size,
  q.layout,
  [
    for (final p in q.points) ...[p.x, p.y],
  ],
];

List<AngkaQuestion> generateFrom(Map<String, dynamic> p) =>
    AngkaGenerator.generate(
      min: p['min'] as int,
      max: p['max'] as int,
      count: p['count'] as int,
      objectIds: [for (final o in p['object_ids'] as List) o as String],
      layout: p['layout'] as String,
      seed: p['seed'] as int,
    );

void main() {
  test('mulberry32 matches the canonical JavaScript values', () {
    final r = Mulberry32(1);
    expect([r.next(), r.next(), r.next()], [2693262067, 11749833, 2265367787]);
  });

  test('imul32 keeps the low 32 bits of large products', () {
    expect(imul32(0xFFFFFFFF, 0xFFFFFFFF), 1);
    expect(imul32(0x6D2B79F5, 3), (0x6D2B79F5 * 3) & 0xFFFFFFFF);
  });

  test('reproduces every case of the backend golden fixture', () {
    final cases =
        jsonDecode(
              File(
                'test/fixtures/angka_generator_golden.json',
              ).readAsStringSync(),
            )
            as List;
    expect(cases.length, greaterThanOrEqualTo(500));
    for (var i = 0; i < cases.length; i++) {
      final c = cases[i] as Map<String, dynamic>;
      final got = generateFrom(c['params'] as Map<String, dynamic>);
      expect(
        jsonEncode(got.map(compact).toList()),
        jsonEncode(c['questions']),
        reason: 'case $i',
      );
    }
  });

  test('properties hold over 10,000 random cases', () {
    final r = Mulberry32(99);
    const objects = ['a', 'b', 'c'];
    for (var i = 0; i < 10000; i++) {
      final lo = 1 + r.intn(20);
      final hi = lo + r.intn(21 - lo);
      final count = 5 + r.intn(16);
      final objs = objects.sublist(0, 1 + r.intn(3));
      final seed = r.next();
      final layout = r.intn(2) == 0
          ? AngkaGenerator.layoutRows
          : AngkaGenerator.layoutScatter;
      List<AngkaQuestion> gen() => AngkaGenerator.generate(
        min: lo,
        max: hi,
        count: count,
        objectIds: objs,
        layout: layout,
        seed: seed,
      );
      final qs = gen();
      final why = 'case $i ($lo–$hi, $count, $layout, $seed)';
      expect(qs, hasLength(count), reason: why);
      expect(gen(), qs, reason: 'deterministic: $why');
      final seen = <int>{};
      for (var k = 0; k < qs.length; k++) {
        final q = qs[k];
        seen.add(q.count);
        expect(q.count, inInclusiveRange(lo, hi), reason: why);
        if (k > 0 && hi > lo) {
          expect(q.count, isNot(qs[k - 1].count), reason: why);
        }
        if (k > 0 && objs.length > 1) {
          expect(q.objectId, isNot(qs[k - 1].objectId), reason: why);
        }
        expect(q.points, hasLength(q.count), reason: why);
        final min = q.size + AngkaGenerator.gap;
        for (var a = 0; a < q.points.length; a++) {
          final pa = q.points[a];
          expect(pa.x - q.size ~/ 2, greaterThanOrEqualTo(0), reason: why);
          expect(pa.y + q.size ~/ 2, lessThanOrEqualTo(180), reason: why);
          for (final pb in q.points.skip(a + 1)) {
            final dx = pa.x - pb.x, dy = pa.y - pb.y;
            expect(dx * dx + dy * dy, greaterThanOrEqualTo(min * min));
          }
        }
      }
      final span = hi - lo + 1;
      expect(seen, hasLength(span <= count ? span : count), reason: why);
    }
  });

  test('seven pictures in rows split 4 + 3', () {
    final q = AngkaGenerator.generate(
      min: 7,
      max: 7,
      count: 1,
      objectIds: const ['apel'],
      layout: AngkaGenerator.layoutRows,
      seed: 1,
    ).single;
    expect(q.points[0].y, q.points[3].y);
    expect(q.points[3].y, isNot(q.points[4].y));
  });
}
