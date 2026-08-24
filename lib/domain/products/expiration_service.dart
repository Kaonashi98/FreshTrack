import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product.dart';

enum ExpirationState { fresh, dueSoon, expiresToday, expired }

class ExpirationInfo {
  const ExpirationInfo({required this.state, required this.daysRemaining});
  final ExpirationState state;
  final int daysRemaining;
}

abstract final class ExpirationService {
  static ExpirationInfo evaluate({
    required CivilDate expirationDate,
    DateTime? now,
    int dueSoonDays = 7,
  }) {
    final today = CivilDate.fromDateTime(now ?? DateTime.now());
    final days = expirationDate.differenceInDays(today);
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
}
