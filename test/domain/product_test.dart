import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/common/civil_date.dart';

void main() {
  test('copyWith può rimuovere descrizione e immagine', () {
    final product = _product().copyWith(
      description: 'Da consumare freddo',
      imagePath: '/tmp/latte.jpg',
    );

    final cleared = product.copyWith(description: null, imagePath: null);

    expect(cleared.description, isNull);
    expect(cleared.imagePath, isNull);
  });

  test(
    'la versione 1 include millilitri e litri tra le unità selezionabili',
    () {
      expect(
        selectableMeasurementUnits,
        containsAll([MeasurementUnit.milliliters, MeasurementUnit.liters]),
      );
    },
  );
}

Product _product() => Product(
  id: 'latte',
  name: 'Latte',
  category: ProductCategory.beverages,
  quantity: 1,
  unit: MeasurementUnit.liters,
  purchaseDate: CivilDate(2026, 7, 27),
  expirationDate: CivilDate(2026, 8, 2),
  status: ProductStatus.available,
  notificationDaysBefore: 3,
  createdAt: DateTime(2026, 7, 27),
  updatedAt: DateTime(2026, 7, 27),
);
