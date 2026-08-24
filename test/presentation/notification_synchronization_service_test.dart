import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';

void main() {
  test(
    'serializza modifiche rapide e usa ogni volta lo stato più recente',
    () async {
      final repository = _Repository([_product('A')]);
      final scheduler = _Scheduler();
      final service = NotificationSynchronizationService(
        repository,
        scheduler,
        () async => AppSettings.defaults,
      );

      final first = service.synchronizeLatest();
      repository.products
        ..clear()
        ..add(_product('B'));
      final second = service.synchronizeLatest();
      await Future.wait([first, second]);

      expect(scheduler.snapshots, hasLength(2));
      expect(scheduler.snapshots.last.single.name, 'B');
      expect(scheduler.maximumConcurrentCalls, 1);
    },
  );

  test('dopo eliminazione sincronizza una lista senza il record', () async {
    final repository = _Repository([_product('A')]);
    final scheduler = _Scheduler();
    final service = NotificationSynchronizationService(
      repository,
      scheduler,
      () async => AppSettings.defaults,
    );
    await repository.delete('A');
    await service.synchronizeLatest();
    expect(scheduler.snapshots.single, isEmpty);
  });
}

class _Repository implements ProductRepository {
  _Repository(this.products);
  final List<Product> products;

  @override
  Future<void> clear() async => products.clear();
  @override
  Future<void> delete(String id) async =>
      products.removeWhere((item) => item.id == id);
  @override
  Future<List<Product>> getAll() async => List.of(products);
  @override
  Future<Product?> getById(String id) async => null;
  @override
  Future<void> save(Product product) async {}
  @override
  Stream<List<Product>> watchAll() => Stream.value(products);
}

class _Scheduler implements ExpirationNotificationScheduler {
  final snapshots = <List<Product>>[];
  int _concurrentCalls = 0;
  int maximumConcurrentCalls = 0;

  @override
  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
  }) async {
    _concurrentCalls++;
    if (_concurrentCalls > maximumConcurrentCalls) {
      maximumConcurrentCalls = _concurrentCalls;
    }
    snapshots.add(List.of(products));
    await Future<void>.delayed(Duration.zero);
    _concurrentCalls--;
    return const NotificationSynchronizationResult();
  }

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
}

Product _product(String name) => Product(
  id: name,
  name: name,
  category: ProductCategory.food,
  quantity: 1,
  unit: MeasurementUnit.pieces,
  purchaseDate: CivilDate(2026, 8, 1),
  expirationDate: CivilDate(2026, 8, 30),
  status: ProductStatus.available,
  notificationDaysBefore: 0,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);
