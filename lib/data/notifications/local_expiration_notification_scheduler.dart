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
    this._clock,
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
  static const _settingsChannel = MethodChannel('freshtrack/system_settings');
  static const _scheduleSignaturesKey =
      'notifications.expiration_schedule_signatures.v1';
  static const _catchUpDeliveredDateKey =
      'notifications.catchup_delivered_date.v1';
  static const _catchUpNotificationId = 910010;
  static const _testReminderId = 910001;

  final FlutterLocalNotificationsPlugin _plugin;
  final ExpirationNotificationPlanner _planner;
  SharedPreferencesAsync? _preferences;
  final LocalTimeZoneIdentifier _localTimeZoneIdentifier;
  final DateTime Function()? _clock;
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

  @override
  Future<bool> canScheduleExactNotifications() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.canScheduleExactNotifications() ?? false;
  }

  @override
  Future<bool> requestExactNotificationPermission() async {
    await initialize();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestExactAlarmsPermission() ?? false;
  }

  @override
  Future<void> openSystemNotificationSettings() async {
    try {
      await _settingsChannel.invokeMethod<void>('openNotificationSettings');
    } on MissingPluginException {
      // Tests and platforms without the channel ignore the request.
    }
  }

  @override
  Future<void> openExactAlarmSettings() async {
    try {
      await _settingsChannel.invokeMethod<void>('openExactAlarmSettings');
    } on MissingPluginException {
      // Tests and platforms without the channel ignore the request.
    }
  }

  void _handleResponse(NotificationResponse response) {
    unawaited(_markCatchUpDeliveredForPayload(response.payload));
    final date = _planner.dateFromPayload(response.payload);
    if (date != null && !_openedDates.isClosed) _openedDates.add(date);
  }

  @override
  Future<void> scheduleTestReminder({
    required Duration delay,
    required String languageCode,
  }) async {
    await initialize();
    await _refreshLocalTimeZone();
    final now = _currentTime();
    final scheduledDate = now.add(delay);
    final english = languageCode != 'it';
    await _zonedSchedule(
      id: _testReminderId,
      title: english
          ? 'FreshTrack test reminder'
          : 'Promemoria di prova FreshTrack',
      body: english
          ? 'Notifications are working. Open the app to review your expirations.'
          : 'Le notifiche funzionano. Apri l’app per rivedere le scadenze.',
      scheduledDate: scheduledDate,
      payload: 'expiry-test',
      preferExactTimes: true,
      languageCode: languageCode,
    );
  }

  @override
  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
    String languageCode = 'it',
    bool preferExactTimes = false,
  }) => _synchronizations.run(
    () => _synchronize(
      List.of(products),
      hour: hour,
      minute: minute,
      daysBefore: daysBefore,
      languageCode: languageCode,
      preferExactTimes: preferExactTimes,
    ),
  );

  Future<NotificationSynchronizationResult> _synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
    required String languageCode,
    required bool preferExactTimes,
  }) async {
    await initialize();
    final timeZoneIdentifier = await _refreshLocalTimeZone();
    final now = _currentTime();
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
        preferExactTimes,
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
        await _zonedSchedule(
          id: plan.id,
          title: plan.title,
          body: plan.body,
          scheduledDate: scheduledDate,
          payload: plan.payload,
          preferExactTimes: preferExactTimes,
          languageCode: languageCode,
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
    final catchUpDelivered = await _deliverCatchUpIfNeeded(
      products,
      now: now,
      hour: hour,
      minute: minute,
      daysBefore: daysBefore,
      languageCode: languageCode,
    );
    return NotificationSynchronizationResult(
      requested: allPlans.length,
      scheduled: scheduled,
      unchanged: unchanged,
      cancelled: cancelled,
      truncated: truncated,
      failed: failed,
      catchUpDelivered: catchUpDelivered,
    );
  }

  Future<int> _deliverCatchUpIfNeeded(
    List<Product> products, {
    required time_zone.TZDateTime now,
    required int hour,
    required int minute,
    required int daysBefore,
    required String languageCode,
  }) async {
    final missed = _planner.missedToday(
      products,
      now: now,
      notificationHour: hour,
      notificationMinute: minute,
      daysBefore: daysBefore,
      languageCode: languageCode,
    );
    if (missed.isEmpty) return 0;
    final today = CivilDate.fromDateTime(now).toIso8601String();
    final lastDelivered = await _schedulePreferences.getString(
      _catchUpDeliveredDateKey,
    );
    if (lastDelivered == today) return 0;
    final plan = missed.firstWhere(
      (item) => item.id > 0,
      orElse: () => missed.first,
    );
    try {
      await _plugin.show(
        id: _catchUpNotificationId,
        title: plan.title,
        body: plan.body,
        notificationDetails: _details(languageCode),
        payload: plan.payload,
      );
      await _schedulePreferences.setString(_catchUpDeliveredDateKey, today);
      return 1;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _markCatchUpDeliveredForPayload(String? payload) async {
    if (_planner.dateFromPayload(payload) == null) return;
    try {
      await _refreshLocalTimeZone();
      final today = CivilDate.fromDateTime(_currentTime()).toIso8601String();
      await _schedulePreferences.setString(_catchUpDeliveredDateKey, today);
    } catch (_) {
      // A failed preference write must not block notification navigation.
    }
  }

  Future<void> _zonedSchedule({
    required int id,
    required String title,
    required String body,
    required time_zone.TZDateTime scheduledDate,
    required String payload,
    required bool preferExactTimes,
    required String languageCode,
  }) async {
    final preferred = preferExactTimes
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _details(languageCode),
        androidScheduleMode: preferred,
        payload: payload,
      );
    } catch (_) {
      if (preferred == AndroidScheduleMode.inexactAllowWhileIdle) rethrow;
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _details(languageCode),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    }
  }

  NotificationDetails _details(String languageCode) => NotificationDetails(
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
  );

  time_zone.TZDateTime _currentTime() {
    final value = _clock?.call();
    if (value == null) return time_zone.TZDateTime.now(time_zone.local);
    return time_zone.TZDateTime(
      time_zone.local,
      value.year,
      value.month,
      value.day,
      value.hour,
      value.minute,
      value.second,
      value.millisecond,
      value.microsecond,
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
