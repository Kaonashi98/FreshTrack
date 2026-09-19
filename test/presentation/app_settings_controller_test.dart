import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';

void main() {
  test(
    'una modifica anticipata attende il restore e non sovrascrive i dati',
    () async {
      final repository = _DelayedSettingsRepository();
      final container = ProviderContainer(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final mutation = container
          .read(appSettingsProvider.notifier)
          .setThemePreference(AppThemePreference.light);
      expect(repository.saveCalls, 0);

      repository.restore.complete(
        AppSettings.defaults.copyWith(
          themePreference: AppThemePreference.dark,
          notificationDaysBefore: 6,
        ),
      );
      await mutation;

      final state = await container.read(appSettingsProvider.future);
      expect(state.themePreference, AppThemePreference.light);
      expect(state.notificationDaysBefore, 6);
      expect(repository.saved?.notificationDaysBefore, 6);
    },
  );

  test('un errore di persistenza conserva il valore precedente', () async {
    final repository = _DelayedSettingsRepository()
      ..restore.complete(AppSettings.defaults)
      ..failSave = true;
    final container = ProviderContainer(
      overrides: [appSettingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    await container.read(appSettingsProvider.future);

    await expectLater(
      container
          .read(appSettingsProvider.notifier)
          .setThemePreference(AppThemePreference.dark),
      throwsStateError,
    );
    expect(
      container.read(appSettingsProvider).requireValue.themePreference,
      AppThemePreference.dark,
    );
  });
}

class _DelayedSettingsRepository implements AppSettingsRepository {
  final restore = Completer<AppSettings>();
  AppSettings? saved;
  int saveCalls = 0;
  bool failSave = false;

  @override
  Future<void> clear() async {}

  @override
  Future<AppSettings> load() async => saved ?? await restore.future;

  @override
  Future<void> save(AppSettings settings) async {
    saveCalls++;
    if (failSave) throw StateError('storage unavailable');
    saved = settings;
  }
}
