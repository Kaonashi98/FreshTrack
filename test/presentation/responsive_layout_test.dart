import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
import 'package:freshtrack/presentation/products/products_screen.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/presentation/settings/settings_screen.dart';

void main() {
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
        'MainShell vuota $size font $scale mantiene FAB, CTA e bottom bar separati',
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

          final fab = find.byKey(const Key('add-product'));
          final navigationBar = find.byType(NavigationBar);
          expect(fab, findsOneWidget);
          expect(navigationBar, findsOneWidget);
          expect(
            tester.getRect(fab).bottom,
            lessThanOrEqualTo(tester.getRect(navigationBar).top),
          );

          await tester.tap(find.byIcon(Icons.inventory_2_outlined));
          await tester.pumpAndSettle();

          final panel = find.byKey(const Key('empty-products-panel'));
          final cta = find.byKey(const Key('empty-products-add'));
          expect(fab, findsNothing);
          final navigationTop = tester.getRect(navigationBar).top;
          final panelInitiallyVisible = panel.evaluate().isNotEmpty;
          if (panelInitiallyVisible) {
            final headerBottom = tester
                .getBottomLeft(find.text('0 prodotti'))
                .dy;
            final initialPanelRect = tester.getRect(panel);
            if (initialPanelRect.height <= navigationTop - headerBottom) {
              final availableCenter = (headerBottom + navigationTop) / 2;
              expect(
                initialPanelRect.center.dy,
                moreOrLessEquals(availableCenter, epsilon: 44),
              );
            }
          } else {
            final productsScrollable = find
                .descendant(
                  of: find.byKey(const Key('products-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first;
            await tester.scrollUntilVisible(
              cta,
              80,
              scrollable: productsScrollable,
            );
            await tester.pump();
          }

          expect(panel, findsOneWidget);
          expect(cta, findsOneWidget);
          expect(tester.getSize(cta).height, greaterThanOrEqualTo(48));
          await tester.ensureVisible(cta);
          await tester.pump();
          final ctaRect = tester.getRect(cta);
          expect(ctaRect.top, greaterThanOrEqualTo(0));
          expect(ctaRect.bottom, lessThanOrEqualTo(navigationTop));
          expect(find.bySemanticsLabel('Aggiungi prodotto'), findsOneWidget);

          for (final text in [
            'La dispensa è vuota',
            'Inizia registrando una scadenza.',
            'Aggiungi prodotto',
          ]) {
            final paragraph = tester.renderObject<RenderParagraph>(
              find.text(text),
            );
            expect(paragraph.didExceedMaxLines, isFalse, reason: text);
          }

          await tester.drag(
            find.byKey(const Key('products-scroll')),
            const Offset(0, -48),
          );
          await tester.pump();
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
  Future<AppSettings> load() async => AppSettings.defaults;
  @override
  Future<void> save(AppSettings settings) async {}
}

class _Scheduler implements ExpirationNotificationScheduler {
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
