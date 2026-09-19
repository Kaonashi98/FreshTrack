import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/products/product.dart';

class FakeExpirationNotificationScheduler
    implements ExpirationNotificationScheduler {
  @override
  Stream<CivilDate> get openedExpirationDates => const Stream.empty();

  @override
  Future<CivilDate?> initialize() async => null;

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<bool> canScheduleExactNotifications() async => false;

  @override
  Future<bool> requestExactNotificationPermission() async => false;

  @override
  Future<void> openSystemNotificationSettings() async {}

  @override
  Future<void> openExactAlarmSettings() async {}

  @override
  Future<void> scheduleTestReminder({
    required Duration delay,
    required String languageCode,
  }) async {}

  @override
  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
    String languageCode = 'it',
    bool preferExactTimes = false,
  }) async => const NotificationSynchronizationResult();

  @override
  void dispose() {}
}
