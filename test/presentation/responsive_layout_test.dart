import 'package:freshtrack/presentation/settings/about_settings_screen.dart';
import 'package:freshtrack/presentation/settings/appearance_settings_screen.dart';
import 'package:freshtrack/presentation/settings/data_settings_screen.dart';
import 'package:freshtrack/presentation/settings/notification_settings_screen.dart';
import 'package:freshtrack/presentation/settings/privacy_policy_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/core/app.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:freshtrack/presentation/dashboard/dashboard_screen.dart';
import 'package:freshtrack/presentation/products/product_details_screen.dart';
import 'package:freshtrack/presentation/products/product_form_screen.dart';
import 'package:freshtrack/presentation/products/product_add_screen.dart';
import 'package:freshtrack/presentation/products/products_screen.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/presentation/settings/settings_screen.dart';
import '../support/fake_expiration_notification_scheduler.dart';

void main() {
  for (final entry in <String, Widget>{
    'aspetto': const AppearanceSettingsScreen(),
    'notifiche': const NotificationSettingsScreen(),
    'dati': const DataSettingsScreen(),
    'informazioni': const AboutSettingsScreen(),
    'privacy': const PrivacyPolicyScreen(),
  }.entries) {
    testWidgets('regressione: nuova schermata ${entry.key} 320dp font 2', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(
              _Repository([_product()]),
            ),
            expirationNotificationSchedulerProvider.overrideWithValue(
              _Scheduler(),
            ),
            appSettingsRepositoryProvider.overrideWithValue(
              _SettingsRepository(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('it'),
            supportedLocales: const [Locale('it'), Locale('en')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 568),
                textScaler: TextScaler.linear(2),
              ),
              child: entry.value,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(tester.takeException(), isNull);
    });
  }
  const portraitSizes = [Size(320, 568), Size(360, 640), Size(412, 915)];
  for (final size in portraitSizes) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets('schermate principali ${size.width.toInt()}dp font $scale', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = _Repository([_product()]);

        final screens = <String, Widget>{
          'dashboard': const Scaffold(body: DashboardScreen()),
          'products': const Scaffold(body: ProductsScreen()),
          'form': const ProductFormScreen(),
          'add': const ProductAddScreen(),
          'details': const ProductDetailsScreen(productId: 'latte'),
          'settings': const Scaffold(body: SettingsScreen()),
        };
        for (final entry in screens.entries) {
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                productRepositoryProvider.overrideWithValue(repository),
                expirationNotificationSchedulerProvider.overrideWithValue(
                  _Scheduler(),
                ),
                appSettingsRepositoryProvider.overrideWithValue(
                  _SettingsRepository(),
                ),
              ],
              child: MaterialApp(
                locale: const Locale('it'),
                supportedLocales: const [Locale('it'), Locale('en')],
                localizationsDelegates: GlobalMaterialLocalizations.delegates,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: entry.value,
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          expect(tester.takeException(), isNull, reason: entry.key);
        }
      });
    }
  }

  for (final size in [const Size(640, 360), const Size(915, 412)]) {
    testWidgets('schermate principali landscape $size font 2.0', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _Repository([_product()]);
      for (final screen in <Widget>[
        const Scaffold(body: DashboardScreen()),
        const Scaffold(body: ProductsScreen()),
        const ProductFormScreen(),
        const ProductAddScreen(),
        const ProductDetailsScreen(productId: 'latte'),
        const Scaffold(body: SettingsScreen()),
      ]) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              productRepositoryProvider.overrideWithValue(repository),
              expirationNotificationSchedulerProvider.overrideWithValue(
                _Scheduler(),
              ),
              appSettingsRepositoryProvider.overrideWithValue(
                _SettingsRepository(),
              ),
            ],
            child: MaterialApp(
              locale: const Locale('it'),
              supportedLocales: const [Locale('it'), Locale('en')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(2),
                ),
                child: screen,
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 350));
        expect(tester.takeException(), isNull);
      }
    });
  }

  const shellSizes = [
    Size(320, 568),
    Size(360, 640),
    Size(412, 915),
    Size(640, 360),
    Size(915, 412),
  ];
  for (final size in shellSizes) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'MainShell vuota $size font $scale mantiene navigazione, aggiunta e form utilizzabili',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                productRepositoryProvider.overrideWithValue(_Repository([])),
                expirationNotificationSchedulerProvider.overrideWithValue(
                  _Scheduler(),
                ),
                appSettingsRepositoryProvider.overrideWithValue(
                  _SettingsRepository(),
                ),
              ],
              child: const FreshTrackApp(),
            ),
          );
          await tester.pumpAndSettle();

          final add = find.byKey(const Key('add-product'));
          final navigation = find.byKey(const Key('main-navigation'));
          expect(add, findsOneWidget);
          expect(tester.getSize(add).height, greaterThanOrEqualTo(48));
          expect(
            tester.getRect(navigation).contains(tester.getCenter(add)),
            isTrue,
          );
          expect(
            tester.getRect(add).overlaps(tester.getRect(find.text('Oggi'))),
            isFalse,
          );
          expect(
            tester.getRect(add).overlaps(tester.getRect(find.text('Prodotti'))),
            isFalse,
          );
          await tester.tap(find.text('Prodotti'));
          await tester.pumpAndSettle();
          expect(add, findsOneWidget);
          expect(find.byKey(const Key('empty-products-add')), findsNothing);
          await tester.tap(add);
          await tester.pumpAndSettle();
          final manual = find.byKey(const Key('add-manually'));
          await tester.scrollUntilVisible(
            manual,
            100,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.ensureVisible(manual);
          await tester.pumpAndSettle();
          await tester.tap(manual);
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('product-name')), findsOneWidget);
          final save = find.byKey(const Key('save-product'));
          expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
          expect(tester.getRect(save).bottom, lessThanOrEqualTo(size.height));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}

