import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('il candidato usa un versionCode nuovo', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: 1.0.0+11'));
  });

  test('la privacy pubblicabile copre entrambe le lingue e i fornitori', () {
    final policy = File('docs/privacy-site/index.html').readAsStringSync();

    expect(policy, contains('id="english"'));
    expect(policy, contains('id="italiano"'));
    expect(policy, contains('September 15, 2026'));
    expect(policy, contains('15 settembre 2026'));
    expect(policy, contains('Open Food Facts'));
    expect(policy, contains('Google ML Kit'));
    expect(policy, contains('per-installation identifiers'));
    expect(policy, contains('identificatori per installazione'));
    expect(policy, contains('not a medical device'));
    expect(policy, contains('Non è un dispositivo medico'));
  });

  test('sono pronte le schede Play italiana e inglese', () {
    final italian = File('docs/play_store_listing_it.md').readAsStringSync();
    final english = File('docs/play_store_listing_en.md').readAsStringSync();

    expect(italian, contains('build 11'));
    expect(italian, contains('italiana o inglese'));
    expect(english, contains('build 11'));
    expect(english, contains('automatic Italian/English'));
    expect(english, contains('not a medical device'));

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
        '## Note di rilascio',
      ).length,
      lessThanOrEqualTo(4000),
    );
    expect(
      _section(english, '## Full description', '## Release notes').length,
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
