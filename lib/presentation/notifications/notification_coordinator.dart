import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/core/router/app_router.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
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
    extends ConsumerState<NotificationCoordinator>
    with WidgetsBindingObserver {
  StreamSubscription<CivilDate>? _openedDateSubscription;
  bool _productsLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final scheduler = ref.read(expirationNotificationSchedulerProvider);
    _openedDateSubscription = scheduler.openedExpirationDates.listen(
      _openExpirationDate,
    );
    unawaited(_initialize(scheduler));
    ref.listenManual(
      productsProvider,
      (_, next) => next.whenData((products) {
        _productsLoaded = true;
        final settings = ref.read(appSettingsProvider).value;
        if (settings != null) {
          _queueSynchronization();
        }
      }),
      fireImmediately: true,
    );
    ref.listenManual(appSettingsProvider, (_, settings) {
      settings.whenData((_) {
        if (_productsLoaded) _queueSynchronization();
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    unawaited(
      ref
          .read(notificationSynchronizationProvider)
          .synchronizeLatest()
          .catchError((error, stackTrace) {
            debugPrint(
              'Riallineamento notifiche al resume non riuscito: $error',
            );
            return const NotificationSynchronizationResult(
              requested: 0,
              scheduled: 0,
              unchanged: 0,
              cancelled: 0,
              truncated: 0,
              failed: 1,
            );
          }),
    );
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

  void _queueSynchronization() {
    unawaited(
      ref
          .read(notificationSynchronizationProvider)
          .synchronizeLatest()
          .then<void>(
            (_) {},
            onError: (Object error, StackTrace stackTrace) {
              debugPrint('Sincronizzazione notifiche non riuscita: $error');
              debugPrintStack(stackTrace: stackTrace);
            },
          ),
    );
  }

  void _openExpirationDate(CivilDate date) {
    if (!mounted) return;
    ref
        .read(routerProvider)
        .go('/products?expiresOn=${date.toIso8601String()}');
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _openedDateSubscription?.cancel();
    super.dispose();
  }
}
