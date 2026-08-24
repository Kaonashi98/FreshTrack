import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/data/settings/shared_preferences_app_settings_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appVersionLabelProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'Versione ${info.version} · build ${info.buildNumber}';
});

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>(
  (_) => SharedPreferencesAppSettingsRepository(SharedPreferencesAsync()),
);

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

class AppSettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => ref.read(appSettingsRepositoryProvider).load();

  Future<void> setThemePreference(AppThemePreference value) async {
    await _persist((await future).copyWith(themePreference: value));
  }

  Future<void> setNotificationDaysBefore(int value) async {
    await _persist(
      (await future).copyWith(notificationDaysBefore: value.clamp(0, 30)),
    );
  }

  Future<void> setNotificationTime({
    required int hour,
    required int minute,
  }) async {
    final next = (await future).copyWith(
      notificationHour: hour.clamp(0, 23),
      notificationMinute: minute.clamp(0, 59),
    );
    await _persist(next);
  }

  Future<void> reset() async {
    await ref.read(appSettingsRepositoryProvider).clear();
    state = const AsyncData(AppSettings.defaults);
  }

  Future<void> _persist(AppSettings next) async {
    await ref.read(appSettingsRepositoryProvider).save(next);
    if (ref.mounted) state = AsyncData(next);
  }
}
