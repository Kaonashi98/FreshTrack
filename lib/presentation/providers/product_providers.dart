import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/data/database/app_database.dart' hide Product;
import 'package:freshtrack/data/media/product_image_storage.dart';
import 'package:freshtrack/data/products/drift_product_repository.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.open();
  ref.onDispose(database.close);
  return database;
});

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => DriftProductRepository(ref.watch(databaseProvider)),
);

final productImageStorageProvider = Provider<ProductImageStorage>(
  (ref) => ProductImageStorage(),
);

final productsProvider = StreamProvider<List<Product>>(
  (ref) => ref.watch(productRepositoryProvider).watchAll(),
);
final productByIdProvider = FutureProvider.family<Product?, String>((ref, id) {
  ref.watch(productsProvider);
  return ref.watch(productRepositoryProvider).getById(id);
});
