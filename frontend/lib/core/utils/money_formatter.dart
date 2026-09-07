import 'package:intl/intl.dart';

/// Formats whole-Taka amounts as Bangla currency text, e.g. `৳180`.
String taka(int amount) => '\u09f3$amount';

/// Consistent date/time formatting across the app.
final _dateFmt = DateFormat('dd MMM yyyy');
final _dateTimeFmt = DateFormat('dd MMM yyyy • hh:mm a');
final _timeFmt = DateFormat('hh:mm a');

String formatDate(DateTime d) => _dateFmt.format(d);
String formatDateTime(DateTime d) => _dateTimeFmt.format(d);
String formatTime(DateTime d) => _timeFmt.format(d);

/// Safe parse — returns null rather than throwing.
DateTime? tryParseDate(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  return DateTime.tryParse(raw);
}

/// Compact amount for tables: e.g. "৳180" or "৳1,250" with grouping if desired.
/// Keep whole-taka integer formatting for now; no decimals.
///
///
String takaCompact(int amount) {
  final f = NumberFormat.decimalPattern();
  return '\u09f3${f.format(amount)}';
}
