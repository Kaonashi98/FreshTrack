import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/database/app_database.dart' hide Product;
import 'package:freshtrack/data/products/drift_product_repository.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'upgrade reale v2 preserva record, date, immagini e preferenze prodotto',
    () async {
      final directory = await Directory.systemTemp.createTemp('freshtrack-v2-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File(
        '${directory.path}${Platform.pathSeparator}freshtrack.sqlite',
      );
      final legacy = sqlite.sqlite3.open(file.path);
      legacy.execute('''
      CREATE TABLE products (
        id TEXT NOT NULL PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NULL,
        category INTEGER NOT NULL,
        quantity REAL NOT NULL,
        unit INTEGER NOT NULL,
        purchase_date INTEGER NOT NULL,
        expiration_date INTEGER NOT NULL,
        image_path TEXT NULL,
        barcode TEXT NULL,
        status INTEGER NOT NULL,
        notification_days_before INTEGER NOT NULL DEFAULT 0,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
      final purchase = DateTime(2026, 3, 28);
      final expiration = DateTime(2026, 3, 30);
      final created = DateTime(2026, 3, 1, 14, 30);
      legacy.execute(
        'INSERT INTO products VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          'legacy-id',
          'Latte legacy',
          'descrizione',
          1,
          1.5,
          4,
          purchase.millisecondsSinceEpoch ~/ 1000,
          expiration.millisecondsSinceEpoch ~/ 1000,
          'C:/private/image.jpg',
          null,
          0,
          7,
          created.millisecondsSinceEpoch ~/ 1000,
          created.millisecondsSinceEpoch ~/ 1000,
        ],
      );
      for (var index = 0; index < 6; index++) {
        legacy.execute(
          'INSERT INTO products VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          [
            'enum-$index',
            'Enum $index',
            null,
            index,
            1.0,
            index,
            purchase.millisecondsSinceEpoch ~/ 1000,
            expiration.millisecondsSinceEpoch ~/ 1000,
            null,
            null,
            index % 4,
            3,
            created.millisecondsSinceEpoch ~/ 1000,
            created.millisecondsSinceEpoch ~/ 1000,
          ],
        );
      }
      legacy.execute('PRAGMA user_version = 2');
      legacy.close();

      var database = AppDatabase(NativeDatabase(file));
      var repository = DriftProductRepository(database);
      final migrated = await repository.getById('legacy-id');

      expect(migrated, isNotNull);
      expect(migrated!.name, 'Latte legacy');
      expect(migrated.description, 'descrizione');
      expect(migrated.category, ProductCategory.beverages);
      expect(migrated.unit, MeasurementUnit.liters);
      expect(migrated.purchaseDate, CivilDate(2026, 3, 28));
      expect(migrated.expirationDate, CivilDate(2026, 3, 30));
      expect(migrated.imagePath, 'C:/private/image.jpg');
      expect(migrated.notificationDaysBefore, 7);
      for (var index = 0; index < 6; index++) {
        final enumProduct = await repository.getById('enum-$index');
        expect(enumProduct?.category, ProductCategory.values[index]);
        expect(enumProduct?.unit, MeasurementUnit.values[index]);
        expect(enumProduct?.status, ProductStatus.values[index % 4]);
        expect(enumProduct?.notificationDaysBefore, 3);
      }
      await database.close();

      database = AppDatabase(NativeDatabase(file));
      repository = DriftProductRepository(database);
      final reopened = await repository.getById('legacy-id');
      expect(reopened?.purchaseDate, CivilDate(2026, 3, 28));
      expect(reopened?.expirationDate, CivilDate(2026, 3, 30));
      await database.close();
    },
  );
}
