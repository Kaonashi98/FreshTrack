import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_planner.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
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
      _product('Latte', DateTime(2026, 8, 4)),
    ], now: DateTime(2026, 8, 4, 8));

    expect(plans, hasLength(1));
    expect(plans.single.title, 'Latte scade oggi');
    expect(plans.single.body, 'Usalo o consumalo oggi per evitare sprechi.');
  });

  test('i farmaci usano un testo senza invito a consumare', () {
    final plans = planner.create([
      _product(
        'Insulina',
        DateTime(2026, 8, 4),
        category: ProductCategory.medicines,
      ),
    ], now: DateTime(2026, 8, 4, 8));

    expect(plans.single.title, 'Insulina scade oggi');
    expect(
      plans.single.body,
      'Controlla la scadenza. FreshTrack non sostituisce il parere di un medico o di un farmacista.',
    );
  });

  test('pianifica il preavviso globale, non quello salvato sul prodotto', () {
    final expirationDate = DateTime(2026, 8, 10);
    final plans = planner.create(
      [_product('Latte', expirationDate, notificationDaysBefore: 0)],
      now: DateTime(2026, 8, 1, 8),
      daysBefore: 3,
    );

    final advance = plans.singleWhere(
      (plan) => plan.title == 'Latte scade tra 3 giorni',
    );
    expect(advance.date, CivilDate(2026, 8, 7));
    expect(advance.payload, 'expiry-date:2026-08-10');
    expect(plans, hasLength(2));
  });

  test('senza preavviso globale non crea avvisi anticipati', () {
    final plans = planner.create([
      _product('Latte', DateTime(2026, 8, 10), notificationDaysBefore: 3),
    ], now: DateTime(2026, 8, 1, 8));

    expect(plans, hasLength(1));
    expect(plans.single.title, 'Latte scade oggi');
  });

  test('rispetta l’orario configurato per gli avvisi', () {
    final product = _product('Yogurt', DateTime(2026, 8, 4));

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
      CivilDate(2026, 8, 4),
    );
    expect(planner.dateFromPayload('payload-non-valido'), isNull);
  });

  test('ID scadenza e preavviso sono deterministici e senza collisioni', () {
    final plans = planner.create(
      [
        _product('A', DateTime(2026, 10, 25)),
        _product('B', DateTime(2026, 10, 26)),
      ],
      now: DateTime(2026, 10, 20, 8),
      daysBefore: 1,
    );
    final ids = plans.map((plan) => plan.id).toSet();
    expect(ids, hasLength(plans.length));
    expect(ids.where((id) => id > 0), hasLength(2));
    expect(ids.where((id) => id < 0), hasLength(2));
  });

  test('il preavviso attraversa il cambio DST come giorno civile', () {
    final plans = planner.create(
      [_product('Latte', DateTime(2026, 3, 30))],
      now: DateTime(2026, 3, 20, 8),
      daysBefore: 2,
    );
    final advance = plans.singleWhere((plan) => plan.id < 0);
    expect(advance.date, CivilDate(2026, 3, 28));
  });

  test('1000 prodotti generano piani raggruppati con ID univoci', () {
    final products = List.generate(
      1000,
      (index) => _product(
        'Prodotto $index',
        DateTime(2026, 9, 1).add(Duration(days: index % 365)),
      ),
    );
    final stopwatch = Stopwatch()..start();
    final plans = planner.create(
      products,
      now: DateTime(2026, 8, 24, 8),
      daysBefore: 3,
    );
    stopwatch.stop();
    expect(plans.map((plan) => plan.id).toSet(), hasLength(plans.length));
    expect(plans.length, lessThanOrEqualTo(730));
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 2)));
  });
}

Product _product(
  String name,
  DateTime expirationDate, {
  ProductStatus status = ProductStatus.available,
  ProductCategory category = ProductCategory.food,
  int notificationDaysBefore = 0,
}) => Product(
  id: name,
  name: name,
  category: category,
  quantity: 1,
  unit: MeasurementUnit.pieces,
  purchaseDate: CivilDate.fromDateTime(
    expirationDate.subtract(const Duration(days: 2)),
  ),
  expirationDate: CivilDate.fromDateTime(expirationDate),
  status: status,
  notificationDaysBefore: notificationDaysBefore,
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 1),
);
