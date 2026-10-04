import 'package:intl/intl.dart';

/// "Rp 39.000" — Indonesian thousands separators.
String formatIdr(int amount) {
  final digits = amount.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return 'Rp $digits';
}

/// "31 Okt" — short promo end date, e.g. "Promo s/d 31 Okt".
String formatShortDate(DateTime date) =>
    DateFormat('d MMM', 'id_ID').format(date.toLocal());

/// "31 Okt 2026" — subscription start/end dates.
String formatLongDate(DateTime date) =>
    DateFormat('d MMM yyyy', 'id_ID').format(date.toLocal());

/// Parses an optional ISO-8601 timestamp from JSON.
DateTime? parseOptionalDate(Object? value) =>
    value is String ? DateTime.tryParse(value) : null;
