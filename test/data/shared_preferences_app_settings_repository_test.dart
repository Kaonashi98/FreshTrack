import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/settings/shared_preferences_app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'migra il vecchio preavviso a zero e conserva le modifiche manuali',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            'settings.notification_days': 3,
          });
      final repository = SharedPreferencesAppSettingsRepository(
        SharedPreferencesAsync(),
      );

      final migrated = await repository.load();
      expect(migrated.notificationDaysBefore, 0);
      expect(migrated.notificationHour, 9);
      expect(migrated.notificationMinute, 0);

      await repository.save(migrated.copyWith(notificationDaysBefore: 5));

      final restored = await repository.load();
      expect(restored.notificationDaysBefore, 5);
    },
  );
}
