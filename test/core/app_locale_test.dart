import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/core/app.dart';

void main() {
  test('usa italiano solo quando una lingua di sistema è italiana', () {
    expect(
      resolveFreshTrackLocale(const [Locale('it', 'IT')]),
      const Locale('it'),
    );
  });

  test('usa inglese per ogni sistema non italiano e per locale assente', () {
    expect(
      resolveFreshTrackLocale(const [Locale('fr', 'FR')]),
      const Locale('en'),
    );
    expect(
      resolveFreshTrackLocale(const [Locale('ja', 'JP')]),
      const Locale('en'),
    );
    expect(
      resolveFreshTrackLocale(const [Locale('de', 'DE'), Locale('it')]),
      const Locale('en'),
    );
    expect(resolveFreshTrackLocale(null), const Locale('en'));
  });
}
