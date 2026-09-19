import 'package:freshtrack/domain/products/product.dart';

abstract final class ProductValidation {
  static String? quantity(double? value) {
    if (value == null ||
        !value.isFinite ||
        value <= 0 ||
        value > maxProductQuantity) {
      return 'Inserisci una quantità valida maggiore di zero.';
    }
    return null;
  }

  static String? error(Product product) {
    if (product.id.isEmpty || product.id.length > 128) {
      return 'Identificativo del prodotto non valido.';
    }
    if (product.name.trim().isEmpty ||
        product.name.length > maxProductNameLength) {
      return 'Inserisci un nome valido (massimo 160 caratteri).';
    }
    if ((product.description?.length ?? 0) > maxProductDescriptionLength) {
      return 'La descrizione può contenere al massimo 1000 caratteri.';
    }
    final quantityError = quantity(product.quantity);
    if (quantityError != null) return quantityError;
    if (product.expirationDate.isBefore(product.purchaseDate)) {
      return 'La scadenza non può precedere l’acquisto.';
    }
    for (final date in [product.purchaseDate, product.expirationDate]) {
      if (date.year < 2000 || date.year > 2100) {
        return 'La data deve essere compresa tra il 2000 e il 2100.';
      }
    }
    final barcode = product.barcode;
    if (barcode != null && !RegExp(r'^\d{8,14}$').hasMatch(barcode)) {
      return 'Il barcode deve contenere da 8 a 14 cifre.';
    }
    return null;
  }

  static void requireValid(Product product) {
    final message = error(product);
    if (message != null) throw FormatException(message);
  }
}
