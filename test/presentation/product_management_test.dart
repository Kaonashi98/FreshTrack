import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/presentation/products/product_details_screen.dart';
import 'package:freshtrack/presentation/products/product_form_screen.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('modifica un prodotto esistente', (tester) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([_product()]);
    final router = GoRouter(
      initialLocation: '/host',
      routes: [
        GoRoute(
          path: '/host',
          builder: (context, _) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('open-edit'),
                onPressed: () => context.push('/products/latte/edit'),
                child: const Text('Apri modifica'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/products/:id/edit',
          builder: (_, state) =>
              ProductFormScreen(productId: state.pathParameters['id']),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, repository));
    await tester.tap(find.byKey(const Key('open-edit')));
    await tester.pumpAndSettle();

    expect(find.text('Modifica prodotto'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('product-name')),
      'Latte intero',
    );
    await tester.tap(find.byKey(const Key('save-product')));
    await tester.pumpAndSettle();

    expect((await repository.getById('latte'))?.name, 'Latte intero');
    expect(find.byKey(const Key('open-edit')), findsOneWidget);
  });

  testWidgets('apre la foto del prodotto a schermo intero', (tester) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([
      _product(imagePath: 'foto-non-presente.jpg'),
    ]);
    final router = GoRouter(
      initialLocation: '/products/latte',
      routes: [
        GoRoute(
          path: '/products/:id',
          builder: (_, state) =>
              ProductDetailsScreen(productId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('open-product-image')));
    await tester.pumpAndSettle();

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.byKey(const Key('close-product-image')), findsOneWidget);
  });
  testWidgets('mostra azioni essenziali e cancella il prodotto', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([_product()]);
    final router = GoRouter(
      initialLocation: '/products/latte',
      routes: [
        GoRoute(
          path: '/products',
          builder: (_, _) => const Scaffold(body: Text('Elenco prodotti')),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (_, state) =>
              ProductDetailsScreen(productId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();
    expect(find.text('Gestisci prodotto'), findsNothing);
    expect(find.text('Disponibile'), findsNothing);
    expect(find.byKey(const Key('edit-product')), findsOneWidget);
    expect(find.byKey(const Key('duplicate-product')), findsNothing);

    await tester.tap(find.byKey(const Key('delete-product')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Elimina'));
    await tester.pumpAndSettle();

    expect(await repository.getById('latte'), isNull);
    expect(find.text('Elenco prodotti'), findsOneWidget);
  });
}

Widget _app(GoRouter router, ProductRepository repository) => ProviderScope(
  overrides: [productRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp.router(routerConfig: router),
);

void _useLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Product _product({String? imagePath}) => Product(
  id: 'latte',
  name: 'Latte',
  imagePath: imagePath,
  category: ProductCategory.beverages,
  quantity: 1,
  unit: MeasurementUnit.liters,
  purchaseDate: DateTime(2026, 7, 27),
  expirationDate: DateTime(2026, 8, 2),
  status: ProductStatus.available,
  notificationDaysBefore: 3,
  createdAt: DateTime(2026, 7, 27),
  updatedAt: DateTime(2026, 7, 27),
);

class _MemoryProductRepository implements ProductRepository {
  _MemoryProductRepository(this.products);

  final List<Product> products;

  @override
  Future<void> clear() async => products.clear();

  @override
  Future<void> delete(String id) async {
    products.removeWhere((product) => product.id == id);
  }

  @override
  Future<Product?> getById(String id) async {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<void> save(Product product) async {
    products.removeWhere((existing) => existing.id == product.id);
    products.add(product);
  }

  @override
  Stream<List<Product>> watchAll() =>
      Stream.value(List<Product>.unmodifiable(products));
}
