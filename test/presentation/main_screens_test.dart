import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/core/app.dart';
import 'package:freshtrack/core/router/app_router.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:freshtrack/presentation/dashboard/dashboard_screen.dart';
import 'package:freshtrack/presentation/products/product_details_screen.dart';
import 'package:freshtrack/presentation/products/product_form_screen.dart';
import 'package:freshtrack/presentation/products/products_screen.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('dashboard mostra indicatori e prodotto in scadenza', (
    tester,
  ) async {
    final repository = FakeProductRepository([_product('Latte')]);
    await tester.pumpWidget(
      _testApp(const Scaffold(body: DashboardScreen()), repository),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('dashboard-logo')), findsNothing);
    expect(find.text('Totali'), findsOneWidget);
    expect(find.text('Consumati'), findsNothing);
    expect(find.text('Meno sprechi, più valore a ciò che hai.'), findsNothing);
    expect(find.text('Priorità'), findsOneWidget);
    expect(find.byKey(const Key('dashboard-summary')), findsOneWidget);
    expect(find.text('Latte'), findsOneWidget);
  });

  testWidgets(
    'dashboard ordina e mostra solo tre scadenze entro sette giorni',
    (tester) async {
      final repository = FakeProductRepository([
        _product('Fuori finestra', daysUntilExpiration: 8),
        _product('Quarto', daysUntilExpiration: 7),
        _product('Terzo', daysUntilExpiration: 5),
        _product('Secondo', daysUntilExpiration: 3),
        _product('Primo', daysUntilExpiration: 1),
        _product('Scaduto', daysUntilExpiration: -1),
      ]);
      await tester.pumpWidget(
        _testApp(const Scaffold(body: DashboardScreen()), repository),
      );
      await tester.pumpAndSettle();

      expect(find.text('Primo'), findsOneWidget);
      expect(find.text('Secondo'), findsOneWidget);
      expect(find.text('Terzo'), findsOneWidget);
      expect(find.text('Quarto'), findsNothing);
      expect(find.text('Fuori finestra'), findsNothing);
      expect(find.text('Scaduto'), findsNothing);
      expect(find.byKey(const Key('show-all-priorities')), findsOneWidget);
      expect(find.text('Mostra tutti'), findsOneWidget);
      expect(
        find.text('C’è un altro prodotto in scadenza nei prossimi 7 giorni.'),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('Primo')).dy,
        lessThan(tester.getTopLeft(find.text('Secondo')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Secondo')).dy,
        lessThan(tester.getTopLeft(find.text('Terzo')).dy),
      );
      expect(
        tester.getTopLeft(find.byKey(const Key('show-all-priorities'))).dy,
        greaterThan(tester.getBottomLeft(find.text('Terzo')).dy),
      );
    },
  );

  testWidgets('Totali apre la pagina con tutti i prodotti', (tester) async {
    final repository = FakeProductRepository([_product('Latte')]);
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: DashboardScreen()),
        ),
        GoRoute(
          path: '/products',
          builder: (_, _) => const Scaffold(body: ProductsScreen()),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [productRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard-stat-total')));
    await tester.pumpAndSettle();

    expect(find.text('I tuoi prodotti'), findsOneWidget);
  });

  testWidgets(
    'In scadenza apre il pannello ordinato senza azioni distruttive',
    (tester) async {
      final repository = FakeProductRepository([
        _product('Dopodomani', daysUntilExpiration: 2),
        _product('Domani', daysUntilExpiration: 1),
      ]);
      await tester.pumpWidget(
        _testApp(const Scaffold(body: DashboardScreen()), repository),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('dashboard-stat-due-soon')));
      await tester.pumpAndSettle();

      expect(find.text('Prodotti in scadenza'), findsOneWidget);
      expect(find.byKey(const Key('sheet-product-Domani')), findsOneWidget);
      expect(find.byKey(const Key('sheet-product-Dopodomani')), findsOneWidget);
      expect(find.byKey(const Key('delete-all-expired')), findsNothing);
      expect(
        tester.getTopLeft(find.byKey(const Key('sheet-product-Domani'))).dy,
        lessThan(
          tester
              .getTopLeft(find.byKey(const Key('sheet-product-Dopodomani')))
              .dy,
        ),
      );
    },
  );

  testWidgets('Scaduti consente di eliminare un singolo prodotto', (
    tester,
  ) async {
    final repository = FakeProductRepository([
      _product('Yogurt vecchio', daysUntilExpiration: -1),
    ]);
    await tester.pumpWidget(
      _testApp(const Scaffold(body: DashboardScreen()), repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard-stat-expired')));
    await tester.pumpAndSettle();
    expect(find.text('Prodotti scaduti'), findsOneWidget);
    expect(
      find.byKey(const Key('delete-expired-Yogurt vecchio')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('delete-expired-Yogurt vecchio')));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare Yogurt vecchio?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-dashboard-delete')));
    await tester.pumpAndSettle();

    expect(repository.products, isEmpty);
    expect(find.text('Nessun prodotto scaduto'), findsOneWidget);
  });

  testWidgets('Scaduti consente di eliminare tutti dopo conferma', (
    tester,
  ) async {
    final repository = FakeProductRepository([
      _product('Primo scaduto', daysUntilExpiration: -2),
      _product('Secondo scaduto', daysUntilExpiration: -1),
    ]);
    await tester.pumpWidget(
      _testApp(const Scaffold(body: DashboardScreen()), repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('dashboard-stat-expired')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-all-expired')));
    await tester.pumpAndSettle();
    expect(find.text('Eliminare tutti i prodotti scaduti?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-dashboard-delete')));
    await tester.pumpAndSettle();

    expect(repository.products, isEmpty);
    expect(find.text('Nessun prodotto scaduto'), findsOneWidget);
  });
  testWidgets('la scadenza di oggi è sempre evidenziata in rosso', (
    tester,
  ) async {
    final repository = FakeProductRepository([
      _product('Yogurt', daysUntilExpiration: 0),
    ]);
    await tester.pumpWidget(
      _testApp(const Scaffold(body: ProductsScreen()), repository),
    );
    await tester.pumpAndSettle();

    final label = tester.widget<Text>(find.textContaining('Scade oggi'));
    expect(label.style?.color, AppTheme.danger);
  });
  testWidgets('lista ricerca i prodotti per nome', (tester) async {
    final repository = FakeProductRepository([
      _product('Latte'),
      _product('Pasta'),
    ]);
    await tester.pumpWidget(
      _testApp(const Scaffold(body: ProductsScreen()), repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('Pasta'), findsOneWidget);
    expect(find.text('Stato'), findsNothing);
    await tester.tap(find.text('Categoria'));
    await tester.pumpAndSettle();
    expect(find.text('Cura personale'), findsNothing);
    expect(find.text('Pulizia'), findsNothing);
    expect(find.text('Altro'), findsNothing);
    await tester.tap(find.text('Tutte le categorie'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('products-back')), findsNothing);

    await tester.enterText(find.byType(SearchBar), 'pasta');
    await tester.pump();
    expect(find.text('Latte'), findsNothing);
    expect(find.text('Pasta'), findsOneWidget);
    expect(find.byKey(const Key('clear-product-search')), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear-product-search')));
    await tester.pump();
    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('Pasta'), findsOneWidget);
  });

  testWidgets('la ricerca non va in overflow quando appare la tastiera', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 700);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    final repository = FakeProductRepository([
      _product('Latte'),
      _product('Pasta'),
    ]);
    await tester.pumpWidget(
      _testApp(const Scaffold(body: ProductsScreen()), repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SearchBar));
    await tester.enterText(find.byType(SearchBar), 'latte');
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Latte'), findsOneWidget);
  });

  testWidgets('inventario vuoto permette di aggiungere subito un prodotto', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeProductRepository([]);
    final router = GoRouter(
      initialLocation: '/products',
      routes: [
        GoRoute(
          path: '/products',
          builder: (_, _) => const Scaffold(body: ProductsScreen()),
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
        overrides: [productRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('empty-products-add')), findsOneWidget);
    await tester.tap(find.byKey(const Key('empty-products-add')));
    await tester.pumpAndSettle();

    expect(find.text('Nuovo prodotto'), findsOneWidget);
    expect(find.byKey(const Key('product-name')), findsOneWidget);
  });

  testWidgets(
    'dashboard vuota mostra il FAB, prodotti vuoti mostrano solo la CTA interna',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeProductRepository([]);
      await tester.pumpWidget(_freshTrackTestApp(repository));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add-product')), findsOneWidget);
      expect(find.byTooltip('Aggiungi prodotto'), findsOneWidget);
      await tester.tap(find.text('Prodotti'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('add-product')), findsNothing);
      expect(find.byKey(const Key('empty-products-add')), findsOneWidget);
      final panelCenter = tester.getCenter(
        find.byKey(const Key('empty-products-panel')),
      );
      final availableCenter =
          (tester.getBottomLeft(find.text('0 prodotti')).dy +
              tester.getTopLeft(find.byType(NavigationBar)).dy) /
          2;
      expect(panelCenter.dy, moreOrLessEquals(availableCenter, epsilon: 32));
    },
  );

  testWidgets('FAB apre il form e indietro torna alla dashboard vuota', (
    tester,
  ) async {
    final repository = FakeProductRepository([]);
    addTearDown(repository.dispose);
    await tester.pumpWidget(_freshTrackTestApp(repository));
    await tester.pumpAndSettle();

    final fab = find.byKey(const Key('add-product'));
    expect(fab, findsOneWidget);
    expect(tester.getSize(fab).height, greaterThanOrEqualTo(48));
    expect(find.byTooltip('Aggiungi prodotto'), findsOneWidget);
    expect(find.bySemanticsLabel('Aggiungi'), findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    expect(find.text('Nuovo prodotto'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-summary')), findsOneWidget);
    expect(fab, findsOneWidget);
  });

  testWidgets('il FAB segue Dashboard, Prodotti e Impostazioni', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeProductRepository([_product('Latte')]);
    await tester.pumpWidget(_freshTrackTestApp(repository));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('add-product')), findsOneWidget);
    await tester.tap(find.text('Prodotti'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-product')), findsOneWidget);
    await tester.tap(find.text('Impostazioni'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-product')), findsNothing);
  });

  testWidgets('ricerca senza risultati non mostra la CTA interna', (
    tester,
  ) async {
    final repository = FakeProductRepository([_product('Latte')]);
    await tester.pumpWidget(
      _testApp(const Scaffold(body: ProductsScreen()), repository),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(SearchBar), 'pasta');
    await tester.pump();

    expect(find.text('Nessun risultato'), findsOneWidget);
    expect(find.byKey(const Key('empty-products-add')), findsNothing);
  });

  testWidgets('categoria senza risultati non mostra la CTA interna', (
    tester,
  ) async {
    final repository = FakeProductRepository([_product('Latte')]);
    await tester.pumpWidget(
      _testApp(const Scaffold(body: ProductsScreen()), repository),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Categoria'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Farmaci'));
    await tester.pumpAndSettle();

    expect(find.text('Nessun risultato'), findsOneWidget);
    expect(find.byKey(const Key('empty-products-add')), findsNothing);
  });

  testWidgets('expirationDate senza risultati non mostra la CTA interna', (
    tester,
  ) async {
    final repository = FakeProductRepository([_product('Latte')]);
    final dateWithoutProducts = CivilDate.fromDateTime(
      DateTime.now(),
    ).addDays(30);
    await tester.pumpWidget(
      _testApp(
        Scaffold(body: ProductsScreen(expirationDate: dateWithoutProducts)),
        repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nessun risultato'), findsOneWidget);
    expect(
      find.text('Prova a cambiare la ricerca o a rimuovere i filtri.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('empty-products-add')), findsNothing);
  });

  testWidgets(
    'salvare il primo prodotto sostituisce la CTA interna con il FAB',
    (tester) async {
      tester.view.physicalSize = const Size(430, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = FakeProductRepository([]);
      addTearDown(repository.dispose);
      await tester.pumpWidget(_freshTrackTestApp(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Prodotti'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('empty-products-add')), findsOneWidget);
      expect(find.byKey(const Key('add-product')), findsNothing);
      await tester.tap(find.byKey(const Key('empty-products-add')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('product-name')), 'Latte');
      await tester.ensureVisible(find.byKey(const Key('save-product')));
      await tester.tap(find.byKey(const Key('save-product')));
      await tester.pumpAndSettle();

      expect(find.text('Latte'), findsOneWidget);
      expect(find.byKey(const Key('empty-products-add')), findsNothing);
      expect(find.byKey(const Key('add-product')), findsOneWidget);
    },
  );

  testWidgets('loading ed error non mostrano il FAB', (tester) async {
    for (final stream in <Stream<List<Product>>>[
      const Stream.empty(),
      Stream.error(StateError('database non disponibile')),
    ]) {
      final repository = _StreamProductRepository(stream);
      await tester.pumpWidget(_freshTrackTestApp(repository));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const Key('add-product')), findsNothing);
      expect(find.byKey(const Key('empty-products-add')), findsNothing);
    }
  });

  testWidgets('doppi tap rapidi su FAB e CTA non sovrappongono due form', (
    tester,
  ) async {
    final repository = FakeProductRepository([]);
    addTearDown(repository.dispose);
    await tester.pumpWidget(_freshTrackTestApp(repository));
    await tester.pumpAndSettle();

    final fab = find.byKey(const Key('add-product'));
    await tester.tap(fab);
    await tester.tap(fab, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Nuovo prodotto'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dashboard-summary')), findsOneWidget);

    await tester.tap(find.text('Prodotti'));
    await tester.pumpAndSettle();
    final cta = find.byKey(const Key('empty-products-add'));
    await tester.tap(cta);
    await tester.tap(cta, warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Nuovo prodotto'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('empty-products-add')), findsOneWidget);
  });

  testWidgets('tap sulla freccia apre il dettaglio prodotto', (tester) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeProductRepository([_product('Latte')]);
    final router = GoRouter(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, _) => const Scaffold(body: DashboardScreen()),
        ),
        GoRoute(
          path: '/products/:id',
          builder: (_, state) =>
              ProductDetailsScreen(productId: state.pathParameters['id']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
          routerProvider.overrideWithValue(router),
        ],
        child: const FreshTrackApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Latte'));
    await tester.pumpAndSettle();

    expect(find.text('Dettaglio prodotto'), findsOneWidget);
    expect(find.text('Latte'), findsOneWidget);
    expect(find.text('Informazioni'), findsOneWidget);
  });

  testWidgets('anteprima foto mostra sempre l’immagine completa', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = FakeProductRepository([
      _product('Latte', imagePath: 'immagine-di-test.jpg'),
    ]);
    await tester.pumpWidget(
      _testApp(const ProductFormScreen(productId: 'Latte'), repository),
    );
    await tester.pumpAndSettle();

    final preview = tester.widget<Image>(
      find.byKey(const Key('product-image-preview')),
    );
    expect(preview.fit, BoxFit.contain);
  });
  testWidgets('form segnala il nome obbligatorio', (tester) async {
    tester.view.physicalSize = const Size(800, 2800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = FakeProductRepository([]);
    await tester.pumpWidget(_testApp(const ProductFormScreen(), repository));
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(find.byKey(const Key('product-name'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('empty-photo-picker'))).dy,
      ),
    );
    expect(
      tester.getSize(find.byKey(const Key('empty-photo-picker'))).height,
      lessThan(140),
    );
    expect(find.text('Scatta foto'), findsOneWidget);
    expect(find.text('Galleria'), findsOneWidget);
    expect(find.text('Stato'), findsNothing);
    await tester.tap(find.text('Alimentari').first);
    await tester.pumpAndSettle();
    expect(find.text('Cura personale'), findsNothing);
    expect(find.text('Pulizia'), findsNothing);
    expect(find.text('Altro'), findsNothing);
    expect(find.text('Bevande'), findsNothing);
    expect(find.text('Farmaci'), findsOneWidget);
    await tester.tap(find.text('Farmaci'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('medicine-disclaimer')), findsOneWidget);

    await tester.tap(find.text('pz').first);
    await tester.pumpAndSettle();
    expect(find.text('ml'), findsOneWidget);
    expect(find.text('l'), findsOneWidget);
    expect(find.text('g'), findsOneWidget);
    expect(find.text('kg'), findsOneWidget);
    expect(find.text('confezioni'), findsOneWidget);
    await tester.tap(find.text('pz').last);
    await tester.pumpAndSettle();

    expect(find.text('Barcode'), findsNothing);
    await tester.tap(find.byKey(const Key('save-product')));
    await tester.pump();
    expect(find.text('Inserisci il nome'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('product-name')),
      List.filled(200, 'x').join(),
    );
    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('product-name')),
    );
    expect(nameField.controller?.text.length, 160);

    await tester.enterText(find.byKey(const Key('product-quantity')), 'NaN');
    await tester.tap(find.byKey(const Key('save-product')));
    await tester.pump();
    expect(find.text('Valore non valido'), findsOneWidget);
  });
}

Widget _testApp(Widget home, ProductRepository repository) => ProviderScope(
  overrides: [productRepositoryProvider.overrideWithValue(repository)],
  child: MaterialApp(home: home),
);

Widget _freshTrackTestApp(ProductRepository repository) => ProviderScope(
  overrides: [
    productRepositoryProvider.overrideWithValue(repository),
    expirationNotificationSchedulerProvider.overrideWithValue(
      _FakeNotificationScheduler(),
    ),
    appSettingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
  ],
  child: const FreshTrackApp(),
);

Product _product(
  String name, {
  int daysUntilExpiration = 2,
  String? imagePath,
}) {
  final now = DateTime.now();
  return Product(
    id: name,
    name: name,
    category: ProductCategory.food,
    quantity: 1,
    unit: MeasurementUnit.pieces,
    purchaseDate: CivilDate.fromDateTime(now),
    expirationDate: CivilDate.fromDateTime(
      now.add(Duration(days: daysUntilExpiration)),
    ),
    status: ProductStatus.available,
    imagePath: imagePath,
    notificationDaysBefore: 3,
    createdAt: now,
    updatedAt: now,
  );
}

class FakeProductRepository implements ProductRepository {
  FakeProductRepository(this.products);
  final List<Product> products;
  final _changes = StreamController<List<Product>>.broadcast();

  @override
  Stream<List<Product>> watchAll() async* {
    yield List.unmodifiable(products);
    yield* _changes.stream;
  }

  @override
  Future<List<Product>> getAll() async => List.unmodifiable(products);

  @override
  Future<Product?> getById(String id) async =>
      products.where((p) => p.id == id).firstOrNull;

  @override
  Future<void> save(Product product) async {
    products.removeWhere((p) => p.id == product.id);
    products.add(product);
    _changes.add(List.unmodifiable(products));
  }

  @override
  Future<void> delete(String id) async {
    products.removeWhere((p) => p.id == id);
    _changes.add(List.unmodifiable(products));
  }

  @override
  Future<void> clear() async {
    products.clear();
    _changes.add(const []);
  }

  Future<void> dispose() => _changes.close();
}

class _StreamProductRepository implements ProductRepository {
  const _StreamProductRepository(this.stream);

  final Stream<List<Product>> stream;

  @override
  Stream<List<Product>> watchAll() => stream;

  @override
  Future<List<Product>> getAll() async => const [];

  @override
  Future<Product?> getById(String id) async => null;

  @override
  Future<void> save(Product product) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clear() async {}
}

class _FakeSettingsRepository implements AppSettingsRepository {
  @override
  Future<AppSettings> load() async => AppSettings.defaults;

  @override
  Future<void> save(AppSettings settings) async {}

  @override
  Future<void> clear() async {}
}

class _FakeNotificationScheduler implements ExpirationNotificationScheduler {
  @override
  Stream<CivilDate> get openedExpirationDates => const Stream.empty();

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  void dispose() {}

  @override
  Future<CivilDate?> initialize() async => null;

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
  }) async => const NotificationSynchronizationResult();
}
