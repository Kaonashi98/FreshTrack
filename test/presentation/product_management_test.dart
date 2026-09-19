import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:freshtrack/data/products/open_food_facts_service.dart';
import 'package:freshtrack/presentation/providers/data_transfer_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:freshtrack/presentation/products/product_details_screen.dart';
import 'package:freshtrack/presentation/products/product_form_screen.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/shared/widgets/product_card.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('scadenze rapide mostrano e salvano il giorno scelto', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repo = _MemoryProductRepository([]);
    final router = _auditFormRouter();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, repo));
    await tester.tap(find.byKey(const Key('audit-new')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('product-name')),
      'Prova date rapide',
    );
    for (final days in [1, 7, 0]) {
      final choice = find.byKey(Key('quick-expiry-$days'));
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(tester.widget<ChoiceChip>(choice).selected, isTrue);
    }
    await tester.tap(find.byKey(const Key('save-product')));
    await tester.pumpAndSettle();
    expect(
      repo.products.single.expirationDate,
      CivilDate.fromDateTime(DateTime.now()),
    );
  });

  testWidgets(
    'regressione: salvataggi ripetuti durante sync non duplicano il prodotto',
    (tester) async {
      _useLargeViewport(tester);
      final repo = _MemoryProductRepository([]);
      final scheduler = _AuditBlockingScheduler();
      final router = _auditFormRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router, repo, scheduler: scheduler));
      await tester.tap(find.byKey(const Key('audit-new')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('product-name')),
        'Latte audit',
      );
      await tester.tap(find.byKey(const Key('save-product')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(repo.products, hasLength(1));
      expect(scheduler.started, isTrue);
      await tester.tap(find.byKey(const Key('save-product')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final savedCount = repo.products.length;
      await tester.pumpWidget(const SizedBox.shrink());
      scheduler.release.complete();
      await tester.pumpAndSettle();
      expect(
        savedCount,
        1,
        reason:
            'Il pulsante deve restare protetto fino al completamento del flusso',
      );
    },
  );
  testWidgets(
    'regressione: quantita negativa non salvabile dopo chiusura dettagli',
    (tester) async {
      _useLargeViewport(tester);
      final repo = _MemoryProductRepository([]);
      final router = _auditFormRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(router, repo));
      await tester.tap(find.byKey(const Key('audit-new')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('product-name')),
        'Quantita audit',
      );
      await tester.tap(find.text('Altri dettagli'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('product-quantity')), '-2');
      await tester.tap(find.text('Altri dettagli'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('product-quantity')), findsNothing);
      await tester.tap(find.byKey(const Key('save-product')));
      await tester.pumpAndSettle();
      expect(
        repo.products,
        isEmpty,
        reason:
            'La validazione deve applicarsi anche quando il campo non e montato',
      );
    },
  );
  testWidgets(
    'regressione: risposta barcode precedente non modifica il prodotto successivo',
    (tester) async {
      _useLargeViewport(tester);
      final repo = _MemoryProductRepository([]);
      final lookup = _AuditDelayedLookup();
      final router = GoRouter(
        initialLocation: '/products/new',
        routes: [
          GoRoute(
            path: '/products/new',
            builder: (_, _) => const ProductFormScreen(),
          ),
          GoRoute(
            path: '/products/scan-barcode',
            builder: (context, _) => Scaffold(
              body: FilledButton(
                onPressed: () => context.pop('3017620422003'),
                child: const Text('Rileva codice audit'),
              ),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(repo),
            appSettingsRepositoryProvider.overrideWithValue(
              _FakeSettingsRepository(),
            ),
            expirationNotificationSchedulerProvider.overrideWithValue(
              _FakeNotificationScheduler(),
            ),
            openFoodFactsServiceProvider.overrideWith((ref) async => lookup),
          ],
          child: MaterialApp.router(
            locale: const Locale('it'),
            supportedLocales: const [Locale('it'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('scan-barcode')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Rileva codice audit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(lookup.started, isTrue);
      await tester.enterText(
        find.byKey(const Key('product-name')),
        'Primo prodotto manuale',
      );
      await tester.tap(find.byKey(const Key('save-and-add-another')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(repo.products, hasLength(1));
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('product-name')))
            .controller!
            .text,
        isEmpty,
      );
      await tester.enterText(
        find.byKey(const Key('product-name')),
        'Secondo prodotto',
      );
      lookup.release.complete(
        const BarcodeLookupResult.found(
          BarcodeProductLookup(
            barcode: '3017620422003',
            name: 'Nome del vecchio barcode',
            category: ProductCategory.food,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextFormField>(find.byKey(const Key('product-name')))
            .controller!
            .text,
        'Secondo prodotto',
      );
    },
  );
  testWidgets(
    'regressione: nuovo prodotto con scadenza oggi deve essere salvabile',
    (tester) async {
      _useLargeViewport(tester);
      final repository = _MemoryProductRepository([]);
      final router = GoRouter(
        initialLocation: '/host',
        routes: [
          GoRoute(
            path: '/host',
            builder: (context, _) => Scaffold(
              body: FilledButton(
                key: const Key('audit-new'),
                onPressed: () => context.push('/products/new'),
                child: const Text('Nuovo'),
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
      await tester.pumpWidget(_app(router, repository));
      await tester.tap(find.byKey(const Key('audit-new')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('product-name')),
        'Scade oggi',
      );
      await tester.tap(
        find
            .ancestor(
              of: find.text('Data di scadenza'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(DateTime.now().day.toString()).last);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-product')));
      await tester.pumpAndSettle();
      expect(
        find.text('La scadenza non può precedere l’acquisto.'),
        findsNothing,
      );
      expect(
        repository.products,
        hasLength(1),
        reason:
            'Un prodotto che scade oggi deve poter essere aggiunto con la data acquisto predefinita di oggi',
      );
    },
  );
  testWidgets('thumbnail decodifica alla dimensione fisica visualizzata', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        supportedLocales: const [Locale('it'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: ProductCard(
            product: _product(imagePath: 'foto-non-presente.jpg'),
          ),
        ),
      ),
    );
    final image = tester.widget<Image>(find.byType(Image));
    final provider = image.image as ResizeImage;
    expect(provider.width, 96);
    expect(provider.height, 96);
  });

  testWidgets('modifica il nome conservando la precisione della quantità', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([
      _product().copyWith(quantity: 0.25),
    ]);
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
    expect((await repository.getById('latte'))?.quantity, 0.25);
    expect(
      (await repository.getById('latte'))?.category,
      ProductCategory.beverages,
    );
    expect(find.byKey(const Key('open-edit')), findsOneWidget);
  });

  testWidgets('salva un prodotto e prepara subito il successivo', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([]);
    final router = GoRouter(
      initialLocation: '/products/new',
      routes: [
        GoRoute(
          path: '/products/new',
          builder: (_, _) => const ProductFormScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('product-name')), 'Yogurt');
    await tester.tap(find.byKey(const Key('save-and-add-another')));
    await tester.pumpAndSettle();

    expect(repository.products, hasLength(1));
    expect(repository.products.single.name, 'Yogurt');
    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('product-name')),
    );
    expect(nameField.controller?.text, isEmpty);
    expect(find.byKey(const Key('product-name')), findsOneWidget);
    expect(
      find.text('Prodotto salvato. Puoi aggiungerne un altro.'),
      findsOneWidget,
    );
  });

  testWidgets('propone i prodotti già usati durante la digitazione', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([_product()]);
    final router = GoRouter(
      initialLocation: '/products/new',
      routes: [
        GoRoute(
          path: '/products/new',
          builder: (_, _) => const ProductFormScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();
    final nameFinder = find.byKey(const Key('product-name'));
    await tester.tap(nameFinder);
    await tester.pump();
    await tester.enterText(nameFinder, 'lat');
    await tester.pump();

    expect(find.text('Latte'), findsOneWidget);
    await tester.tap(find.text('Latte'));
    await tester.pumpAndSettle();

    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('product-name')),
    );
    expect(nameField.controller?.text, 'Latte');
  });

  testWidgets('duplica un prodotto in un nuovo form precompilato', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([_product()]);
    final router = GoRouter(
      initialLocation: '/products/latte',
      routes: [
        GoRoute(
          path: '/products/new',
          builder: (_, state) => ProductFormScreen(
            templateId: state.uri.queryParameters['template'],
          ),
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
    await tester.tap(find.byKey(const Key('duplicate-product')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('product-name')), findsOneWidget);
    final nameField = tester.widget<TextFormField>(
      find.byKey(const Key('product-name')),
    );
    expect(nameField.controller?.text, 'Latte');
    expect(find.byKey(const Key('save-and-add-another')), findsOneWidget);
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
        child: MaterialApp.router(
          locale: const Locale('it'),
          supportedLocales: const [Locale('it'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open-new')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('product-name')),
      'Crema solare',
    );
    await tester.tap(find.text('Alimentari').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cura personale'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-product')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Attivare i promemoria?'), findsOneWidget);
    expect(scheduler.permissionRequests, 0);
    await tester.tap(find.byKey(const Key('confirm-enable-notifications')));
    await tester.pumpAndSettle();
    expect(scheduler.permissionRequests, 1);
    expect(repository.products.single.name, 'Crema solare');
    expect(repository.products.single.category, ProductCategory.personalCare);
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
        child: MaterialApp.router(
          locale: const Locale('it'),
          supportedLocales: const [Locale('it'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          routerConfig: router,
        ),
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

  testWidgets('segna una bevanda come consumata e la ripristina', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([_product()]);
    final scheduler = _FakeNotificationScheduler();
    final router = _detailsRouter('latte');
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, repository, scheduler: scheduler));
    await tester.pumpAndSettle();

    expect(find.text('Segna come consumato'), findsOneWidget);
    await tester.tap(find.byKey(const Key('complete-product')));
    await tester.pumpAndSettle();

    expect((await repository.getById('latte'))?.status, ProductStatus.consumed);
    expect(find.text('Prodotto consumato'), findsOneWidget);
    expect(find.byKey(const Key('restore-product')), findsOneWidget);
    expect(
      scheduler.synchronizedProducts.single.status,
      ProductStatus.consumed,
    );

    await tester.tap(find.byKey(const Key('restore-product')));
    await tester.pumpAndSettle();

    expect(
      (await repository.getById('latte'))?.status,
      ProductStatus.available,
    );
    expect(find.text('Segna come consumato'), findsOneWidget);
    expect(
      scheduler.synchronizedProducts.single.status,
      ProductStatus.available,
    );
  });

  testWidgets('usa il testo utilizzato per la cura personale', (tester) async {
    _useLargeViewport(tester);
    final product = _product(
      id: 'crema',
      name: 'Crema solare',
      category: ProductCategory.personalCare,
    );
    final repository = _MemoryProductRepository([product]);
    final router = _detailsRouter(product.id);
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();

    expect(find.text('Segna come utilizzato'), findsOneWidget);
    expect(find.text('Segna come consumato'), findsNothing);
    await tester.tap(find.byKey(const Key('complete-product')));
    await tester.pumpAndSettle();

    expect(find.text('Prodotto utilizzato'), findsOneWidget);
    expect(
      (await repository.getById(product.id))?.status,
      ProductStatus.consumed,
    );
  });

  testWidgets('un errore nei promemoria non annulla il cambio di stato', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([_product()]);
    final scheduler = _FakeNotificationScheduler(failSynchronization: true);
    final router = _detailsRouter('latte');
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, repository, scheduler: scheduler));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('complete-product')));
    await tester.pumpAndSettle();

    expect((await repository.getById('latte'))?.status, ProductStatus.consumed);
    expect(
      find.text(
        'Prodotto segnato come consumato. Alcuni promemoria non sono stati aggiornati.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('segna un prodotto come buttato solo dopo conferma', (
    tester,
  ) async {
    _useLargeViewport(tester);
    final repository = _MemoryProductRepository([_product()]);
    final router = _detailsRouter('latte');
    addTearDown(router.dispose);

    await tester.pumpWidget(_app(router, repository));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('discard-product')));
    await tester.pumpAndSettle();

    expect(find.text('Segnare il prodotto come buttato?'), findsOneWidget);
    expect(
      (await repository.getById('latte'))?.status,
      ProductStatus.available,
    );
    await tester.tap(find.byKey(const Key('confirm-discard-product')));
    await tester.pumpAndSettle();

    expect(
      (await repository.getById('latte'))?.status,
      ProductStatus.discarded,
    );
    expect(find.text('Prodotto buttato'), findsOneWidget);
    expect(find.byKey(const Key('restore-product')), findsOneWidget);
  });

  testWidgets('la scheda mostra Utilizzato per la cura personale', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('it'),
        supportedLocales: const [Locale('it'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: ProductCard(
            product: _product(
              category: ProductCategory.personalCare,
              status: ProductStatus.consumed,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Utilizzato'), findsOneWidget);
    expect(find.textContaining('Consumato'), findsNothing);
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
    expect(find.byKey(const Key('duplicate-product')), findsOneWidget);

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
    appSettingsRepositoryProvider.overrideWithValue(_FakeSettingsRepository()),
    expirationNotificationSchedulerProvider.overrideWithValue(
      scheduler ?? _FakeNotificationScheduler(),
    ),
  ],
  child: MaterialApp.router(
    locale: const Locale('it'),
    supportedLocales: const [Locale('it'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    routerConfig: router,
  ),
);

GoRouter _detailsRouter(String productId) => GoRouter(
  initialLocation: '/products/$productId',
  routes: [
    GoRoute(
      path: '/products/:id',
      builder: (_, state) =>
          ProductDetailsScreen(productId: state.pathParameters['id']!),
    ),
  ],
);

void _useLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 2800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Product _product({
  String id = 'latte',
  String name = 'Latte',
  String? imagePath,
  ProductCategory category = ProductCategory.beverages,
  ProductStatus status = ProductStatus.available,
}) => Product(
  id: id,
  name: name,
  imagePath: imagePath,
  category: category,
  quantity: 1,
  unit: MeasurementUnit.liters,
  purchaseDate: CivilDate(2026, 7, 27),
  expirationDate: CivilDate(2026, 8, 2),
  status: status,
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
  Future<void> replaceAll(List<Product> next) async {
    products
      ..clear()
      ..addAll(next);
  }

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
    this.failSynchronization = false,
  });

  bool enabled;
  final bool failStatusCheck;
  final bool failSynchronization;
  int permissionRequests = 0;
  List<Product> synchronizedProducts = const [];

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
    String languageCode = 'it',
  }) async {
    if (failSynchronization) {
      throw StateError('Sincronizzazione non disponibile');
    }
    synchronizedProducts = List.unmodifiable(products);
    return const NotificationSynchronizationResult();
  }
}

class _FakeSettingsRepository implements AppSettingsRepository {
  AppSettings _settings = AppSettings.defaults;

  @override
  Future<void> clear() async => _settings = AppSettings.defaults;

  @override
  Future<AppSettings> load() async => _settings;

  @override
  Future<void> save(AppSettings settings) async => _settings = settings;
}

GoRouter _auditFormRouter() => GoRouter(
  initialLocation: '/host',
  routes: [
    GoRoute(
      path: '/host',
      builder: (context, _) => Scaffold(
        body: FilledButton(
          key: const Key('audit-new'),
          onPressed: () => context.push('/products/new'),
          child: const Text('Nuovo'),
        ),
      ),
    ),
    GoRoute(
      path: '/products/new',
      builder: (_, _) => const ProductFormScreen(),
    ),
  ],
);

class _AuditBlockingScheduler extends _FakeNotificationScheduler {
  final release = Completer<void>();
  bool started = false;
  @override
  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
    String languageCode = 'it',
  }) async {
    started = true;
    await release.future;
    return const NotificationSynchronizationResult();
  }
}

class _AuditDelayedLookup extends OpenFoodFactsService {
  _AuditDelayedLookup() : super(http.Client(), appVersion: 'audit');
  final release = Completer<BarcodeLookupResult>();
  bool started = false;
  @override
  Future<BarcodeLookupResult> lookup(
    String rawBarcode, {
    String languageCode = 'it',
  }) {
    started = true;
    return release.future;
  }
}
