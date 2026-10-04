import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;

/// WHO Child Growth Standards (2006, 0–5 years) LMS engine, with the
/// Permenkes No. 2/2020 categories.
///
/// A port of the backend's `growth` package: both load a byte-identical
/// `who2006_lms.csv` and pass the same golden fixture, so the live preview in
/// the form always matches what the server stores. The app never shows a
/// z-score to parents, only the category.

enum Sex { male, female }

enum Position { standing, recumbent }

enum Indicator { heightForAge, weightForAge }

/// Category ids as the API returns them.
class GrowthCategory {
  static const severelyStunted = 'severely_stunted';
  static const stunted = 'stunted';
  static const normal = 'normal';
  static const tall = 'tall';
  static const severelyUnderweight = 'severely_underweight';
  static const underweight = 'underweight';
  static const riskOverweight = 'risk_overweight';
  static const outOfRange = 'out_of_range';
}

/// Last day covered by the 0–5 year standard.
const int maxAgeDays = 1856;

/// Below this age the reference is length (lying), from it height (standing).
const int lengthHeightCutoffDays = 731;

class _Lms {
  final double l, m, s;
  const _Lms(this.l, this.m, this.s);
}

class IndicatorResult {
  /// Null past [maxAgeDays].
  final double? z;
  final String category;
  final bool flagged;
  const IndicatorResult({this.z, required this.category, this.flagged = false});
}

class GrowthResult {
  final int ageDays;
  final double? adjustedHeightCm;
  final IndicatorResult? hfa;
  final IndicatorResult? wfa;
  const GrowthResult({
    required this.ageDays,
    this.adjustedHeightCm,
    this.hfa,
    this.wfa,
  });

  bool get flagged => (hfa?.flagged ?? false) || (wfa?.flagged ?? false);
}

class WhoGrowthStandard {
  static const assetPath = 'assets/growth/who2006_lms.csv';
  static WhoGrowthStandard? _cached;

  final Map<(Indicator, Sex), List<_Lms>> _tables;
  WhoGrowthStandard._(this._tables);

  /// Loads the bundled table once.
  static Future<WhoGrowthStandard> load() async => _cached ??=
      WhoGrowthStandard.parse(await rootBundle.loadString(assetPath));

  /// The already-loaded table, or null before [load] completes.
  static WhoGrowthStandard? get cached => _cached;

  factory WhoGrowthStandard.parse(String csv) {
    final tables = <(Indicator, Sex), List<_Lms>>{};
    final lines = csv.split('\n');
    for (final line in lines.skip(1)) {
      if (line.trim().isEmpty) continue;
      final c = line.split(',');
      final key = (
        c[0] == 'lhfa' ? Indicator.heightForAge : Indicator.weightForAge,
        c[1] == 'male' ? Sex.male : Sex.female,
      );
      final list = tables.putIfAbsent(key, () => []);
      if (int.parse(c[2]) != list.length) {
        throw FormatException('LMS rows out of order at $line');
      }
      list.add(
        _Lms(double.parse(c[3]), double.parse(c[4]), double.parse(c[5])),
      );
    }
    return WhoGrowthStandard._(tables);
  }

  /// z-score of [x], rounded to 2 decimals, or null outside 0..[maxAgeDays].
  /// Weight beyond ±3 uses WHO's restricted LMS tail rule.
  double? zScore(Indicator ind, Sex sex, int ageDays, double x) {
    final p = _at(ind, sex, ageDays);
    if (p == null) return null;
    var z = (math.pow(x / p.m, p.l) - 1) / (p.l * p.s);
    if (ind == Indicator.weightForAge && (z > 3 || z < -3)) {
      double sd(double k) => p.m * math.pow(1 + p.l * p.s * k, 1 / p.l);
      z = z > 3
          ? 3 + (x - sd(3)) / (sd(3) - sd(2))
          : -3 + (x - sd(-3)) / (sd(-2) - sd(-3));
    }
    return roundTo(z, 2);
  }

