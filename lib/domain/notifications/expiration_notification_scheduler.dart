import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product.dart';

class NotificationSynchronizationResult {
  const NotificationSynchronizationResult({
    this.requested = 0,
    this.scheduled = 0,
    this.unchanged = 0,
    this.cancelled = 0,
    this.truncated = 0,
    this.failed = 0,
    this.catchUpDelivered = 0,
  });

  final int requested;
  final int scheduled;
  final int unchanged;
  final int cancelled;
  final int truncated;
  final int failed;
  final int catchUpDelivered;

  bool get isComplete => truncated == 0 && failed == 0;
}

abstract interface class ExpirationNotificationScheduler {
  Future<CivilDate?> initialize();

  Future<bool> areNotificationsEnabled();

  Future<bool> requestNotificationPermission();

  Future<bool> canScheduleExactNotifications();

  Future<bool> requestExactNotificationPermission();

  Future<void> openSystemNotificationSettings();

  Future<void> openExactAlarmSettings();

  Future<void> scheduleTestReminder({
    required Duration delay,
    required String languageCode,
  });

  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
    String languageCode = 'it',
    bool preferExactTimes = false,
  });

  Stream<CivilDate> get openedExpirationDates;

  void dispose();
}
