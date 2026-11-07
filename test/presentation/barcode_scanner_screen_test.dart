import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/presentation/products/barcode_scanner_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const method = MethodChannel('dev.steenbakker.mobile_scanner/scanner/method');
  const events = MethodChannel('dev.steenbakker.mobile_scanner/scanner/event');
  const orientation = MethodChannel(
    'dev.steenbakker.mobile_scanner/scanner/deviceOrientation',
  );

  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(method, (call) async {
      if (call.method == 'state') return 2;
      if (call.method == 'request') return false;
      return null;
    });
    messenger.setMockMethodCallHandler(events, (_) async => null);
    messenger.setMockMethodCallHandler(orientation, (_) async => null);
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [method, events, orientation]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('camera denied keeps manual entry usable at scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const BarcodeScannerScreen(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Camera unavailable'), findsOneWidget);
      expect(
        find.textContaining('Bring the barcode into the frame'),
        findsNothing,
      );
      expect(find.byKey(const Key('barcode-manual-entry')), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Enter code'));
      await tester.tap(find.text('Enter code'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Enter the code'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });
  }
}
