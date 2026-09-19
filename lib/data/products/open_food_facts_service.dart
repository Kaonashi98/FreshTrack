import 'dart:async';
import 'dart:convert';

import 'package:freshtrack/domain/products/product.dart';
import 'package:http/http.dart' as http;

final class BarcodeProductLookup {
  const BarcodeProductLookup({
    required this.barcode,
    required this.name,
    required this.category,
    this.brand,
  });

  final String barcode;
  final String name;
  final String? brand;
  final ProductCategory category;
}

enum BarcodeLookupStatus { found, notFound, unavailable }

final class BarcodeLookupResult {
  const BarcodeLookupResult._(this.status, this.product);

  const BarcodeLookupResult.found(BarcodeProductLookup product)
    : this._(BarcodeLookupStatus.found, product);
  const BarcodeLookupResult.notFound()
    : this._(BarcodeLookupStatus.notFound, null);
  const BarcodeLookupResult.unavailable()
    : this._(BarcodeLookupStatus.unavailable, null);

  final BarcodeLookupStatus status;
  final BarcodeProductLookup? product;
}

class OpenFoodFactsService {
  OpenFoodFactsService(
    this._client, {
    required String appVersion,
    this.timeout = const Duration(seconds: 8),
  }) : _userAgent =
           'FreshTrack/${_safeVersion(appVersion)} Android '
           '(freshtrack.help@outlook.com)';

  final http.Client _client;
  final String _userAgent;
  final Duration timeout;

  Future<BarcodeLookupResult> lookup(
    String rawBarcode, {
    String languageCode = 'it',
  }) async {
    final barcode = rawBarcode.replaceAll(RegExp(r'\D'), '');
    if (barcode.length < minProductBarcodeLength ||
        barcode.length > maxProductBarcodeLength) {
      return const BarcodeLookupResult.notFound();
    }
    final uri = Uri.https(
      'world.openfoodfacts.org',
      '/api/v3.6/product/$barcode',
      {
        'fields':
            'code,product_name_it,product_name_en,product_name,brands,categories_tags',
      },
    );
    try {
      final response = await _client
          .get(
            uri,
            headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
          )
          .timeout(timeout);
      if (response.statusCode == 404) {
        return const BarcodeLookupResult.notFound();
      }
      if (response.statusCode != 200) {
        return const BarcodeLookupResult.unavailable();
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> || decoded['status'] != 'success') {
        return const BarcodeLookupResult.notFound();
      }
      final product = decoded['product'];
      if (product is! Map<String, dynamic>) {
        return const BarcodeLookupResult.notFound();
      }
      final italianName = _string(product['product_name_it']);
      final englishName = _string(product['product_name_en']);
      final genericName = _string(product['product_name']);
      final name = languageCode == 'it'
          ? italianName ?? genericName ?? englishName
          : englishName ?? genericName ?? italianName;
      if (name == null) return const BarcodeLookupResult.notFound();
      final brand = _string(product['brands']);
      final rawTags = product['categories_tags'];
      final tags = (rawTags is List<dynamic> ? rawTags : const <dynamic>[])
          .whereType<String>()
          .map((value) => value.toLowerCase())
          .toList(growable: false);
      return BarcodeLookupResult.found(
        BarcodeProductLookup(
          barcode: barcode,
          name: name,
          brand: brand,
          category:
              tags.any(
                (tag) =>
                    tag.contains('beverage') ||
                    tag.contains('drink') ||
                    tag.contains('bevande'),
              )
              ? ProductCategory.beverages
              : ProductCategory.food,
        ),
      );
    } on TimeoutException {
      return const BarcodeLookupResult.unavailable();
    } on http.ClientException {
      return const BarcodeLookupResult.unavailable();
    } on FormatException {
      return const BarcodeLookupResult.unavailable();
    } on Object {
      return const BarcodeLookupResult.unavailable();
    }
  }

  String? _string(Object? value) {
    final text = value is String ? value.trim() : '';
    if (text.isEmpty) return null;
    return text.length <= maxProductNameLength
        ? text
        : text.substring(0, maxProductNameLength).trimRight();
  }

  static String _safeVersion(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^0-9A-Za-z.+_-]'), '');
    return sanitized.isEmpty ? 'unknown' : sanitized;
  }
}