class _Repository implements ProductRepository {
  _Repository(this.products);
  final List<Product> products;
  @override
  Future<void> clear() async {}
  @override
  Future<void> replaceAll(List<Product> products) async {}
  @override
  Future<void> delete(String id) async {}
  @override
  Future<List<Product>> getAll() async => products;
  @override
  Future<Product?> getById(String id) async => products.first;
  @override
  Future<void> save(Product product) async {}
  @override
  Stream<List<Product>> watchAll() => Stream.value(products);
}

class _SettingsRepository implements AppSettingsRepository {
  @override
  Future<void> clear() async {}
  @override
  Future<AppSettings> load() async => AppSettings.defaults.copyWith(
    languagePreference: AppLanguagePreference.italian,
  );
  @override
  Future<void> save(AppSettings settings) async {}
}

class _Scheduler extends FakeExpirationNotificationScheduler {
  @override
  Future<bool> areNotificationsEnabled() async => true;
  @override
  void dispose() {}
  @override
  Future<CivilDate?> initialize() async => null;
  @override
  Stream<CivilDate> get openedExpirationDates => const Stream.empty();
  @override
  Future<bool> requestNotificationPermission() async => true;
  @override
  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
    String languageCode = 'it',
    bool preferExactTimes = false,
  }) async => const NotificationSynchronizationResult();
}

Product _product() => Product(
  id: 'latte',
  name: 'Latte intero con un nome sufficientemente lungo',
  description:
      'Descrizione lunga per verificare il ridimensionamento del testo.',
  category: ProductCategory.food,
  quantity: 1,
  unit: MeasurementUnit.liters,
  purchaseDate: CivilDate.fromDateTime(DateTime.now()),
  expirationDate: CivilDate.fromDateTime(DateTime.now()).addDays(3),
  status: ProductStatus.available,
  notificationDaysBefore: 0,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
