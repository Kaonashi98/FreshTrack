import 'dart:async';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/core/app.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';

void main() {
  testWidgets('il tap sulla notifica apre i prodotti della relativa data', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final date = DateTime(2026, 8, 4);
    final scheduler = _FakeScheduler();
    final repository = _FakeRepository([_product('Latte', date)]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productRepositoryProvider.overrideWithValue(repository),
          expirationNotificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: const FreshTrackApp(),
      ),
    );
    await tester.pumpAndSettle();

    final appContext = tester.element(find.text('La tua dispensa'));
    expect(Localizations.localeOf(appContext).languageCode, 'it');

    scheduler.open(date);
    await tester.pumpAndSettle();

    expect(find.text('Scadenze del 04/08/2026'), findsOneWidget);
    expect(find.byKey(const Key('expiry-date-filter')), findsOneWidget);
    expect(find.text('Latte'), findsOneWidget);
  });
}

class _FakeScheduler implements ExpirationNotificationScheduler {
  final _openedDates = StreamController<CivilDate>.broadcast();

  void open(DateTime date) => _openedDates.add(CivilDate.fromDateTime(date));

  @override
  Stream<CivilDate> get openedExpirationDates => _openedDates.stream;

  @override
  Future<CivilDate?> initialize() async => null;

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<bool> requestNotificationPermission() async => true;

  @override
  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
  }) async => const NotificationSynchronizationResult();

  @override
  void dispose() => _openedDates.close();
}

class _FakeRepository implements ProductRepository {
  _FakeRepository(this.products);

  final List<Product> products;

  @override
  Stream<List<Product>> watchAll() => Stream.value(products);

  @override
  Future<List<Product>> getAll() async => products;

  @override
  Future<Product?> getById(String id) async => null;

  @override
  Future<void> save(Product product) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<void> clear() async {}
}

Product _product(String name, DateTime expirationDate) => Product(
  id: name,
  name: name,
  category: ProductCategory.food,
  quantity: 1,
  unit: MeasurementUnit.pieces,
  purchaseDate: CivilDate.fromDateTime(
    expirationDate.subtract(const Duration(days: 2)),
  ),
  expirationDate: CivilDate.fromDateTime(expirationDate),
  status: ProductStatus.available,
  notificationDaysBefore: 3,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);
