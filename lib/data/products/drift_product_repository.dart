import 'package:drift/drift.dart';
import 'package:freshtrack/data/database/app_database.dart';
import 'package:freshtrack/domain/products/product.dart' as domain;
import 'package:freshtrack/domain/products/product_repository.dart';

class DriftProductRepository implements ProductRepository {
  DriftProductRepository(this._database);
  final AppDatabase _database;

  @override
  Stream<List<domain.Product>> watchAll() {
    final query = _database.select(_database.products)
      ..orderBy([(row) => OrderingTerm.asc(row.expirationDate)]);
    return query.watch().map((rows) => rows.map(_toDomain).toList());
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
    category: domain.ProductCategory.values[row.category],
    quantity: row.quantity,
    unit: domain.MeasurementUnit.values[row.unit],
    purchaseDate: row.purchaseDate,
    expirationDate: row.expirationDate,
    imagePath: row.imagePath,
    status: domain.ProductStatus.values[row.status],
    notificationDaysBefore: row.notificationDaysBefore,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  ProductsCompanion _toCompanion(domain.Product product) =>
      ProductsCompanion.insert(
        id: product.id,
        name: product.name,
        description: Value(product.description),
        category: product.category.index,
        quantity: product.quantity,
        unit: product.unit.index,
        purchaseDate: product.purchaseDate,
        expirationDate: product.expirationDate,
        imagePath: Value(product.imagePath),
        status: product.status.index,
        notificationDaysBefore: Value(product.notificationDaysBefore),
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
      );
}
