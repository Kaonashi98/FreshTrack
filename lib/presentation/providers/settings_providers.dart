import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/data/settings/shared_preferences_app_settings_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>(
  (_) => SharedPreferencesAppSettingsRepository(SharedPreferencesAsync()),
);

final appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
      AppSettingsController.new,
    );

class AppSettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    unawaited(_restore());
    return AppSettings.defaults;
  }

  Future<void> setThemePreference(AppThemePreference value) async {
    state = state.copyWith(themePreference: value);
    await _persist();
  }

  Future<void> setNotificationDaysBefore(int value) async {
    state = state.copyWith(notificationDaysBefore: value.clamp(0, 30));
    await _persist();
  }

  Future<void> setNotificationTime({
    required int hour,
    required int minute,
  }) async {
    state = state.copyWith(
      notificationHour: hour.clamp(0, 23),
      notificationMinute: minute.clamp(0, 59),
    );
    await _persist();
  }

  Future<void> _restore() async {
    try {
      final restored = await ref.read(appSettingsRepositoryProvider).load();
      if (ref.mounted) state = restored;
    } catch (_) {
      // The defaults remain available if persistent storage cannot be read.
    }
  }

  Future<void> _persist() =>
      ref.read(appSettingsRepositoryProvider).save(state);
}
