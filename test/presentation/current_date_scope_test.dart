import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/shared/widgets/current_date_scope.dart';

void main() {
  testWidgets('aggiorna il giorno a mezzanotte senza riaprire la schermata', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 6, 23, 59, 59);
    await tester.pumpWidget(
      MaterialApp(
        home: DayBoundary(
          clock: () => now,
          child: Builder(
            builder: (context) => Text('${CurrentDateScope.now(context).day}'),
          ),
        ),
      ),
    );
    expect(find.text('6'), findsOneWidget);
    now = DateTime(2026, 9, 7);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('7'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('aggiorna il giorno al ritorno da una sospensione lunga', (
    tester,
  ) async {
    var now = DateTime(2026, 9, 6, 12);
    await tester.pumpWidget(
      MaterialApp(
        home: DayBoundary(
          clock: () => now,
          child: Builder(
            builder: (context) => Text('${CurrentDateScope.now(context).day}'),
          ),
        ),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2026, 9, 8, 10);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.text('8'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
