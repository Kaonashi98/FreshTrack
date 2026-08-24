/// A calendar date without a time, offset or time-zone meaning.
///
/// FreshTrack stores user-selected dates in this form so travelling or a DST
/// transition can never move a purchase/expiration date to another day.
final class CivilDate implements Comparable<CivilDate> {
  CivilDate(this.year, this.month, this.day) {
    final normalized = DateTime.utc(year, month, day);
    if (normalized.year != year ||
        normalized.month != month ||
        normalized.day != day) {
      throw ArgumentError.value(toIso8601String(), 'date', 'Invalid date');
    }
  }

  factory CivilDate.fromDateTime(DateTime value) =>
      CivilDate(value.year, value.month, value.day);

  static CivilDate? tryParse(String? value) {
    if (value == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      return null;
    }
    final parts = value.split('-').map(int.parse).toList(growable: false);
    try {
      return CivilDate(parts[0], parts[1], parts[2]);
    } on ArgumentError {
      return null;
    }
  }

  final int year;
  final int month;
  final int day;

  CivilDate addDays(int days) {
    final result = DateTime.utc(year, month, day).add(Duration(days: days));
    return CivilDate(result.year, result.month, result.day);
  }

  CivilDate subtractDays(int days) => addDays(-days);

  int differenceInDays(CivilDate other) => DateTime.utc(
    year,
    month,
    day,
  ).difference(DateTime.utc(other.year, other.month, other.day)).inDays;

  DateTime toLocalDateTime() => DateTime(year, month, day);

  bool isBefore(CivilDate other) => compareTo(other) < 0;
  bool isAfter(CivilDate other) => compareTo(other) > 0;

  @override
  int compareTo(CivilDate other) => (year * 10000 + month * 100 + day)
      .compareTo(other.year * 10000 + other.month * 100 + other.day);

  String toIso8601String() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  String toString() => toIso8601String();

  @override
  bool operator ==(Object other) =>
      other is CivilDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);
}
