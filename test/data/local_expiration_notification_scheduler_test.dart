import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/notifications/local_expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:timezone/timezone.dart' as time_zone;

void main() {
  late _MockNotificationsPlugin plugin;

  setUpAll(() {
    registerFallbackValue(const InitializationSettings());
    registerFallbackValue(const NotificationDetails());
    registerFallbackValue(time_zone.TZDateTime(time_zone.UTC, 2026));
    registerFallbackValue(AndroidScheduleMode.inexactAllowWhileIdle);
    registerFallbackValue(AndroidScheduleMode.exactAllowWhileIdle);
  });

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    plugin = _MockNotificationsPlugin();
    when(
      () => plugin.initialize(
        settings: any(named: 'settings'),
        onDidReceiveNotificationResponse: any(
          named: 'onDidReceiveNotificationResponse',
        ),
      ),
    ).thenAnswer((_) async => true);
    when(
      () => plugin.getNotificationAppLaunchDetails(),
    ).thenAnswer((_) async => null);
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((_) async {});
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => plugin.show(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
  });

  test('regressione: sync concorrenti lasciano lo stato piu recente', () async {
    final pending = <PendingNotificationRequest>[];
    final scheduledStarted = Completer<void>();
    final releaseSchedule = Completer<void>();
    when(
      () => plugin.pendingNotificationRequests(),
    ).thenAnswer((_) async => List.of(pending));
    when(() => plugin.cancel(id: any(named: 'id'))).thenAnswer((call) async {
      pending.removeWhere((entry) => entry.id == call.namedArguments[#id]);
    });
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((call) async {
      scheduledStarted.complete();
      await releaseSchedule.future;
      pending.add(
        PendingNotificationRequest(
          call.namedArguments[#id] as int,
          'Latte',
          'scade',
          call.namedArguments[#payload] as String?,
        ),
      );
    });
    final scheduler = LocalExpirationNotificationScheduler(
      plugin: plugin,
      preferences: SharedPreferencesAsync(),
      localTimeZoneIdentifier: () async => 'Europe/Rome',
    );
    addTearDown(scheduler.dispose);
    final oldSync = scheduler.synchronize(
      [_product(CivilDate(2026, 12, 20))],
      hour: 9,
      minute: 0,
      daysBefore: 0,
    );
    await scheduledStarted.future;
    final newSync = scheduler.synchronize(
      [],
      hour: 9,
      minute: 0,
      daysBefore: 0,
    );
    await Future<void>.delayed(const Duration(milliseconds: 20));
    releaseSchedule.complete();
    await Future.wait([oldSync, newSync]);
    expect(
      pending,
      isEmpty,
      reason: 'Il prodotto e stato rimosso durante il precedente allineamento',
    );
  });
  test(
    'regressione: inizializzazione notifiche recupera dopo errore temporaneo',
    () async {
      var attempts = 0;
      when(
        () => plugin.initialize(
          settings: any(named: 'settings'),
          onDidReceiveNotificationResponse: any(
            named: 'onDidReceiveNotificationResponse',
          ),
        ),
      ).thenAnswer((_) async {
        attempts++;
        if (attempts == 1) throw StateError('errore temporaneo');
        return true;
      });
      final scheduler = LocalExpirationNotificationScheduler(plugin: plugin);
      addTearDown(scheduler.dispose);
      await expectLater(scheduler.initialize(), throwsStateError);
      await expectLater(scheduler.initialize(), completes);
    },
  );
  test('non riprogramma richieste già coerenti', () async {
    var pending = <PendingNotificationRequest>[];
    var timeZoneIdentifier = 'Europe/Rome';
    when(
      () => plugin.pendingNotificationRequests(),
    ).thenAnswer((_) async => pending);
    final scheduler = LocalExpirationNotificationScheduler(
      plugin: plugin,
      preferences: SharedPreferencesAsync(),
      localTimeZoneIdentifier: () async => timeZoneIdentifier,
    );
    addTearDown(scheduler.dispose);
    final product = _product(CivilDate(2026, 12, 20));

    final first = await scheduler.synchronize(
      [product],
      hour: 9,
      minute: 0,
      daysBefore: 3,
    );
    expect(first.scheduled, 2);
    pending = const [
      PendingNotificationRequest(
        20261220,
        'expiry',
        'body',
        'expiry-date:2026-12-20',
      ),
      PendingNotificationRequest(
        -20261220,
        'advance',
        'body',
        'expiry-date:2026-12-20',
      ),
    ];

    final second = await scheduler.synchronize(
      [product],
      hour: 9,
      minute: 0,
      daysBefore: 3,
    );
    expect(second.unchanged, 2);
    verify(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        payload: any(named: 'payload'),
      ),
    ).called(2);

    timeZoneIdentifier = 'UTC';
    final afterTimeZoneChange = await scheduler.synchronize(
      [product],
      hour: 9,
      minute: 0,
      daysBefore: 3,
    );
    expect(afterTimeZoneChange.scheduled, 2);
    verify(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        payload: any(named: 'payload'),
      ),
    ).called(2);
  });

  test('fallisce chiuso se Android non fornisce il timezone', () async {
    when(
      () => plugin.pendingNotificationRequests(),
    ).thenAnswer((_) async => const []);
    final scheduler = LocalExpirationNotificationScheduler(
      plugin: plugin,
      preferences: SharedPreferencesAsync(),
      localTimeZoneIdentifier: () => Future.error(StateError('timezone')),
    );
    addTearDown(scheduler.dispose);

    await expectLater(
      scheduler.synchronize(
        [_product(CivilDate(2026, 12, 20))],
        hour: 9,
        minute: 0,
        daysBefore: 0,
      ),
      throwsStateError,
    );
    verifyNever(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        payload: any(named: 'payload'),
      ),
    );
  });

  test(
    'applica il limite conservativo e segnala i promemoria troncati',
    () async {
      when(
        () => plugin.pendingNotificationRequests(),
      ).thenAnswer((_) async => const []);
      final scheduler = LocalExpirationNotificationScheduler(
        plugin: plugin,
        preferences: SharedPreferencesAsync(),
        localTimeZoneIdentifier: () async => 'Europe/Rome',
        maximumScheduledNotifications: 1,
      );
      addTearDown(scheduler.dispose);

      final result = await scheduler.synchronize(
        [_product(CivilDate(2026, 12, 20)), _product(CivilDate(2026, 12, 21))],
        hour: 9,
        minute: 0,
        daysBefore: 3,
      );
      expect(result.requested, 4);
      expect(result.scheduled, 1);
      expect(result.truncated, 3);
      expect(result.isComplete, isFalse);
    },
  );

  test('un errore platform di scheduling è riportato senza crash', () async {
    when(
      () => plugin.pendingNotificationRequests(),
    ).thenAnswer((_) async => const []);
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        payload: any(named: 'payload'),
      ),
    ).thenThrow(StateError('OEM limit'));
    final scheduler = LocalExpirationNotificationScheduler(
      plugin: plugin,
      preferences: SharedPreferencesAsync(),
      localTimeZoneIdentifier: () async => 'Europe/Rome',
    );
    addTearDown(scheduler.dispose);
    final result = await scheduler.synchronize(
      [_product(CivilDate(2026, 12, 20))],
      hour: 9,
      minute: 0,
      daysBefore: 0,
    );
    expect(result.failed, 1);
    expect(result.isComplete, isFalse);
  });

  test('consegna i promemoria di oggi persi una sola volta', () async {
    when(
      () => plugin.pendingNotificationRequests(),
    ).thenAnswer((_) async => const []);
    final scheduler = LocalExpirationNotificationScheduler(
      plugin: plugin,
      preferences: SharedPreferencesAsync(),
      localTimeZoneIdentifier: () async => 'Europe/Rome',
      clock: () => DateTime(2026, 12, 20, 10),
    );
    addTearDown(scheduler.dispose);
    final first = await scheduler.synchronize(
      [_product(CivilDate(2026, 12, 20))],
      hour: 9,
      minute: 0,
      daysBefore: 0,
    );
    final second = await scheduler.synchronize(
      [_product(CivilDate(2026, 12, 20))],
      hour: 9,
      minute: 0,
      daysBefore: 0,
    );
    expect(first.catchUpDelivered, 1);
    expect(second.catchUpDelivered, 0);
    verify(
      () => plugin.show(
        id: any(named: 'id'),
        title: 'Latte scade oggi',
        body: any(named: 'body'),
        notificationDetails: any(named: 'notificationDetails'),
        payload: 'expiry-date:2026-12-20',
      ),
    ).called(1);
  });

  test('usa allarmi esatti quando richiesti, con ripiego', () async {
    when(
      () => plugin.pendingNotificationRequests(),
    ).thenAnswer((_) async => const []);
    when(
      () => plugin.zonedSchedule(
        id: any(named: 'id'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        scheduledDate: any(named: 'scheduledDate'),
        notificationDetails: any(named: 'notificationDetails'),
        androidScheduleMode: any(named: 'androidScheduleMode'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((invocation) async {
      final mode =
          invocation.namedArguments[#androidScheduleMode]
              as AndroidScheduleMode;
      if (mode == AndroidScheduleMode.exactAllowWhileIdle) {
        throw StateError('exact denied');
      }
    });
    final scheduler = LocalExpirationNotificationScheduler(
      plugin: plugin,
      preferences: SharedPreferencesAsync(),
      localTimeZoneIdentifier: () async => 'Europe/Rome',
      clock: () => DateTime(2026, 1, 1, 8),
    );
    addTearDown(scheduler.dispose);
    final result = await scheduler.synchronize(
      [_product(CivilDate(2026, 12, 20))],
      hour: 9,
      minute: 0,
      daysBefore: 0,
      preferExactTimes: true,
    );
    expect(result.scheduled, 1);
    expect(result.failed, 0);
  });
}

class _MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

Product _product(CivilDate expiration) => Product(
  id: expiration.toString(),
  name: 'Latte',
  category: ProductCategory.food,
  quantity: 1,
  unit: MeasurementUnit.liters,
  purchaseDate: expiration.subtractDays(2),
  expirationDate: expiration,
  status: ProductStatus.available,
  notificationDaysBefore: 3,
  createdAt: DateTime(2026, 1, 1),
  updatedAt: DateTime(2026, 1, 1),
);
