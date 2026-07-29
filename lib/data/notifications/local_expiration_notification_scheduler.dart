import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_planner.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as time_zone;

class LocalExpirationNotificationScheduler
    implements ExpirationNotificationScheduler {
  LocalExpirationNotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    this._planner = const ExpirationNotificationPlanner(),
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const _channelId = 'freshtrack_expiration_day';
  static const _channelName = 'Scadenze di oggi';
  static const _channelDescription =
      'Avvisi per i prodotti che raggiungono la data di scadenza.';

  final FlutterLocalNotificationsPlugin _plugin;
  final ExpirationNotificationPlanner _planner;
  final StreamController<DateTime> _openedDates =
      StreamController<DateTime>.broadcast();

  Future<DateTime?>? _initialization;

  @override
  Stream<DateTime> get openedExpirationDates => _openedDates.stream;

  @override
  Future<DateTime?> initialize() => _initialization ??= _initialize();

  Future<DateTime?> _initialize() async {
    time_zone_data.initializeTimeZones();
    try {
      final deviceTimeZone = await FlutterTimezone.getLocalTimezone();
      time_zone.setLocalLocation(
        time_zone.getLocation(deviceTimeZone.identifier),
      );
    } catch (_) {
      time_zone.setLocalLocation(time_zone.getLocation('Europe/Rome'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleResponse,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      return _planner.dateFromPayload(
        launchDetails?.notificationResponse?.payload,
      );
    }
    return null;
  }

  void _handleResponse(NotificationResponse response) {
    final date = _planner.dateFromPayload(response.payload);
    if (date != null && !_openedDates.isClosed) _openedDates.add(date);
  }

  @override
  Future<void> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
  }) async {
    await initialize();
    final now = time_zone.TZDateTime.now(time_zone.local);
    final plans = _planner.create(
      products,
      now: now,
      notificationHour: hour,
      notificationMinute: minute,
    );
    final validIds = plans.map((plan) => plan.id).toSet();
    final pending = await _plugin.pendingNotificationRequests();

    for (final notification in pending) {
      if ((notification.payload?.startsWith(
            ExpirationNotificationPlanner.payloadPrefix,
          ) ??
          false)) {
        if (!validIds.contains(notification.id)) {
          await _plugin.cancel(id: notification.id);
        }
      }
    }

    for (final plan in plans) {
      final scheduledDate = time_zone.TZDateTime(
        time_zone.local,
        plan.date.year,
        plan.date.month,
        plan.date.day,
        hour,
        minute,
      );
      if (!scheduledDate.isAfter(now)) continue;

      await _plugin.cancel(id: plan.id);
      await _plugin.zonedSchedule(
        id: plan.id,
        title: plan.title,
        body: plan.body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: plan.payload,
      );
    }
  }

  @override
  void dispose() {
    _openedDates.close();
  }
}
