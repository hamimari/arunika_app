import 'dart:io';

import 'package:arunika_app/core/growth/growth_engine.dart';
import 'package:arunika_app/core/growth/growth_format.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Must match `lmsSHA256` in arunika-backend/growth/growth_test.go. Both
/// repositories ship the same file; if one changes, the other must too.
const lmsSha256 =
    '8e3c98c8f1c1ca812122660c4e51467c937c541238546a2ab6d1a5660177b744';

void main() {
  final lmsFile = File(WhoGrowthStandard.assetPath);
  late WhoGrowthStandard who;

  setUpAll(() => who = WhoGrowthStandard.parse(lmsFile.readAsStringSync()));

  test('LMS file is byte-identical to the backend copy', () {
    expect(sha256.convert(lmsFile.readAsBytesSync()).toString(), lmsSha256);
  });

  test('every WHO SD line classifies to its z-score (golden fixture)', () {
    final rows = File(
      'test/fixtures/growth_golden.csv',
    ).readAsLinesSync().skip(1).where((l) => l.isNotEmpty).toList();
    expect(rows.length, greaterThan(2000));
    for (final row in rows) {
      final c = row.split(',');
      final z = who.zScore(
        c[0] == 'lhfa' ? Indicator.heightForAge : Indicator.weightForAge,
        c[1] == 'male' ? Sex.male : Sex.female,
        int.parse(c[2]),
        double.parse(c[4]),
      );
      expect(z, closeTo(double.parse(c[5]), 0.01), reason: row);
    }
  });

  test('RFC example: 3 years 2 months, normal height and weight', () {
    final r = who.classify(
      sex: Sex.male,
      birthDate: DateTime(2023, 7, 12),
      measuredOn: DateTime(2026, 9, 12),
      heightCm: 94.8,
      weightKg: 13.9,
      position: Position.standing,
    );
    expect(r.ageDays, 1158);
    expect(ageLabelLong(r.ageDays), '3 tahun 2 bulan');
    expect(ageLabelShort(r.ageDays), '3 th 2 bln');
    expect(r.hfa!.category, GrowthCategory.normal);
    expect(r.wfa!.category, GrowthCategory.normal);
    expect(r.flagged, isFalse);
  });

  test('0.7 cm adjustment at the 730/731-day boundary', () {
    expect(adjustHeight(85, Position.standing, 730), 85.7);
    expect(adjustHeight(85, Position.recumbent, 731), 84.3);
    expect(adjustHeight(85, Position.recumbent, 730), 85);
    expect(defaultPosition(730), Position.recumbent);
    expect(defaultPosition(731), Position.standing);
  });

  test('weight tail rule beyond +3 SD', () {
    final sd2 = who.sdValue(Indicator.weightForAge, Sex.male, 1096, 2)!;
    final sd3 = who.sdValue(Indicator.weightForAge, Sex.male, 1096, 3)!;
    final z = who.zScore(
      Indicator.weightForAge,
      Sex.male,
      1096,
      sd3 + 0.4 * (sd3 - sd2),
    );
    expect(z, closeTo(3.4, 0.01));
  });

  test('category boundaries', () {
    expect(categoryFor(Indicator.heightForAge, -3.01), 'severely_stunted');
    expect(categoryFor(Indicator.heightForAge, -3.0), 'stunted');
    expect(categoryFor(Indicator.heightForAge, -2.0), 'normal');
    expect(categoryFor(Indicator.heightForAge, 3.0), 'normal');
    expect(categoryFor(Indicator.heightForAge, 3.01), 'tall');
    expect(categoryFor(Indicator.weightForAge, 1.0), 'normal');
    expect(categoryFor(Indicator.weightForAge, 1.01), 'risk_overweight');
    expect(categoryFor(Indicator.weightForAge, -3.01), 'severely_underweight');
  });

  test('implausible typo is flagged; past five years is out of range', () {
    final typo = who.classify(
      sex: Sex.male,
      birthDate: DateTime(2023, 7, 12),
      measuredOn: DateTime(2026, 9, 12),
      heightCm: 9.5,
      position: Position.standing,
    );
    expect(typo.hfa!.flagged, isTrue);

    final old = who.classify(
      sex: Sex.female,
      birthDate: DateTime(2020, 1, 1),
      measuredOn: DateTime(2020, 1, 1).add(const Duration(days: 1900)),
      weightKg: 20,
      position: Position.standing,
    );
    expect(old.wfa!.z, isNull);
    expect(old.wfa!.category, GrowthCategory.outOfRange);
  });

  test('gender normalisation', () {
    expect(normalizeSex('Laki-Laki'), Sex.male);
    expect(normalizeSex(' perempuan '), Sex.female);
    expect(normalizeSex('M'), Sex.male);
    expect(normalizeSex(''), isNull);
    expect(normalizeSex(null), isNull);
  });

  test('formatting', () {
    expect(formatDecimal(94.8), '94,8');
    expect(formatSigned(2.2), '+2,2');
    expect(parseDecimal('94,8'), 94.8);
    expect(parseDecimal('13.9'), 13.9);
    expect(parseDecimal(''), isNull);
    expect(formatShortDate(DateTime(2025, 12, 12)), '12 Des 2025');
    expect(formatLongDate(DateTime(2026, 9, 12)), '12 September 2026');
  });

  test('status copy', () {
    expect(
      statusSentence(
        indicator: Indicator.heightForAge,
        category: 'normal',
        childName: 'hamiz',
      ),
      'Tinggi hamiz normal untuk usianya.',
    );
    expect(
      statusSentence(
        indicator: Indicator.heightForAge,
        category: 'stunted',
        childName: 'hamiz',
      ),
      'Pendek. Coba konsultasikan ke posyandu atau dokter anak saat kunjungan berikutnya.',
    );
    expect(
      statusSentence(
        indicator: Indicator.weightForAge,
        category: 'severely_underweight',
        childName: 'hamiz',
      ),
      'Berat badan sangat kurang. Sebaiknya segera periksakan ke dokter anak atau puskesmas.',
    );
  });
}
