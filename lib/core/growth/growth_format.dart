import 'package:arunika_app/core/growth/growth_engine.dart';
import 'package:flutter/material.dart';

/// Parent-facing text for growth screens. Indonesian numbers use a decimal
/// comma ("94,8 cm"); dates and ages follow the Tumbuh Kembang design.

const _shortMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', //
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
];
const _longMonths = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', //
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

/// "94,8" — one decimal, comma separator.
String formatDecimal(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// "+2,2" / "−0,4".
String formatSigned(double v) =>
    '${v >= 0 ? '+' : '−'}${formatDecimal(v.abs())}';

/// Parses "94,8" or "94.8"; null when empty or not a number.
double? parseDecimal(String text) {
  final t = text.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}

/// "12 Sep 2026".
String formatShortDate(DateTime d) =>
    '${d.day} ${_shortMonths[d.month - 1]} ${d.year}';

/// "12 September 2026".
String formatLongDate(DateTime d) =>
    '${d.day} ${_longMonths[d.month - 1]} ${d.year}';

/// "3 tahun 2 bulan", "7 bulan", "2 tahun".
String ageLabelLong(int ageDays) {
  final months = ageInMonths(ageDays < 0 ? 0 : ageDays);
  final y = months ~/ 12, m = months % 12;
  if (y == 0) return '$m bulan';
  if (m == 0) return '$y tahun';
  return '$y tahun $m bulan';
}

/// "3 th 2 bln", "7 bln", "2 th".
String ageLabelShort(int ageDays) {
  final months = ageInMonths(ageDays < 0 ? 0 : ageDays);
  final y = months ~/ 12, m = months % 12;
  if (y == 0) return '$m bln';
  if (m == 0) return '$y th';
  return '$y th $m bln';
}

String sexLabel(Sex sex) => sex == Sex.male ? 'Laki-laki' : 'Perempuan';

/// How a category is shown: chip label and its colours. Status is never
/// conveyed by colour alone — the label always carries it.
class CategoryStyle {
  final String label;
  final Color foreground;
  final Color background;
  final GrowthSeverity severity;
  const CategoryStyle(
    this.label,
    this.foreground,
    this.background,
    this.severity,
  );
}

enum GrowthSeverity { normal, watch, urgent, info }

class GrowthPalette {
  static const green = Color(0xFF1F7A4D);
  static const greenSoft = Color(0xFFE2F3E9);
  static const amber = Color(0xFF8A5A00);
  static const amberSoft = Color(0xFFFFF0CC);
  static const red = Color(0xFFB3261E);
  static const redSoft = Color(0xFFFBE1DD);
  static const blue = Color(0xFF2F5FA8);
  static const blueSoft = Color(0xFFDDE8F8);

  // Chart zones (lighter than the chips so the child's line stands out).
  static const zoneBlue = Color(0xFFDCE7F5);
  static const zoneGreen = Color(0xFFDDEFE2);
  static const zoneAmber = Color(0xFFFCEBC4);
  static const zoneRed = Color(0xFFF6D9D4);
}

CategoryStyle categoryStyle(String category) => switch (category) {
  GrowthCategory.normal => const CategoryStyle(
    'Normal',
    GrowthPalette.green,
    GrowthPalette.greenSoft,
    GrowthSeverity.normal,
  ),
  GrowthCategory.stunted => const CategoryStyle(
    'Pendek',
    GrowthPalette.amber,
    GrowthPalette.amberSoft,
    GrowthSeverity.watch,
  ),
  GrowthCategory.severelyStunted => const CategoryStyle(
    'Sangat pendek',
    GrowthPalette.red,
    GrowthPalette.redSoft,
    GrowthSeverity.urgent,
  ),
  GrowthCategory.tall => const CategoryStyle(
    'Tinggi',
    GrowthPalette.blue,
    GrowthPalette.blueSoft,
    GrowthSeverity.info,
  ),
  GrowthCategory.underweight => const CategoryStyle(
    'Berat badan kurang',
    GrowthPalette.amber,
    GrowthPalette.amberSoft,
    GrowthSeverity.watch,
  ),
  GrowthCategory.severelyUnderweight => const CategoryStyle(
    'Berat badan sangat kurang',
    GrowthPalette.red,
    GrowthPalette.redSoft,
    GrowthSeverity.urgent,
  ),
  GrowthCategory.riskOverweight => const CategoryStyle(
    'Risiko berat badan lebih',
    GrowthPalette.amber,
    GrowthPalette.amberSoft,
    GrowthSeverity.watch,
  ),
  _ => const CategoryStyle(
    'Di atas 5 tahun',
    Color(0xFF6B6B6B),
    Color(0xFFEFEBE7),
    GrowthSeverity.info,
  ),
};

/// The plain-language status sentence under the chart (PRD copy).
String statusSentence({
  required Indicator indicator,
  required String category,
  required String childName,
}) {
  final style = categoryStyle(category);
  switch (style.severity) {
    case GrowthSeverity.normal:
      final what = indicator == Indicator.heightForAge ? 'Tinggi' : 'Berat';
      return '$what $childName normal untuk usianya.';
    case GrowthSeverity.watch:
      return '${style.label}. Coba konsultasikan ke posyandu atau dokter anak '
          'saat kunjungan berikutnya.';
    case GrowthSeverity.urgent:
      return '${style.label}. Sebaiknya segera periksakan ke dokter anak atau '
          'puskesmas.';
    case GrowthSeverity.info:
      if (category == GrowthCategory.tall) {
        return 'Tinggi. ${indicator == Indicator.heightForAge ? 'Tinggi' : 'Berat'} '
            '$childName di atas rentang normal untuk usianya.';
      }
      return 'Standar WHO 0–5 tahun tidak berlaku lagi untuk usia ini.';
  }
}

const growthDisclaimer =
    'Acuan: WHO Child Growth Standards & Permenkes No. 2 Tahun 2020. Grafik '
    'ini bukan diagnosis; tanyakan dokter atau posyandu bila ada kekhawatiran.';
