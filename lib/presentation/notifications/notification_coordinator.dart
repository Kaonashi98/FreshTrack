import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/core/router/app_router.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';

class NotificationCoordinator extends ConsumerStatefulWidget {
  const NotificationCoordinator({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationCoordinator> createState() =>
      _NotificationCoordinatorState();
}

class _NotificationCoordinatorState
    extends ConsumerState<NotificationCoordinator> {
  StreamSubscription<DateTime>? _openedDateSubscription;
  Future<void> _synchronization = Future.value();
  List<Product> _latestProducts = const [];

  @override
  void initState() {
    super.initState();
    final scheduler = ref.read(expirationNotificationSchedulerProvider);
    _openedDateSubscription = scheduler.openedExpirationDates.listen(
      _openExpirationDate,
    );
    unawaited(_initialize(scheduler));
    ref.listenManual(
      productsProvider,
      (_, next) => next.whenData((products) {
        _latestProducts = products;
        _queueSynchronization(
          scheduler,
          products,
          ref.read(appSettingsProvider),
        );
      }),
      fireImmediately: true,
    );
    ref.listenManual(appSettingsProvider, (_, settings) {
      _queueSynchronization(scheduler, _latestProducts, settings);
    });
  }

  Future<void> _initialize(ExpirationNotificationScheduler scheduler) async {
    try {
      final initialDate = await scheduler.initialize();
      if (initialDate != null && mounted) _openExpirationDate(initialDate);
    } catch (error, stackTrace) {
      debugPrint('Inizializzazione notifiche non riuscita: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _queueSynchronization(
    ExpirationNotificationScheduler scheduler,
    List<Product> products,
    AppSettings settings,
  ) {
    _synchronization = _synchronization.then(
      (_) => _synchronize(scheduler, products, settings),
    );
  }

  Future<void> _synchronize(
    ExpirationNotificationScheduler scheduler,
    List<Product> products,
    AppSettings settings,
  ) async {
    try {
      await scheduler.synchronize(
        products,
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      );
    } catch (error, stackTrace) {
      debugPrint('Sincronizzazione notifiche non riuscita: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  void _openExpirationDate(DateTime date) {
    if (!mounted) return;
    ref.read(routerProvider).go('/products?expiresOn=${_isoDate(date)}');
  }

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    _openedDateSubscription?.cancel();
    super.dispose();
  }
}
