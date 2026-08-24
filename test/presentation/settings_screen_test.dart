import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/data/media/product_image_storage.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:freshtrack/presentation/settings/settings_screen.dart';

void main() {
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'FreshTrack',
      packageName: 'io.github.kaonashi98.freshtrack',
      version: '1.0.0',
      buildNumber: '2',
      buildSignature: '',
    );
  });

  testWidgets('cambia tema e salva la preferenza', (tester) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = _MemorySettingsRepository();
    final scheduler = _FakeNotificationScheduler();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(repository),
          expirationNotificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tema dell’app'), findsOneWidget);
    expect(find.text('Preavviso'), findsOneWidget);
    expect(find.text('Promemoria di scadenza'), findsOneWidget);
    expect(
      find.text('Attivi. Gli avvisi restano sul dispositivo.'),
      findsOneWidget,
    );
    expect(scheduler.permissionRequests, 0);
    expect(AppSettings.defaults.notificationDaysBefore, 0);
    expect(
      find.text('Avvisa il giorno della scadenza, per tutti i prodotti.'),
      findsOneWidget,
    );
    expect(find.text('Esporta dati'), findsNothing);
    expect(find.text('Importa dati'), findsNothing);
    expect(find.byKey(const Key('notification-time')), findsOneWidget);
    expect(find.byKey(const Key('medical-disclaimer')), findsOneWidget);

    await tester.tap(find.text('Chiaro'));
    await tester.pumpAndSettle();

    expect(repository.saved.themePreference, AppThemePreference.light);

    await tester.scrollUntilVisible(
      find.byKey(const Key('notification-time')),
      250,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.byKey(const Key('notification-time')));
    await tester.pumpAndSettle();
    expect(find.text('Annulla'), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('app-version')),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Versione 1.0.0 · build 2'), findsOneWidget);
  });

  testWidgets('richiede le notifiche solo dopo un gesto esplicito', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scheduler = _FakeNotificationScheduler(enabled: false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(
            _MemorySettingsRepository(),
          ),
          expirationNotificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 0);
    expect(find.byKey(const Key('enable-notifications')), findsOneWidget);
    expect(
      find.text('Non attivi. Abilitali per ricevere gli avvisi.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('enable-notifications')));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 1);
    expect(
      find.text('Attivi. Gli avvisi restano sul dispositivo.'),
      findsOneWidget,
    );
  });

  testWidgets('permesso notifiche negato mantiene uno stato coerente', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final scheduler = _FakeNotificationScheduler(
      enabled: false,
      grantPermission: false,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(
            _MemorySettingsRepository(),
          ),
          expirationNotificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enable-notifications')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Permesso non concesso'), findsOneWidget);
    expect(scheduler.enabled, isFalse);
  });

  testWidgets('cancella prodotti, immagini e preferenze dopo conferma', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settingsRepository = _MemorySettingsRepository()
      ..saved = AppSettings.defaults.copyWith(
        themePreference: AppThemePreference.light,
        notificationDaysBefore: 4,
      );
    final productRepository = _MemoryProductRepository([_product()]);
    final imageStorage = _FakeProductImageStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(settingsRepository),
          expirationNotificationSchedulerProvider.overrideWithValue(
            _FakeNotificationScheduler(),
          ),
          productRepositoryProvider.overrideWithValue(productRepository),
          productImageStorageProvider.overrideWithValue(imageStorage),
        ],
        child: const MaterialApp(home: Scaffold(body: SettingsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('clear-data')),
      300,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(find.byKey(const Key('clear-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancella'));
    await tester.pumpAndSettle();

    expect(productRepository.products, isEmpty);
    expect(imageStorage.deleteAllCalls, 1);
    expect(settingsRepository.saved.themePreference, AppThemePreference.dark);
    expect(settingsRepository.saved.notificationDaysBefore, 0);
    expect(find.text('Tutti i dati sono stati cancellati.'), findsOneWidget);
  });
}

class _FakeNotificationScheduler implements ExpirationNotificationScheduler {
  _FakeNotificationScheduler({
    this.enabled = true,
    this.grantPermission = true,
  });

  bool enabled;
  final bool grantPermission;
  int permissionRequests = 0;

  @override
  Stream<CivilDate> get openedExpirationDates => const Stream.empty();

  @override
  Future<bool> areNotificationsEnabled() async => enabled;

  @override
  void dispose() {}

  @override
  Future<CivilDate?> initialize() async => null;

  @override
  Future<bool> requestNotificationPermission() async {
    permissionRequests++;
    enabled = grantPermission;
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

class _MemorySettingsRepository implements AppSettingsRepository {
  AppSettings saved = AppSettings.defaults;

  @override
  Future<void> clear() async {
    saved = AppSettings.defaults;
  }

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings settings) async {
    saved = settings;
  }
}

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
  Stream<List<Product>> watchAll() => Stream.value(products);

  @override
  Future<List<Product>> getAll() async => products;
}

class _FakeProductImageStorage extends ProductImageStorage {
  int deleteAllCalls = 0;

  @override
  Future<void> deleteAll() async {
    deleteAllCalls++;
  }
}

Product _product() => Product(
  id: 'latte',
  name: 'Latte',
  category: ProductCategory.food,
  quantity: 1,
  unit: MeasurementUnit.liters,
  purchaseDate: CivilDate(2026, 8, 20),
  expirationDate: CivilDate(2026, 8, 25),
  status: ProductStatus.available,
  notificationDaysBefore: 0,
  createdAt: DateTime(2026, 8, 20),
  updatedAt: DateTime(2026, 8, 20),
);
