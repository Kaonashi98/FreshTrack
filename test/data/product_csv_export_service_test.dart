import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/backup/product_csv_export_service.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product.dart';

void main() {
  test('esporta lo scaduto calcolato senza alterare gli stati conclusi', () {
    final expired = _product(name: 'Scaduto');
    final bytes = ProductCsvExportService.encode([
      expired,
      expired.copyWith(name: 'Consumata', status: ProductStatus.consumed),
      expired.copyWith(name: 'Buttata', status: ProductStatus.discarded),
      expired.copyWith(
        name: 'Utilizzato',
        category: ProductCategory.medicines,
        status: ProductStatus.consumed,
      ),
    ], now: DateTime(2026, 8, 31));
    final rows = utf8.decode(bytes.sublist(3)).trim().split('\r\n');

    expect(rows[1].split(';')[6], '"Scaduto"');
    expect(rows[2].split(';')[6], '"Consumato"');
    expect(rows[3].split(';')[6], '"Buttato"');
    expect(rows[4].split(';')[6], '"Utilizzato"');
  });

  test('il prodotto che scade oggi resta disponibile nel CSV', () {
    final text = utf8.decode(
      ProductCsvExportService.encode([
        _product(name: 'Oggi'),
      ], now: DateTime(2026, 8, 30, 23, 59)),
    );
    expect(text, contains('"Disponibile"'));
    expect(text, isNot(contains('"Scaduto"')));
  });

  test(
    'regressione: CSV farmaco utilizzato conserva la terminologia corretta',
    () {
      final text = utf8.decode(
        ProductCsvExportService.encode([
          _product(name: 'Farmaco').copyWith(
            category: ProductCategory.medicines,
            status: ProductStatus.consumed,
          ),
        ]),
      );
      expect(text, contains('"Utilizzato"'));
    },
  );
  test('esporta colonne complete compatibili con Excel', () {
    final bytes = ProductCsvExportService.encode([_product(name: 'Latte')]);
    final text = utf8.decode(bytes.sublist(3));

    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(text, contains('"Nome";"Categoria";"Quantità"'));
    expect(text, contains('"Latte";"Alimentari";"2";"pz"'));
    expect(text, contains('"8001234567890"'));
  });

  test('neutralizza formule e gestisce virgolette e righe', () {
    final text = utf8.decode(
      ProductCsvExportService.encode([
        _product(name: '=HYPERLINK("x")', description: 'riga 1\nriga 2'),
      ]).sublist(3),
    );

    expect(text, contains('"\'=HYPERLINK(""x"")"'));
    expect(text, contains('"riga 1\nriga 2"'));
  });

  test('esporta intestazioni e valori in inglese', () {
    final text = utf8.decode(
      ProductCsvExportService.encode([
        _product(name: 'Milk'),
      ], languageCode: 'en').sublist(3),
    );

    expect(text, contains('"Name";"Category";"Quantity"'));
    expect(text, contains('"Milk";"Food";"2";"pz"'));
  });
}

Product _product({required String name, String? description}) => Product(
  id: 'latte',
  name: name,
  description: description,
  category: ProductCategory.food,
  quantity: 2,
  unit: MeasurementUnit.pieces,
  purchaseDate: CivilDate(2026, 8, 20),
  expirationDate: CivilDate(2026, 8, 30),
  barcode: '8001234567890',
  status: ProductStatus.available,
  notificationDaysBefore: 2,
  createdAt: DateTime.utc(2026, 8, 20),
  updatedAt: DateTime.utc(2026, 8, 20),
);
