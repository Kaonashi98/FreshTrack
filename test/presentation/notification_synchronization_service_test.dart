import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/presentation/notifications/notification_coordinator.dart';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import '../support/fake_expiration_notification_scheduler.dart';

void main() {
  test(
    'due incrementi rapidi del preavviso vengono entrambi conservati',
    () async {
      final container = ProviderContainer(
        overrides: [
          appSettingsRepositoryProvider.overrideWithValue(
            _AuditSettingsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(appSettingsProvider.notifier);
      await controller.setNotificationDaysBefore(0);
      await Future.wait([
        controller.adjustNotificationDaysBefore(1),
        controller.adjustNotificationDaysBefore(1),
      ]);
      expect(
        (await container.read(
          appSettingsProvider.future,
        )).notificationDaysBefore,
        2,
      );
    },
  );
  testWidgets(
    'regressione: avvio non cancella avvisi prima del caricamento inventario',
    (tester) async {
      final repo = _AuditDelayedRepository([_product('Latte')]);
      final scheduler = _Scheduler();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productRepositoryProvider.overrideWithValue(repo),
            appSettingsRepositoryProvider.overrideWithValue(
              _AuditSettingsRepository(),
            ),
            expirationNotificationSchedulerProvider.overrideWithValue(
              scheduler,
            ),
          ],
          child: const MaterialApp(
            home: NotificationCoordinator(child: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      final snapshots = List.of(scheduler.snapshots);
      await tester.pumpWidget(const SizedBox.shrink());
      unawaited(repo.controller.close());
      expect(
        snapshots,
        isEmpty,
        reason: 'L inventario non ancora caricato non e un inventario vuoto',
      );
    },
  );
  test(
    'regressione: preferenze concorrenti conservano entrambe le modifiche',
    () async {
      final repo = _AuditSettingsRepository();
      final container = ProviderContainer(
        overrides: [appSettingsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(appSettingsProvider.future);
      final controller = container.read(appSettingsProvider.notifier);
      await Future.wait([
        controller.setThemePreference(AppThemePreference.light),
        controller.setNotificationTime(hour: 13, minute: 25),
      ]);
      final state = await container.read(appSettingsProvider.future);
      expect(state.notificationHour, 13);
      expect(state.themePreference, AppThemePreference.light);
    },
  );
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
  Future<void> replaceAll(List<Product> next) async {
    products
      ..clear()
      ..addAll(next);
  }

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

class _Scheduler extends FakeExpirationNotificationScheduler {
  final snapshots = <List<Product>>[];
  int _concurrentCalls = 0;
  int maximumConcurrentCalls = 0;

  @override
  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
    String languageCode = 'it',
    bool preferExactTimes = false,
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

class _AuditDelayedRepository extends _Repository {
  _AuditDelayedRepository(super.products);
  final controller = StreamController<List<Product>>();
  @override
  Stream<List<Product>> watchAll() => controller.stream;
}

class _AuditSettingsRepository implements AppSettingsRepository {
  AppSettings value = AppSettings.defaults;
  @override
  Future<AppSettings> load() async => value;
  @override
  Future<void> save(AppSettings next) async {
    value = next;
  }

  @override
  Future<void> clear() async {
    value = AppSettings.defaults;
  }
}
