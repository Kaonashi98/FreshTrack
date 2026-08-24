import 'package:drift/drift.dart';
import 'package:freshtrack/data/database/app_database.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product.dart' as domain;
import 'package:freshtrack/domain/products/product_repository.dart';

class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._database);
  final AppDatabase _database;

  @override
  Stream<List<domain.Product>> watchAll() {
    final query = _database.select(_database.products)
      ..orderBy([(row) => OrderingTerm.asc(row.expirationDateCivil)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
  }

  @override
  Future<List<domain.Product>> getAll() async {
    final query = _database.select(_database.products)
      ..orderBy([(row) => OrderingTerm.asc(row.expirationDateCivil)]);
    return (await query.get()).map(_toDomain).toList(growable: false);
  }

  @override
  Future<domain.Product?> getById(String id) async {
    final query = _database.select(_database.products)
      ..where((row) => row.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(domain.Product product) => _database
      .into(_database.products)
      .insertOnConflictUpdate(_toCompanion(product));

  @override
  Future<void> delete(String id) => (_database.delete(
    _database.products,
  )..where((row) => row.id.equals(id))).go();

  @override
  Future<void> clear() => _database.delete(_database.products).go();

  domain.Product _toDomain(Product row) => domain.Product(
    id: row.id,
    name: row.name,
    description: row.description,
    category: _categoryFromCode(row.categoryCode),
    quantity: row.quantity,
    unit: _unitFromCode(row.unitCode),
    purchaseDate: _dateFromCanonical(row.purchaseDateCivil, row.purchaseDate),
    expirationDate: _dateFromCanonical(
      row.expirationDateCivil,
      row.expirationDate,
    ),
    imagePath: row.imagePath,
    status: _statusFromCode(row.statusCode),
    notificationDaysBefore: row.notificationDaysBefore,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  ProductsCompanion _toCompanion(domain.Product product) =>
      ProductsCompanion.insert(
        id: product.id,
        name: product.name,
        description: Value(product.description),
        category: _legacyCategoryCode(product.category),
        categoryCode: Value(product.category.name),
        quantity: product.quantity,
        unit: _legacyUnitCode(product.unit),
        unitCode: Value(product.unit.name),
        // Compatibility mirrors for the pre-v3 NOT NULL columns. Domain reads
        // and ordering use only the canonical civil-date columns.
        purchaseDate: product.purchaseDate.toLocalDateTime(),
        expirationDate: product.expirationDate.toLocalDateTime(),
        purchaseDateCivil: Value(product.purchaseDate.toIso8601String()),
        expirationDateCivil: Value(product.expirationDate.toIso8601String()),
        imagePath: Value(product.imagePath),
        status: _legacyStatusCode(product.status),
        statusCode: Value(product.status.name),
        notificationDaysBefore: Value(product.notificationDaysBefore),
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );

  CivilDate _dateFromCanonical(String value, DateTime legacy) =>
      CivilDate.tryParse(value) ?? CivilDate.fromDateTime(legacy);

  domain.ProductCategory _categoryFromCode(String value) =>
      domain.ProductCategory.values.firstWhere(
        (item) => item.name == value,
        orElse: () => domain.ProductCategory.other,
      );

  domain.MeasurementUnit _unitFromCode(String value) =>
      domain.MeasurementUnit.values.firstWhere(
        (item) => item.name == value,
        orElse: () => domain.MeasurementUnit.pieces,
      );

  domain.ProductStatus _statusFromCode(String value) =>
      domain.ProductStatus.values.firstWhere(
        (item) => item.name == value,
        orElse: () => domain.ProductStatus.available,
      );

  int _legacyCategoryCode(domain.ProductCategory value) => switch (value) {
    domain.ProductCategory.food => 0,
    domain.ProductCategory.beverages => 1,
    domain.ProductCategory.medicines => 2,
    domain.ProductCategory.personalCare => 3,
    domain.ProductCategory.cleaning => 4,
    domain.ProductCategory.other => 5,
  };

  int _legacyUnitCode(domain.MeasurementUnit value) => switch (value) {
    domain.MeasurementUnit.pieces => 0,
    domain.MeasurementUnit.grams => 1,
    domain.MeasurementUnit.kilograms => 2,
    domain.MeasurementUnit.milliliters => 3,
    domain.MeasurementUnit.liters => 4,
    domain.MeasurementUnit.packs => 5,
  };

  int _legacyStatusCode(domain.ProductStatus value) => switch (value) {
    domain.ProductStatus.available => 0,
    domain.ProductStatus.consumed => 1,
    domain.ProductStatus.expired => 2,
    domain.ProductStatus.discarded => 3,
  };
}
