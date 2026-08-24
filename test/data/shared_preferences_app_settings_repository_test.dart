import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/settings/shared_preferences_app_settings_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'preserva il vecchio preavviso e conserva le modifiche manuali',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'settings.notification_days': 3,
          });
      final repository = SharedPreferencesAppSettingsRepository(
        SharedPreferencesAsync(),
      );

      final migrated = await repository.load();
      expect(migrated.notificationDaysBefore, 3);
      expect(migrated.notificationHour, 9);
      expect(migrated.notificationMinute, 0);

      await repository.save(migrated.copyWith(notificationDaysBefore: 5));

      final restored = await repository.load();
      expect(restored.notificationDaysBefore, 5);
    },
  );

  test('clear rimuove tutte le preferenze e ripristina i default', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    final repository = SharedPreferencesAppSettingsRepository(
      SharedPreferencesAsync(),
    );
    await repository.save(
      AppSettings.defaults.copyWith(
        themePreference: AppThemePreference.light,
        notificationDaysBefore: 6,
        notificationHour: 18,
        notificationMinute: 30,
      ),
    );

    await repository.clear();

    expect(await repository.load(), _hasDefaultSettings);
  });
}

Matcher get _hasDefaultSettings => isA<AppSettings>()
    .having(
      (settings) => settings.themePreference,
      'themePreference',
      AppSettings.defaults.themePreference,
    )
    .having(
      (settings) => settings.notificationDaysBefore,
      'notificationDaysBefore',
      AppSettings.defaults.notificationDaysBefore,
    )
    .having(
      (settings) => settings.notificationHour,
      'notificationHour',
      AppSettings.defaults.notificationHour,
    )
    .having(
      (settings) => settings.notificationMinute,
      'notificationMinute',
      AppSettings.defaults.notificationMinute,
    );
