import 'dart:convert';
import 'dart:typed_data';

import 'package:freshtrack/domain/products/expiration_service.dart';
import 'package:freshtrack/domain/products/product.dart';

abstract final class ProductCsvExportService {
  static Uint8List encode(
    List<Product> products, {
    DateTime? now,
    String languageCode = 'it',
  }) {
    final exportedAt = now ?? DateTime.now();
    final rows = <List<String>>[
      languageCode == 'it'
          ? const [
              'Nome',
              'Categoria',
              'Quantità',
              'Unità',
              'Data acquisto',
              'Data scadenza',
              'Stato',
              'Barcode',
              'Descrizione',
            ]
          : const [
              'Name',
              'Category',
              'Quantity',
              'Unit',
              'Purchase date',
              'Expiration date',
              'Status',
              'Barcode',
              'Description',
            ],
      for (final product in products)
        [
          product.name,
          product.category.localizedLabel(languageCode),
          product.quantityText,
          product.unit.localizedLabel(languageCode),
          product.purchaseDate.toIso8601String(),
          product.expirationDate.toIso8601String(),
          ExpirationService.isExpired(product, now: exportedAt)
              ? ProductStatus.expired.localizedLabel(languageCode)
              : product.localizedStatusLabel(languageCode),
          product.barcode ?? '',
          product.description ?? '',
        ],
    ];
    final content = rows.map((row) => row.map(_cell).join(';')).join('\r\n');
    return Uint8List.fromList([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode('$content\r\n'),
    ]);
  }

  static String _cell(String raw) {
    var value = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final significant = value.trimLeft();
    if (significant.isNotEmpty && '=+-@'.contains(significant[0])) {
      value = "'$value";
    }
    return '"${value.replaceAll('"', '""')}"';
  }
}