  /// The measurement at z-score [k] (a WHO SD line), for the chart zones.
  /// Weight beyond ±3 is extended linearly, as WHO's tables do.
  double? sdValue(Indicator ind, Sex sex, int ageDays, double k) {
    final p = _at(ind, sex, ageDays);
    if (p == null) return null;
    double sd(double k) =>
        (p.m * math.pow(1 + p.l * p.s * k, 1 / p.l)).toDouble();
    if (ind == Indicator.weightForAge && k > 3) {
      return sd(3) + (k - 3) * (sd(3) - sd(2));
    }
    if (ind == Indicator.weightForAge && k < -3) {
      return sd(-3) + (k + 3) * (sd(-2) - sd(-3));
    }
    return sd(k);
  }

  _Lms? _at(Indicator ind, Sex sex, int ageDays) {
    final t = _tables[(ind, sex)];
    if (t == null || ageDays < 0 || ageDays >= t.length) return null;
    return t[ageDays];
  }

  /// Age, z-scores and categories for one measurement. Throws
  /// [ArgumentError] when measured before birth.
  GrowthResult classify({
    required Sex sex,
    required DateTime birthDate,
    required DateTime measuredOn,
    double? heightCm,
    double? weightKg,
    required Position position,
  }) {
    final age = ageInDays(birthDate, measuredOn);
    if (age < 0) throw ArgumentError('measured before birth');
    double? adjusted;
    IndicatorResult? hfa, wfa;
    if (heightCm != null) {
      adjusted = adjustHeight(heightCm, position, age);
      hfa = _indicator(Indicator.heightForAge, sex, age, adjusted);
    }
    if (weightKg != null) {
      wfa = _indicator(Indicator.weightForAge, sex, age, weightKg);
    }
    return GrowthResult(
      ageDays: age,
      adjustedHeightCm: adjusted,
      hfa: hfa,
      wfa: wfa,
    );
  }

  IndicatorResult _indicator(Indicator ind, Sex sex, int age, double x) {
    final z = zScore(ind, sex, age, x);
    if (z == null) {
      return const IndicatorResult(category: GrowthCategory.outOfRange);
    }
    return IndicatorResult(
      z: z,
      category: categoryFor(ind, z),
      flagged: implausible(ind, z),
    );
  }
}

/// Maps the stored child gender ("Laki-Laki" / "Perempuan", or English) to a
/// [Sex]; null means the profile is incomplete.
Sex? normalizeSex(String? gender) {
  switch (gender?.trim().toLowerCase()) {
    case 'laki-laki' || 'laki laki' || 'male' || 'l' || 'm':
      return Sex.male;
    case 'perempuan' || 'female' || 'p' || 'f':
      return Sex.female;
  }
  return null;
}

/// Whole days between two calendar dates, ignoring time of day.
int ageInDays(DateTime birth, DateTime on) => DateTime.utc(
  on.year,
  on.month,
  on.day,
).difference(DateTime.utc(birth.year, birth.month, birth.day)).inDays;

/// Completed months, as WHO counts them.
int ageInMonths(int ageDays) => (ageDays / 30.4375).floor();

/// +0.7 cm for a standing child under 731 days, −0.7 cm for a lying child
/// from 731 days.
double adjustHeight(double heightCm, Position position, int ageDays) {
  if (ageDays < lengthHeightCutoffDays && position == Position.standing) {
    return roundTo(heightCm + 0.7, 1);
  }
  if (ageDays >= lengthHeightCutoffDays && position == Position.recumbent) {
    return roundTo(heightCm - 0.7, 1);
  }
  return heightCm;
}

/// The reference position for an age: lying under 2 years, standing after.
Position defaultPosition(int ageDays) =>
    ageDays < lengthHeightCutoffDays ? Position.recumbent : Position.standing;

String categoryFor(Indicator ind, double z) {
  final height = ind == Indicator.heightForAge;
  if (z < -3) {
    return height
        ? GrowthCategory.severelyStunted
        : GrowthCategory.severelyUnderweight;
  }
  if (z < -2) {
    return height ? GrowthCategory.stunted : GrowthCategory.underweight;
  }
  if (height && z > 3) return GrowthCategory.tall;
  if (!height && z > 1) return GrowthCategory.riskOverweight;
  return GrowthCategory.normal;
}

/// Outside WHO's flag limits.
bool implausible(Indicator ind, double z) =>
    ind == Indicator.heightForAge ? (z < -6 || z > 6) : (z < -6 || z > 5);

double roundTo(double v, int places) {
  final p = math.pow(10, places);
  return (v * p).round() / p;
}
