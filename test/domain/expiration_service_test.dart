import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/products/expiration_service.dart';
import 'package:freshtrack/domain/common/civil_date.dart';

void main() {
  final today = DateTime(2026, 7, 25, 18, 30);

  test('ignora l’orario nel calcolo della scadenza odierna', () {
    final result = ExpirationService.evaluate(
      expirationDate: CivilDate(2026, 7, 25),
      now: today,
    );
    expect(result.state, ExpirationState.expiresToday);
    expect(result.daysRemaining, 0);
  });

  test('classifica una data passata come scaduta', () {
    final result = ExpirationService.evaluate(
      expirationDate: CivilDate(2026, 7, 24),
      now: today,
    );
    expect(result.state, ExpirationState.expired);
    expect(result.daysRemaining, -1);
  });

  test('rispetta la soglia personalizzata di prossima scadenza', () {
    expect(
      ExpirationService.evaluate(
        expirationDate: CivilDate(2026, 7, 30),
        now: today,
        dueSoonDays: 5,
      ).state,
      ExpirationState.dueSoon,
    );
    expect(
      ExpirationService.evaluate(
        expirationDate: CivilDate(2026, 7, 31),
        now: today,
        dueSoonDays: 5,
      ).state,
      ExpirationState.fresh,
    );
  });
}
