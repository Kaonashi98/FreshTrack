import 'package:freshtrack/domain/products/product.dart';

abstract interface class ProductRepository {
  Stream<List<Product>> watchAll();
  Future<List<Product>> getAll();
  Future<Product?> getById(String id);
  Future<void> save(Product product);
  Future<void> replaceAll(List<Product> products);
  Future<void> delete(String id);
  Future<void> clear();
}
