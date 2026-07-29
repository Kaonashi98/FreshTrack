import 'package:freshtrack/domain/products/product.dart';

abstract interface class ExpirationNotificationScheduler {
  Future<DateTime?> initialize();

  Future<void> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
  });

  Stream<DateTime> get openedExpirationDates;

  void dispose();
}
