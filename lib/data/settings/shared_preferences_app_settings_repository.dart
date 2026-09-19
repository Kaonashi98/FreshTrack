import 'dart:convert';

import 'package:freshtrack/domain/common/async_mutex.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAppSettingsRepository implements AppSettingsRepository {
  SharedPreferencesAppSettingsRepository(this._preferences);

  static const _snapshotKey = 'settings.snapshot.v1';
  static const _legacyKeys = [
    'settings.theme',
    'settings.language',
    'settings.notification_days',
    'settings.notification_hour',
    'settings.notification_minute',
    'settings.defaults_version',
  ];
  final SharedPreferencesAsync _preferences;

  @override
  Future<AppSettings> load() => mutationLockFor(this).run(() async {
    final snapshot = await _preferences.getString(_snapshotKey);
    if (snapshot != null) {
      final data = jsonDecode(snapshot) as Map<String, dynamic>;
      return _decode(data);
    }
    return _decode({
      'theme': await _preferences.getString(_legacyKeys[0]),
      'language': await _preferences.getString(_legacyKeys[1]),
      'days': await _preferences.getInt(_legacyKeys[2]),
      'hour': await _preferences.getInt(_legacyKeys[3]),
      'minute': await _preferences.getInt(_legacyKeys[4]),
    });
  });

  AppSettings _decode(Map<String, dynamic> data) => AppSettings(
    themePreference: AppThemePreference.values.firstWhere(
      (value) => value.name == data['theme'],
      orElse: () => AppSettings.defaults.themePreference,
    ),
    languagePreference: AppLanguagePreference.values.firstWhere(
      (value) => value.name == data['language'],
      orElse: () => AppSettings.defaults.languagePreference,
    ),
    notificationDaysBefore:
        ((data['days'] as int?) ?? AppSettings.defaults.notificationDaysBefore)
            .clamp(0, 30),
    notificationHour:
        ((data['hour'] as int?) ?? AppSettings.defaults.notificationHour).clamp(
          0,
          23,
        ),
    notificationMinute:
        ((data['minute'] as int?) ?? AppSettings.defaults.notificationMinute)
            .clamp(0, 59),
    preferExactNotificationTime: data['exact'] == true,
  );

  @override
  Future<void> save(
    AppSettings settings,
  ) => mutationLockFor(this).run(() async {
    // One platform write commits the entire snapshot; values cannot interleave.
    await _preferences.setString(
      _snapshotKey,
      jsonEncode({
        'theme': settings.themePreference.name,
        'language': settings.languagePreference.name,
        'days': settings.notificationDaysBefore,
        'hour': settings.notificationHour,
        'minute': settings.notificationMinute,
        'exact': settings.preferExactNotificationTime,
      }),
    );
  });

  @override
  Future<void> clear() => mutationLockFor(this).run(() async {
    // Keep the current snapshot authoritative until legacy cleanup succeeds.
    for (final key in _legacyKeys) {
      await _preferences.remove(key);
    }
    await _preferences.remove(_snapshotKey);
  });
}
