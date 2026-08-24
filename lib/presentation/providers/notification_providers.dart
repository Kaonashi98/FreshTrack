import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/data/notifications/local_expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';

final expirationNotificationSchedulerProvider =
    Provider<ExpirationNotificationScheduler>((ref) {
      final scheduler = LocalExpirationNotificationScheduler();
      ref.onDispose(scheduler.dispose);
      return scheduler;
    });

final notificationSynchronizationProvider =
    Provider<NotificationSynchronizationService>((ref) {
      return NotificationSynchronizationService(
        ref.read(productRepositoryProvider),
        ref.read(expirationNotificationSchedulerProvider),
        () => ref.read(appSettingsProvider.future),
      );
    });

class NotificationSynchronizationService {
  NotificationSynchronizationService(
    this._repository,
    this._scheduler,
    this._loadSettings,
  );

  final ProductRepository _repository;
  final ExpirationNotificationScheduler _scheduler;
  final Future<AppSettings> Function() _loadSettings;
  Future<void> _tail = Future.value();

  Future<NotificationSynchronizationResult> synchronizeLatest() {
    late NotificationSynchronizationResult result;
    final operation = _tail.catchError((_) {}).then((_) async {
      final products = await _repository.getAll();
      final settings = await _loadSettings();
      result = await _scheduler.synchronize(
        products,
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
        daysBefore: settings.notificationDaysBefore,
      );
    });
    _tail = operation;
    return operation.then((_) => result);
  }
}
