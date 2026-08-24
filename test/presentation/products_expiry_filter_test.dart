import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/presentation/products/products_screen.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';

void main() {
  testWidgets('mostra solo i prodotti disponibili della data selezionata', (
    tester,
  ) async {
    final selectedDate = DateTime(2026, 8, 4);
    final repository = _FakeRepository([
      _product('Latte', selectedDate),
      _product('Pasta', DateTime(2026, 8, 5)),
      _product(
        'Yogurt consumato',
        selectedDate,
        status: ProductStatus.consumed,
      ),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [productRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          home: Scaffold(
            body: ProductsScreen(
              expirationDate: CivilDate.fromDateTime(selectedDate),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expiry-date-filter')), findsOneWidget);
    expect(find.text('Scadenze del 04/08/2026'), findsOneWidget);
    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('Pasta'), findsNothing);
    expect(find.text('Yogurt consumato'), findsNothing);
  });
}

class _FakeRepository implements ProductRepository {
  _FakeRepository(this.products);

  final List<Product> products;

  @override
  Stream<List<Product>> watchAll() => Stream.value(products);

  @override
  Future<List<Product>> getAll() async => products;

  @override
  Future<Product?> getById(String id) async =>
      products.where((product) => product.id == id).firstOrNull;

  @override
  Future<void> save(Product product) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clear() async {}
}

Product _product(
  String name,
  DateTime expirationDate, {
  ProductStatus status = ProductStatus.available,
}) => Product(
  id: name,
  name: name,
  category: ProductCategory.food,
  quantity: 1,
  unit: MeasurementUnit.pieces,
  purchaseDate: CivilDate.fromDateTime(
    expirationDate.subtract(const Duration(days: 2)),
  ),
  expirationDate: CivilDate.fromDateTime(expirationDate),
  status: status,
  notificationDaysBefore: 3,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);
