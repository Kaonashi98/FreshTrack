import 'package:freshtrack/domain/common/civil_date.dart';

final class ExpirationDateCandidate {
  const ExpirationDateCandidate({required this.date, required this.source});

  final CivilDate date;
  final String source;
}

/// Extracts plausible calendar dates from OCR text without choosing one for the
/// user. The UI must always ask for confirmation before changing a product.
abstract final class ExpirationDateParser {
  static List<ExpirationDateCandidate> parse(String text) {
    final candidates = <String, ExpirationDateCandidate>{};

    void add(int year, int month, int day, String source) {
      if (year < 2000 || year > 2100) return;
      try {
        final date = CivilDate(year, month, day);
        candidates.putIfAbsent(
          date.toIso8601String(),
          () => ExpirationDateCandidate(date: date, source: source.trim()),
        );
      } on ArgumentError {
        // OCR frequently creates impossible dates. They are ignored.
      }
    }

    final dayFirstPatterns = [
      RegExp(
        r'(^|[^0-9])([0-3]?\d)\s*[./-]\s*([01]?\d)\s*[./-]\s*(20\d{2}|\d{2})(?=$|[^0-9])',
        multiLine: true,
      ),
      RegExp(
        r'(^|[^0-9])([0-3]?\d)\s+([01]?\d)\s+(20\d{2}|\d{2})(?=$|[^0-9])',
        multiLine: true,
      ),
    ];
    for (final pattern in dayFirstPatterns) {
      for (final match in pattern.allMatches(text)) {
        final rawYear = int.parse(match.group(4)!);
        add(
          rawYear < 100 ? 2000 + rawYear : rawYear,
          int.parse(match.group(3)!),
          int.parse(match.group(2)!),
          match.group(0)!,
        );
      }
    }

    final yearFirstPatterns = [
      RegExp(
        r'(^|[^0-9])(20\d{2})\s*[./-]\s*([01]?\d)\s*[./-]\s*([0-3]?\d)(?=$|[^0-9])',
        multiLine: true,
      ),
      RegExp(
        r'(^|[^0-9])(20\d{2})\s+([01]?\d)\s+([0-3]?\d)(?=$|[^0-9])',
        multiLine: true,
      ),
    ];
    for (final pattern in yearFirstPatterns) {
      for (final match in pattern.allMatches(text)) {
        add(
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
          int.parse(match.group(4)!),
          match.group(0)!,
        );
      }
    }

    final normalized = text.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');
    final monthNames = RegExp(
      r'(^|[^0-9])([0-3]?\d)\s+(GEN(?:NAIO)?|JAN(?:UARY)?|FEB(?:BRAIO|RUARY)?|MAR(?:ZO|CH)?|APR(?:ILE|IL)?|MAG(?:GIO)?|MAY|GIU(?:GNO)?|JUN(?:E)?|LUG(?:LIO)?|JUL(?:Y)?|AGO(?:STO)?|AUG(?:UST)?|SET(?:TEMBRE)?|SEP(?:TEMBER)?|OTT(?:OBRE)?|OCT(?:OBER)?|NOV(?:EMBRE|EMBER)?|DIC(?:EMBRE)?|DEC(?:EMBER)?)\s+(20\d{2}|\d{2})(?=$|[^0-9])',
    );
    for (final match in monthNames.allMatches(normalized)) {
      final rawYear = int.parse(match.group(4)!);
      add(
        rawYear < 100 ? 2000 + rawYear : rawYear,
        _monthNumber(match.group(3)!),
        int.parse(match.group(2)!),
        match.group(0)!,
      );
    }

    final result = candidates.values.toList(growable: false)
      ..sort((left, right) => left.date.compareTo(right.date));
    return result;
  }

  static int _monthNumber(String value) {
    const englishPrefixes = {
      'JAN': 1,
      'FEB': 2,
      'MAR': 3,
      'APR': 4,
      'MAY': 5,
      'JUN': 6,
      'JUL': 7,
      'AUG': 8,
      'SEP': 9,
      'OCT': 10,
      'NOV': 11,
      'DEC': 12,
    };
    for (final entry in englishPrefixes.entries) {
      if (value.startsWith(entry.key)) return entry.value;
    }
    const prefixes = [
      'GEN',
      'FEB',
      'MAR',
      'APR',
      'MAG',
      'GIU',
      'LUG',
      'AGO',
      'SET',
      'OTT',
      'NOV',
      'DIC',
    ];
    return prefixes.indexWhere(value.startsWith) + 1;
  }
}
