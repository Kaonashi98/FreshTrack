import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_planner.dart';
import 'package:freshtrack/domain/products/product.dart';

void main() {
  const planner = ExpirationNotificationPlanner();

  test('raggruppa in una sola notifica i prodotti della stessa data', () {
    final date = DateTime(2026, 8, 4);
    final plans = planner.create([
      _product('Latte', date),
      _product('Yogurt', date),
      _product('Pane consumato', date, status: ProductStatus.consumed),
    ], now: DateTime(2026, 8, 1, 18));

    expect(plans, hasLength(1));
    expect(plans.single.id, 20260804);
    expect(plans.single.title, '2 prodotti scadono oggi');
    expect(plans.single.body, 'Latte, Yogurt');
    expect(plans.single.payload, 'expiry-date:2026-08-04');
  });

  test('la notifica del giorno di scadenza contiene il nome', () {
    final plans = planner.create([
      _product('Insulina', DateTime(2026, 8, 4), notificationDaysBefore: 0),
    ], now: DateTime(2026, 8, 4, 8));

    expect(plans, hasLength(1));
    expect(plans.single.title, 'Insulina scade oggi');
    expect(plans.single.body, 'Consumalo oggi per evitare sprechi.');
  });
  test('pianifica anche il preavviso configurato sul prodotto', () {
    final expirationDate = DateTime(2026, 8, 10);
    final plans = planner.create([
      _product('Latte', expirationDate),
    ], now: DateTime(2026, 8, 1, 8));

    final advance = plans.singleWhere(
      (plan) => plan.title == 'Latte scade tra 3 giorni',
    );
    expect(advance.date, DateTime(2026, 8, 7));
    expect(advance.payload, 'expiry-date:2026-08-10');
    expect(plans, hasLength(2));
  });
  test('rispetta l’orario configurato per gli avvisi', () {
    final product = _product(
      'Yogurt',
      DateTime(2026, 8, 4),
      notificationDaysBefore: 0,
    );

    final beforeConfiguredTime = planner.create(
      [product],
      now: DateTime(2026, 8, 4, 10),
      notificationHour: 18,
      notificationMinute: 30,
    );
    final afterConfiguredTime = planner.create(
      [product],
      now: DateTime(2026, 8, 4, 19),
      notificationHour: 18,
      notificationMinute: 30,
    );

    expect(beforeConfiguredTime, hasLength(1));
    expect(afterConfiguredTime, isEmpty);
  });
  test('ignora prodotti scaduti e decodifica la data dal payload', () {
    final plans = planner.create([
      _product('Vecchio', DateTime(2026, 7, 31)),
    ], now: DateTime(2026, 8, 1));

    expect(plans, isEmpty);
    expect(
      planner.dateFromPayload('expiry-date:2026-08-04'),
      DateTime(2026, 8, 4),
    );
    expect(planner.dateFromPayload('payload-non-valido'), isNull);
  });
}

Product _product(
  String name,
  DateTime expirationDate, {
  ProductStatus status = ProductStatus.available,
  int notificationDaysBefore = 3,
}) => Product(
  id: name,
  name: name,
  category: ProductCategory.food,
  quantity: 1,
  unit: MeasurementUnit.pieces,
  purchaseDate: expirationDate.subtract(const Duration(days: 2)),
  expirationDate: expirationDate,
  status: status,
  notificationDaysBefore: notificationDaysBefore,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);
