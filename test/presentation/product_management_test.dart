import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/presentation/products/product_details_screen.dart';
import 'package:freshtrack/presentation/products/product_form_screen.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/shared/widgets/product_card.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('thumbnail decodifica alla dimensione fisica visualizzata', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProductCard(
            product: _product(imagePath: 'foto-non-presente.jpg'),
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as ResizeImage;
    expect(provider.width, 116);
    expect(provider.height, 116);
  });

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
    expect(
      (await repository.getById('latte'))?.category,
      ProductCategory.beverages,
    );
    expect(find.byKey(const Key('open-edit')), findsOneWidget);
  });

  testWidgets('dopo il salvataggio propone di attivare le notifiche', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([]);
    final scheduler = _FakeNotificationScheduler(enabled: false);
    final router = GoRouter(
      initialLocation: '/host',
      routes: [
        GoRoute(
          path: '/host',
          builder: (context, _) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('open-new'),
                onPressed: () => context.push('/products/new'),
                child: const Text('Apri nuovo'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/products/new',
          builder: (_, _) => const ProductFormScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
          expirationNotificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.byKey(const Key('open-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('product-name')), 'Yogurt');
    await tester.tap(find.byKey(const Key('save-product')));
    await tester.pumpAndSettle();

    expect(find.text('Attivare i promemoria?'), findsOneWidget);
    expect(scheduler.permissionRequests, 0);
    await tester.tap(find.byKey(const Key('confirm-enable-notifications')));
    await tester.pumpAndSettle();
    expect(scheduler.permissionRequests, 1);
    expect(repository.products.single.name, 'Yogurt');
  });

  testWidgets('un errore nelle notifiche non annulla il prodotto salvato', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([]);
    final scheduler = _FakeNotificationScheduler(failStatusCheck: true);
    final router = GoRouter(
      initialLocation: '/host',
      routes: [
        GoRoute(
          path: '/host',
          builder: (context, _) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const Key('open-new'),
                onPressed: () => context.push('/products/new'),
                child: const Text('Apri nuovo'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/products/new',
          builder: (_, _) => const ProductFormScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
          expirationNotificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.tap(find.byKey(const Key('open-new')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('product-name')), 'Pasta');
    await tester.tap(find.byKey(const Key('save-product')));
    await tester.pumpAndSettle();

    expect(repository.products.single.name, 'Pasta');
    expect(find.byKey(const Key('open-new')), findsOneWidget);
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

Widget _app(
  GoRouter router,
  ProductRepository repository, {
  ExpirationNotificationScheduler? scheduler,
}) => ProviderScope(
  overrides: [
    productRepositoryProvider.overrideWithValue(repository),
    expirationNotificationSchedulerProvider.overrideWithValue(
      scheduler ?? _FakeNotificationScheduler(),
    ),
  ],
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
  purchaseDate: CivilDate(2026, 7, 27),
  expirationDate: CivilDate(2026, 8, 2),
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

  @override
  Future<List<Product>> getAll() async => List.unmodifiable(products);
}

class _FakeNotificationScheduler implements ExpirationNotificationScheduler {
  _FakeNotificationScheduler({
    this.enabled = true,
    this.failStatusCheck = false,
  });

  bool enabled;
  final bool failStatusCheck;
  int permissionRequests = 0;

  @override
  Stream<CivilDate> get openedExpirationDates => const Stream.empty();

  @override
  Future<bool> areNotificationsEnabled() async {
    if (failStatusCheck) throw StateError('Plugin notifiche non disponibile');
    return enabled;
  }

  @override
  void dispose() {}

  @override
  Future<CivilDate?> initialize() async => null;

  @override
  Future<bool> requestNotificationPermission() async {
    permissionRequests++;
    enabled = true;
    return enabled;
  }

  @override
  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
  }) async => const NotificationSynchronizationResult();
}
