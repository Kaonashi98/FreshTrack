import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/presentation/settings/settings_screen.dart';

void main() {
  testWidgets('cambia tema e salva la preferenza', (tester) async {
    final repository = _MemorySettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tema dell’app'), findsOneWidget);
    expect(find.text('Preavviso predefinito'), findsOneWidget);
    expect(AppSettings.defaults.notificationDaysBefore, 0);
    expect(find.text('Avvisa il giorno della scadenza.'), findsOneWidget);
    expect(find.text('Esporta dati'), findsNothing);
    expect(find.text('Importa dati'), findsNothing);
    expect(find.byKey(const Key('notification-time')), findsOneWidget);

    await tester.tap(find.text('Chiaro'));
    await tester.pumpAndSettle();

    expect(repository.saved.themePreference, AppThemePreference.light);

    await tester.tap(find.byKey(const Key('notification-time')));
    await tester.pumpAndSettle();
    expect(find.text('Annulla'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('app-version')),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Versione 1.0.0 · build 2'), findsOneWidget);
  });
}

class _MemorySettingsRepository implements AppSettingsRepository {
  AppSettings saved = AppSettings.defaults;

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings settings) async {
    saved = settings;
  }
}
