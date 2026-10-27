import 'package:intl/intl.dart';

import '../../l10n/l10n.dart';

/// Date and time wording in the app's language (`LocaleController`): month
/// and weekday names from intl's date symbols, and the design's own short
/// forms ("SEG", "Seg", the one-letter column heads) from the translations.
abstract final class KDates {
  static String get _loc => l10n.localeName;

  /// January first; lowercase where the language writes them so ("outubro").
  static List<String> get months => [for (var m = 1; m <= 12; m++) DateFormat.MMMM(_loc).format(DateTime(2024, m))];

  /// Monday-first, matching [DateTime.weekday] - 1 ("segunda-feira", "Monday").
  static List<String> get weekdays => [for (var d = 1; d <= 7; d++) DateFormat.EEEE(_loc).format(DateTime(2024, 1, d))];

  /// "Segunda" / "Monday": a weekday on its own, as a title.
  static List<String> get weekdaysShort => l10n.datesWeekdaysTitle.split(',');

  /// "SEG" / "MON".
  static List<String> get abbr => l10n.datesWeekdaysAbbr.split(',');

  /// "seg" / "mon".
  static List<String> get abbrLower => abbr.map((a) => a.toLowerCase()).toList();

  /// "Seg" / "Mon".
  static List<String> get abbrTitle => abbr.map((a) => a[0] + a.substring(1).toLowerCase()).toList();

  /// "S", "T", "Q"… / "M", "T", "W"…
  static List<String> get letters => l10n.datesWeekdayLetters.split(',');

  static String cap(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String two(int n) => n.toString().padLeft(2, '0');

  static String hm(DateTime d) => '${two(d.hour)}:${two(d.minute)}';

  static String minutes(int m) => '${two(m ~/ 60)}:${two(m % 60)}';

  static int toMinutes(String hhmm) {
    final p = hhmm.split(':');
    return (int.tryParse(p.first) ?? 0) * 60 + (p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0);
  }

  /// "17 out" / "17 Oct"
  static String short(DateTime d) => '${d.day} ${DateFormat.MMM(_loc).format(d).replaceAll('.', '')}';

  /// "Sábado, 17 de outubro"
  static String long(DateTime d) => cap(longLower(d));

  /// "sábado, 17 de outubro"
  static String longLower(DateTime d) => DateFormat.MMMMEEEEd(_loc).format(d);

  static String monthYear(DateTime d) => '${cap(months[d.month - 1])} ${d.year}';

  static String key(DateTime d) => '${d.year}-${two(d.month)}-${two(d.day)}';

  static DateTime? parseKey(String k) {
    final p = k.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static int isoWeek(DateTime d) {
    final date = DateTime.utc(d.year, d.month, d.day);
    final thursday = date.add(Duration(days: 4 - date.weekday));
    final firstDay = DateTime.utc(thursday.year, 1, 1);
    return 1 + thursday.difference(firstDay).inDays ~/ 7;
  }
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);

DateTime mondayOf(DateTime d) => addDays(dateOnly(d), -(d.weekday - 1));

bool sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// Rounded rather than truncated: across a DST change a calendar day is 23
/// or 25 hours long.
int daysBetween(DateTime a, DateTime b) => (dateOnly(b).difference(dateOnly(a)).inHours / 24).round();

/// The language's decimal separator ("20,8" / "20.8").
String fmtDec(double v, {int decimals = 1}) => v.toStringAsFixed(decimals).replaceAll('.', NumberFormat.decimalPattern(l10n.localeName).symbols.DECIMAL_SEP);

/// "20,8°" / "20.8°"
String fmtDeg(double? v) => v == null ? '--' : '${fmtDec(v)}°';
