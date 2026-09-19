import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:freshtrack/domain/common/async_mutex.dart';
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
        () => ref.read(appSettingsRepositoryProvider).load(),
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
      final (products, settings) = await mutationLockFor(
        _repository,
      ).run(() async => (await _repository.getAll(), await _loadSettings()));
      result = await _scheduler.synchronize(
        products,
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
        daysBefore: settings.notificationDaysBefore,
        preferExactTimes: settings.preferExactNotificationTime,
        languageCode:
            settings.languagePreference.languageCode ??
            (PlatformDispatcher.instance.locales.isNotEmpty &&
                    PlatformDispatcher.instance.locales.first.languageCode ==
                        'it'
                ? 'it'
                : 'en'),
      );
    });
    _tail = operation;
    return operation.then((_) => result);
  }
}
