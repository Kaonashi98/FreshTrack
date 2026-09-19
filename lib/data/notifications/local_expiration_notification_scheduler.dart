import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/common/async_mutex.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_planner.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:timezone/data/latest.dart' as time_zone_data;
import 'package:timezone/timezone.dart' as time_zone;
import 'package:shared_preferences/shared_preferences.dart';

typedef LocalTimeZoneIdentifier = Future<String> Function();

class LocalExpirationNotificationScheduler
    implements ExpirationNotificationScheduler {
  LocalExpirationNotificationScheduler({
    FlutterLocalNotificationsPlugin? plugin,
    this._planner = const ExpirationNotificationPlanner(),
    SharedPreferencesAsync? preferences,
    LocalTimeZoneIdentifier? localTimeZoneIdentifier,
    this.maximumScheduledNotifications = 450,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _preferences = _retainOptionalPreferences(preferences),
       _localTimeZoneIdentifier =
           localTimeZoneIdentifier ?? _platformTimeZoneIdentifier;

  static const _channelId = 'freshtrack_expiration_day';
  static const _channelName = 'Scadenze di oggi';
  static const _channelDescription =
      'Avvisi per i prodotti che raggiungono la data di scadenza.';
  static const _timeZoneChannel = MethodChannel('freshtrack/timezone');
  static const _scheduleSignaturesKey =
      'notifications.expiration_schedule_signatures.v1';

  final FlutterLocalNotificationsPlugin _plugin;
  final ExpirationNotificationPlanner _planner;
  SharedPreferencesAsync? _preferences;
  final LocalTimeZoneIdentifier _localTimeZoneIdentifier;
  final int maximumScheduledNotifications;
  final StreamController<CivilDate> _openedDates =
      StreamController<CivilDate>.broadcast();

  Future<CivilDate?>? _initialization;
  bool _timeZonesInitialized = false;
  final _synchronizations = AsyncMutex();

  @override
  Stream<CivilDate> get openedExpirationDates => _openedDates.stream;

  @override
  Future<CivilDate?> initialize() => _initialization ??= _initialize()
      .catchError((Object error, StackTrace stack) {
        _initialization = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<CivilDate?> _initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _handleResponse,
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      return _planner.dateFromPayload(
        launchDetails?.notificationResponse?.payload,
      );
    }
    return null;
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.areNotificationsEnabled() ?? true;
  }

  @override
  Future<bool> requestNotificationPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? true;
  }

  void _handleResponse(NotificationResponse response) {
    final date = _planner.dateFromPayload(response.payload);
    if (date != null && !_openedDates.isClosed) _openedDates.add(date);
  }

  @override
  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
    String languageCode = 'it',
  }) => _synchronizations.run(
    () => _synchronize(
      List.of(products),
      hour: hour,
      minute: minute,
      daysBefore: daysBefore,
      languageCode: languageCode,
    ),
  );

  Future<NotificationSynchronizationResult> _synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
    required String languageCode,
  }) async {
    await initialize();
    final timeZoneIdentifier = await _refreshLocalTimeZone();
    final now = time_zone.TZDateTime.now(time_zone.local);
    final allPlans = _planner.create(
      products,
      now: now,
      notificationHour: hour,
      notificationMinute: minute,
      daysBefore: daysBefore,
      languageCode: languageCode,
    );
    // Some Android vendors impose a 500-alarm limit. Keep a conservative
    // reserve for the OS and other app features, retaining the nearest plans.
    final plans = allPlans.take(maximumScheduledNotifications).toList();
    final truncated = allPlans.length - plans.length;
    final validIds = plans.map((plan) => plan.id).toSet();
    final pending = await _plugin.pendingNotificationRequests();
    final pendingById = {for (final item in pending) item.id: item};
    final previousSignatures = await _readSignatures();
    final nextSignatures = <String, String>{};
    var cancelled = 0;
    var scheduled = 0;
    var unchanged = 0;
    var failed = 0;

    for (final notification in pending) {
      if ((notification.payload?.startsWith(
            ExpirationNotificationPlanner.payloadPrefix,
          ) ??
          false)) {
        if (!validIds.contains(notification.id)) {
          await _plugin.cancel(id: notification.id);
          cancelled++;
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
      final signature = jsonEncode([
        plan.title,
        plan.body,
        plan.payload,
        scheduledDate.millisecondsSinceEpoch,
        timeZoneIdentifier,
      ]);
      final key = '${plan.id}';
      if (pendingById.containsKey(plan.id) &&
          previousSignatures[key] == signature) {
        nextSignatures[key] = signature;
        unchanged++;
        continue;
      }
      try {
        if (pendingById.containsKey(plan.id)) {
          await _plugin.cancel(id: plan.id);
          cancelled++;
        }
        await _plugin.zonedSchedule(
          id: plan.id,
          title: plan.title,
          body: plan.body,
          scheduledDate: scheduledDate,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channelId,
              languageCode == 'it' ? _channelName : 'Today’s expirations',
              channelDescription: languageCode == 'it'
                  ? _channelDescription
                  : 'Alerts for products that reach their expiration date.',
              importance: Importance.high,
              priority: Priority.high,
              category: AndroidNotificationCategory.reminder,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: plan.payload,
        );
        nextSignatures[key] = signature;
        scheduled++;
      } catch (_) {
        failed++;
      }
    }
    await _schedulePreferences.setString(
      _scheduleSignaturesKey,
      jsonEncode(nextSignatures),
    );
    return NotificationSynchronizationResult(
      requested: allPlans.length,
      scheduled: scheduled,
      unchanged: unchanged,
      cancelled: cancelled,
      truncated: truncated,
      failed: failed,
    );
  }

  Future<String> _refreshLocalTimeZone() async {
    if (!_timeZonesInitialized) {
      time_zone_data.initializeTimeZones();
      _timeZonesInitialized = true;
    }
    final identifier = await _localTimeZoneIdentifier();
    if (identifier.trim().isEmpty) {
      throw StateError('Android did not return a local time-zone identifier.');
    }
    final normalizedIdentifier = identifier.trim();
    final location =
        normalizedIdentifier == 'UTC' || normalizedIdentifier == 'GMT'
        ? time_zone.UTC
        : time_zone.getLocation(normalizedIdentifier);
    time_zone.setLocalLocation(location);
    return identifier;
  }

  Future<Map<String, String>> _readSignatures() async {
    final raw = await _schedulePreferences.getString(_scheduleSignaturesKey);
    if (raw == null) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return const {};
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return const {};
    }
  }

  SharedPreferencesAsync get _schedulePreferences =>
      _preferences ??= SharedPreferencesAsync();

  static Future<String> _platformTimeZoneIdentifier() async {
    final identifier = await _timeZoneChannel.invokeMethod<String>(
      'getLocalTimezone',
    );
    if (identifier == null) {
      throw StateError('Android returned a null local time-zone identifier.');
    }
    return identifier;
  }

  static SharedPreferencesAsync? _retainOptionalPreferences(
    SharedPreferencesAsync? preferences,
  ) => preferences;

  @override
  void dispose() {
    _openedDates.close();
  }
}
