import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/presentation/settings/privacy_policy_screen.dart';

void main() {
  testWidgets('mostra le informazioni privacy essenziali', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('I tuoi dati restano sul dispositivo'), findsOneWidget);
    expect(find.text('Permessi'), findsOneWidget);
    expect(find.text('Condivisione'), findsOneWidget);
    expect(find.text('Controllo'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text(PrivacyPolicyScreen.lastUpdated),
      400,
    );
    expect(find.textContaining('organizzazione personale'), findsOneWidget);
    expect(find.textContaining('freshtrack.help@outlook.com'), findsOneWidget);
    expect(find.text(PrivacyPolicyScreen.lastUpdated), findsOneWidget);
  });
}
