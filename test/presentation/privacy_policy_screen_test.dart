import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/presentation/settings/privacy_policy_screen.dart';

void main() {
  testWidgets('mostra le informazioni privacy essenziali', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('it'),
        supportedLocales: [Locale('it'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: PrivacyPolicyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('L’inventario resta sul dispositivo'), findsOneWidget);
    expect(find.text('Permessi'), findsOneWidget);
    expect(find.text('Funzioni online opzionali'), findsOneWidget);
    expect(find.text('Foto, OCR e metriche tecniche'), findsOneWidget);
    expect(find.text('Backup e condivisione'), findsOneWidget);
    expect(find.text('Controllo'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(PrivacyPolicyScreen.lastUpdated),
      400,
    );
    expect(find.textContaining('organizzazione personale'), findsOneWidget);
    expect(find.textContaining('fotografare un prodotto'), findsOneWidget);
    expect(
      find.textContaining('identificatori per installazione'),
      findsOneWidget,
    );
    expect(find.textContaining('freshtrack.help@outlook.com'), findsOneWidget);
    expect(find.text(PrivacyPolicyScreen.lastUpdated), findsOneWidget);
  });

  testWidgets('mostra in inglese le trasmissioni e i controlli privacy', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        supportedLocales: [Locale('it'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: PrivacyPolicyScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your inventory stays on your device'), findsOneWidget);
    expect(find.text('Optional online features'), findsOneWidget);
    expect(find.textContaining('request language'), findsOneWidget);
    expect(find.textContaining('per-installation identifiers'), findsOneWidget);
    expect(find.textContaining('not a medical device'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('September 19, 2026'), 400);
    expect(find.text('September 19, 2026'), findsOneWidget);
  });
}
