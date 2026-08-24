import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as time_zone;

void main() {
  setUpAll(time_zone_data.initializeTimeZones);
  test('attraversa mese, anno e anno bisestile senza orario locale', () {
    expect(CivilDate(2026, 1, 1).subtractDays(1), CivilDate(2025, 12, 31));
    expect(CivilDate(2024, 2, 28).addDays(1), CivilDate(2024, 2, 29));
    expect(CivilDate(2024, 2, 29).addDays(1), CivilDate(2024, 3, 1));
  });

  test('calcola giorni civili anche attorno ai cambi DST', () {
    expect(CivilDate(2026, 3, 30).differenceInDays(CivilDate(2026, 3, 28)), 2);
    expect(
      CivilDate(2026, 10, 26).differenceInDays(CivilDate(2026, 10, 24)),
      2,
    );
  });

  test('parsing canonico è stretto e non accetta rollover', () {
    expect(CivilDate.tryParse('2026-08-04'), CivilDate(2026, 8, 4));
    expect(CivilDate.tryParse('2026-8-4'), isNull);
    expect(CivilDate.tryParse('2026-02-30'), isNull);
  });

  test('resta identica riaprendo in fusi verso ovest, UTC e molto a est', () {
    const stored = '2026-08-24';
    for (final zone in [
      'America/New_York',
      'Etc/UTC',
      'Europe/Rome',
      'Pacific/Kiritimati',
    ]) {
      time_zone.setLocalLocation(time_zone.getLocation(zone));
      expect(CivilDate.tryParse(stored), CivilDate(2026, 8, 24));
      final selected = time_zone.TZDateTime(time_zone.local, 2026, 8, 24);
      expect(CivilDate.fromDateTime(selected).toIso8601String(), stored);
    }
  });
}
