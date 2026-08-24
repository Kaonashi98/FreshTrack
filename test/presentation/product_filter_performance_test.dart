import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/presentation/products/products_screen.dart';

void main() {
  for (final count in [100, 500, 1000]) {
    test('ricerca filtro e ordinamento su $count prodotti', () {
      final products = List.generate(count, _product);
      final stopwatch = Stopwatch()..start();
      final filtered = filterAndSortProducts(
        products,
        query: 'caffe',
        category: ProductCategory.food,
        sort: ProductSort.name,
      );
      stopwatch.stop();
      expect(filtered, hasLength((count + 1) ~/ 2));
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
    });
  }

  test('query vuota e filtro data riflettono subito lo stato corrente', () {
    final products = List.generate(20, _product);
    final result = filterAndSortProducts(
      products,
      expirationDate: CivilDate(2026, 8, 10),
    );
    expect(result, isNotEmpty);
    expect(
      result.every((item) => item.expirationDate == CivilDate(2026, 8, 10)),
      isTrue,
    );
  });
}

Product _product(int index) => Product(
  id: '$index',
  name: index.isEven ? 'Caffè $index' : 'Tè $index',
  category: ProductCategory.food,
  quantity: 1,
  unit: MeasurementUnit.pieces,
  purchaseDate: CivilDate(2026, 8, 1),
  expirationDate: CivilDate(2026, 8, 10 + (index % 10)),
  status: ProductStatus.available,
  notificationDaysBefore: 0,
  createdAt: DateTime(2026, 8, 1).add(Duration(minutes: index)),
  updatedAt: DateTime(2026, 8, 1).add(Duration(minutes: index)),
);
