import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la versione sorgente è 1.0.1+14', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: 1.0.1+14'));
  });

  test('la privacy pubblicabile copre entrambe le lingue e i fornitori', () {
    final policy = File('docs/privacy-site/index.html').readAsStringSync();

    expect(policy, contains('id="english"'));
    expect(policy, contains('id="italiano"'));
    expect(policy, contains('October 20, 2026'));
    expect(policy, contains('20 ottobre 2026'));
    expect(policy, contains('Open Food Facts'));
    expect(policy, contains('Open Beauty Facts'));
    expect(policy, contains('Open Pet Food Facts'));
    expect(policy, contains('Open Products Facts'));
    expect(policy, contains('Google ML Kit'));
    expect(policy, contains('per-installation identifiers'));
    expect(policy, contains('identificatori per installazione'));
    expect(policy, contains('auto zoom'));
    expect(policy, contains('zoom automatico'));
    expect(policy, contains('bounding-box coordinates'));
    expect(policy, contains('coordinate previste'));
    expect(policy, isNot(contains('not a medical device')));
    expect(policy, isNot(contains('Non è un dispositivo medico')));
  });

  test('le bozze delle schede Play rispettano i limiti dei testi', () {
    final italian = File('docs/play_store_listing_it.md').readAsStringSync();
    final english = File('docs/play_store_listing_en.md').readAsStringSync();

    expect(italian, contains('prossimo bundle'));
    expect(italian, contains('italiana o inglese'));
    expect(english, contains('next bundle'));
    expect(english, contains('automatic Italian/English'));
    expect(english, isNot(contains('medicines')));

    expect(
      _section(italian, '## Nome', '## Descrizione breve').length,
      lessThanOrEqualTo(30),
    );
    expect(
      _section(english, '## App name', '## Short description').length,
      lessThanOrEqualTo(30),
    );
    expect(
      _section(
        italian,
        '## Descrizione breve',
        '## Descrizione completa',
      ).length,
      lessThanOrEqualTo(80),
    );
    expect(
      _section(english, '## Short description', '## Full description').length,
      lessThanOrEqualTo(80),
    );
    expect(
      _section(
        italian,
        '## Descrizione completa',
        '## Bozza note di rilascio',
      ).length,
      lessThanOrEqualTo(4000),
    );
    expect(
      _section(english, '## Full description', '## Draft release notes').length,
      lessThanOrEqualTo(4000),
    );
  });
}

String _section(String document, String startHeading, String endHeading) {
  final start = document.indexOf(startHeading);
  final end = document.indexOf(endHeading, start + startHeading.length);
  if (start < 0 || end < 0) return '';
  return document.substring(start + startHeading.length, end).trim();
}
