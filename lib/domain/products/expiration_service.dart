import 'package:freshtrack/domain/products/product.dart';

enum ExpirationState { fresh, dueSoon, expiresToday, expired }

class ExpirationInfo {
  const ExpirationInfo({required this.state, required this.daysRemaining});
  final ExpirationState state;
  final int daysRemaining;
}

abstract final class ExpirationService {
  static ExpirationInfo evaluate({
    required DateTime expirationDate,
    DateTime? now,
    int dueSoonDays = 7,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final expiration = _dateOnly(expirationDate);
    final days = expiration.difference(today).inDays;
    if (days < 0) {
      return ExpirationInfo(
        state: ExpirationState.expired,
        daysRemaining: days,
      );
    }
    if (days == 0) {
      return const ExpirationInfo(
        state: ExpirationState.expiresToday,
        daysRemaining: 0,
      );
    }
    if (days <= dueSoonDays) {
      return ExpirationInfo(
        state: ExpirationState.dueSoon,
        daysRemaining: days,
      );
    }
    return ExpirationInfo(state: ExpirationState.fresh, daysRemaining: days);
  }

  static bool isExpired(Product product, {DateTime? now}) =>
      product.status == ProductStatus.expired ||
      (product.status == ProductStatus.available &&
          evaluate(expirationDate: product.expirationDate, now: now).state ==
              ExpirationState.expired);

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);
}
