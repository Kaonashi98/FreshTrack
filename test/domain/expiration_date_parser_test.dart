import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/expiration_date_parser.dart';

void main() {
  test('riconosce formati numerici e mesi italiani', () {
    final result = ExpirationDateParser.parse(
      'SCAD 04/09/2026\nDa consumarsi entro 12 ottobre 26',
    );

    expect(result.map((candidate) => candidate.date), [
      CivilDate(2026, 9, 4),
      CivilDate(2026, 10, 12),
    ]);
  });

  test('riconosce il formato anno mese giorno senza duplicati', () {
    final result = ExpirationDateParser.parse('2027-01-08 e ancora 08/01/2027');

    expect(result, hasLength(1));
    expect(result.single.date, CivilDate(2027, 1, 8));
  });

  test('riconosce anche i nomi dei mesi inglesi', () {
    final result = ExpirationDateParser.parse(
      'BEST BEFORE 4 September 2026 and 12 DEC 27',
    );

    expect(result.map((candidate) => candidate.date), [
      CivilDate(2026, 9, 4),
      CivilDate(2027, 12, 12),
    ]);
  });

  test('ignora date impossibili e anni fuori intervallo', () {
    final result = ExpirationDateParser.parse(
      '31/02/2026 02/01/1999 01/01/2101',
    );

    expect(result, isEmpty);
  });
}
