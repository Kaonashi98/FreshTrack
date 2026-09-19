import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/products/open_food_facts_service.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('preferisce il nome italiano e riconosce una bevanda', () async {
    late http.Request captured;
    final service = OpenFoodFactsService(
      MockClient((request) async {
        captured = request;
        return http.Response(
          jsonEncode({
            'status': 'success',
            'product': {
              'product_name_it': 'Succo di mela',
              'product_name': 'Apple juice',
              'brands': 'Esempio',
              'categories_tags': ['en:beverages'],
            },
          }),
          200,
        );
      }),
      appVersion: '1.0.0+3',
    );

    final result = await service.lookup('80 012345 67890');

    expect(result.status, BarcodeLookupStatus.found);
    expect(result.product?.name, 'Succo di mela');
    expect(result.product?.category, ProductCategory.beverages);
    expect(
      captured.headers['User-Agent'],
      'FreshTrack/1.0.0+3 Android (freshtrack.help@outlook.com)',
    );
    expect(captured.url.path, '/api/v3.6/product/8001234567890');
    expect(captured.url.queryParameters['fields'], contains('product_name_it'));
  });

  test('distingue prodotto assente da servizio non disponibile', () async {
    final notFound = OpenFoodFactsService(
      MockClient((_) async => http.Response('{"status":"failure"}', 404)),
      appVersion: 'test',
    );
    final unavailable = OpenFoodFactsService(
      MockClient((_) async => http.Response('errore', 503)),
      appVersion: 'test',
    );

    expect(
      (await notFound.lookup('8001234567890')).status,
      BarcodeLookupStatus.notFound,
    );
    expect(
      (await unavailable.lookup('8001234567890')).status,
      BarcodeLookupStatus.unavailable,
    );
  });

  test(
    'preferisce il nome inglese quando la lingua attiva è inglese',
    () async {
      final service = OpenFoodFactsService(
        MockClient(
          (_) async => http.Response(
            jsonEncode({
              'status': 'success',
              'product': {
                'product_name_it': 'Succo di mela',
                'product_name_en': 'Apple juice',
                'product_name': 'Jus de pomme',
                'categories_tags': ['en:beverages'],
              },
            }),
            200,
          ),
        ),
        appVersion: 'test',
      );

      final result = await service.lookup('8001234567890', languageCode: 'en');

      expect(result.product?.name, 'Apple juice');
    },
  );

  test('non chiama la rete per un codice non valido', () async {
    var calls = 0;
    final service = OpenFoodFactsService(
      MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      }),
      appVersion: 'test',
    );

    expect((await service.lookup('123')).status, BarcodeLookupStatus.notFound);
    expect(calls, 0);
  });

  test(
    'un errore inatteso del client lascia disponibile l’inserimento manuale',
    () async {
      final service = OpenFoodFactsService(
        MockClient((_) => Future.error(StateError('errore inatteso'))),
        appVersion: '1.0.0+3',
      );

      expect(
        (await service.lookup('8001234567890')).status,
        BarcodeLookupStatus.unavailable,
      );
    },
  );
}
