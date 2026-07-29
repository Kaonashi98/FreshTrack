import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAppSettingsRepository implements AppSettingsRepository {
  SharedPreferencesAppSettingsRepository(this._preferences);

  static const _themeKey = 'settings.theme';
  static const _notificationDaysKey = 'settings.notification_days';
  static const _notificationHourKey = 'settings.notification_hour';
  static const _notificationMinuteKey = 'settings.notification_minute';
  static const _defaultsVersionKey = 'settings.defaults_version';
  static const _currentDefaultsVersion = 2;

  final SharedPreferencesAsync _preferences;

  @override
  Future<AppSettings> load() async {
    final storedTheme = await _preferences.getString(_themeKey);
    final storedDays = await _preferences.getInt(_notificationDaysKey);
    final storedHour = await _preferences.getInt(_notificationHourKey);
    final storedMinute = await _preferences.getInt(_notificationMinuteKey);
    final defaultsVersion = await _preferences.getInt(_defaultsVersionKey) ?? 1;
    final notificationDays = defaultsVersion >= _currentDefaultsVersion
        ? storedDays ?? AppSettings.defaults.notificationDaysBefore
        : AppSettings.defaults.notificationDaysBefore;
    if (defaultsVersion < _currentDefaultsVersion) {
      await _preferences.setInt(_notificationDaysKey, notificationDays);
      await _preferences.setInt(_defaultsVersionKey, _currentDefaultsVersion);
    }
    return AppSettings(
      themePreference: AppThemePreference.values.firstWhere(
        (value) => value.name == storedTheme,
        orElse: () => AppSettings.defaults.themePreference,
      ),
      notificationDaysBefore: notificationDays.clamp(0, 30),
      notificationHour: (storedHour ?? AppSettings.defaults.notificationHour)
          .clamp(0, 23),
      notificationMinute:
          (storedMinute ?? AppSettings.defaults.notificationMinute).clamp(
            0,
            59,
          ),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    await _preferences.setString(_themeKey, settings.themePreference.name);
    await _preferences.setInt(
      _notificationDaysKey,
      settings.notificationDaysBefore,
    );
    await _preferences.setInt(_notificationHourKey, settings.notificationHour);
    await _preferences.setInt(
      _notificationMinuteKey,
      settings.notificationMinute,
    );
    await _preferences.setInt(_defaultsVersionKey, _currentDefaultsVersion);
  }
}
