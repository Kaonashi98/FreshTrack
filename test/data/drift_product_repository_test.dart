import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/database/app_database.dart' hide Product;
import 'package:freshtrack/data/products/drift_product_repository.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/common/civil_date.dart';

void main() {
  late AppDatabase database;
  late DriftProductRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftProductRepository(database);
  });

  tearDown(() => database.close());

  test('salva, legge e aggiorna un prodotto', () async {
    final product = _product('latte');
    await repository.save(product);
    expect((await repository.getById(product.id))?.name, 'Latte');

    await repository.save(product.copyWith(name: 'Latte intero'));
    final products = await repository.watchAll().first;
    expect(products, hasLength(1));
    expect(products.single.name, 'Latte intero');
  });

  test('elimina un prodotto salvato', () async {
    final product = _product('yogurt');
    await repository.save(product);

    await repository.delete(product.id);

    expect(await repository.watchAll().first, isEmpty);
  });

  test(
    'codici enum sconosciuti usano fallback sicuri senza RangeError',
    () async {
      final product = _product('future');
      await repository.save(product);
      await database.customStatement(
        "UPDATE products SET category_code = 'future-category', "
        "unit_code = 'future-unit', status_code = 'future-status' "
        "WHERE id = 'future'",
      );

      final restored = await repository.getById('future');
      expect(restored?.category, ProductCategory.other);
      expect(restored?.unit, MeasurementUnit.pieces);
      expect(restored?.status, ProductStatus.available);
    },
  );
}

Product _product(String id) {
  final now = DateTime(2026, 7, 25);
  return Product(
    id: id,
    name: id[0].toUpperCase() + id.substring(1),
    category: ProductCategory.food,
    quantity: 1,
    unit: MeasurementUnit.liters,
    purchaseDate: CivilDate.fromDateTime(now),
    expirationDate: CivilDate.fromDateTime(now.add(const Duration(days: 5))),
    status: ProductStatus.available,
    notificationDaysBefore: 3,
    createdAt: now,
    updatedAt: now,
  );
}
