import 'dart:async';
import 'package:freshtrack/domain/common/async_mutex.dart';
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

  test(
    'le scritture SQLite attendono il ripristino e riprendono senza perdita',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      final restore = mutationLockFor(repository).run(() async {
        started.complete();
        await release.future;
        await repository.replaceAll([_product('backup')]);
      });
      await started.future;
      final adding = repository.save(_product('nuovo'));
      release.complete();
      await Future.wait([restore, adding]);
      expect(
        (await repository.getAll()).map((p) => p.id),
        containsAll(['backup', 'nuovo']),
      );
    },
  );
  test('rifiuta quantità non valide senza alterare il database', () async {
    await repository.save(_product('valido'));
    for (final value in [
      -1.0,
      0.0,
      double.nan,
      double.infinity,
      1000000001.0,
    ]) {
      await expectLater(
        repository.save(_product('errato').copyWith(quantity: value)),
        throwsFormatException,
      );
    }
    await expectLater(
      repository.replaceAll([_product('errato').copyWith(quantity: -1)]),
      throwsFormatException,
    );
    expect((await repository.getAll()).single.id, 'valido');
  });

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
