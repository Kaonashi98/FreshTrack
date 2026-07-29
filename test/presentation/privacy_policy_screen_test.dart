import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/presentation/settings/privacy_policy_screen.dart';

void main() {
  testWidgets('mostra le informazioni privacy essenziali', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));

    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('I tuoi dati restano sul dispositivo'), findsOneWidget);
    expect(find.text('Permessi'), findsOneWidget);
    expect(find.text('Condivisione'), findsOneWidget);
    expect(find.text('Controllo'), findsOneWidget);
  });
}
