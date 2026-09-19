import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/domain/common/async_mutex.dart';
import 'package:freshtrack/data/settings/shared_preferences_app_settings_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

final packageInfoProvider = FutureProvider<PackageInfo>(
  (_) => PackageInfo.fromPlatform(),
);

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await ref.watch(packageInfoProvider.future);
  return '${info.version}+${info.buildNumber}';
});

final appVersionLabelProvider = FutureProvider<String>((ref) async {
  final info = await ref.watch(packageInfoProvider.future);
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
    await _update((current) => current.copyWith(themePreference: value));
  }

  Future<void> setLanguagePreference(AppLanguagePreference value) async {
    await _update((current) => current.copyWith(languagePreference: value));
  }

  Future<void> setNotificationDaysBefore(int value) async {
    await _update(
      (current) => current.copyWith(notificationDaysBefore: value.clamp(0, 30)),
    );
  }

  Future<void> adjustNotificationDaysBefore(int delta) => _update(
    (current) => current.copyWith(
      notificationDaysBefore: (current.notificationDaysBefore + delta).clamp(
        0,
        30,
      ),
    ),
  );

  Future<void> setNotificationTime({
    required int hour,
    required int minute,
  }) async {
    await _update(
      (current) => current.copyWith(
        notificationHour: hour.clamp(0, 23),
        notificationMinute: minute.clamp(0, 59),
      ),
    );
  }

  Future<void> setPreferExactNotificationTime(bool value) async {
    await _update(
      (current) => current.copyWith(preferExactNotificationTime: value),
    );
  }

  Future<void> reset() async {
    final repository = ref.read(appSettingsRepositoryProvider);
    await mutationLockFor(repository).run(() async {
      await repository.clear();
      if (ref.mounted) state = const AsyncData(AppSettings.defaults);
    });
  }

  Future<void> _update(AppSettings Function(AppSettings) transform) async {
    final repository = ref.read(appSettingsRepositoryProvider);
    await future;
    await mutationLockFor(repository).run(() async {
      final next = transform(await repository.load());
      await repository.save(next);
      if (ref.mounted) state = AsyncData(next);
    });
  }
}
