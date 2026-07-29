import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/data/notifications/local_expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';

final expirationNotificationSchedulerProvider =
    Provider<ExpirationNotificationScheduler>((ref) {
      final scheduler = LocalExpirationNotificationScheduler();
      ref.onDispose(scheduler.dispose);
      return scheduler;
    });
