import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product.dart';

class ExpirationNotificationPlan {
  const ExpirationNotificationPlan({
    required this.id,
    required this.date,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final CivilDate date;
  final String title;
  final String body;
  final String payload;
}

class ExpirationNotificationPlanner {
  const ExpirationNotificationPlanner();

  static const payloadPrefix = 'expiry-date:';
  static const defaultNotificationHour = 9;
  static const defaultNotificationMinute = 0;

  List<ExpirationNotificationPlan> create(
    List<Product> products, {
    required DateTime now,
    int notificationHour = defaultNotificationHour,
    int notificationMinute = defaultNotificationMinute,
    int daysBefore = 0,
  }) {
    final expiryGroups = <CivilDate, List<Product>>{};
    final advanceGroups = <(CivilDate, CivilDate, int), List<Product>>{};
    final advanceDays = daysBefore.clamp(0, 30);
    final today = CivilDate.fromDateTime(now);

    for (final product in products) {
      final expirationDate = product.expirationDate;
      if (product.status != ProductStatus.available ||
          expirationDate.isBefore(today)) {
        continue;
      }
      if (_isFutureSchedule(
        expirationDate,
        now,
        notificationHour,
        notificationMinute,
      )) {
        expiryGroups.putIfAbsent(expirationDate, () => []).add(product);
      }

      if (advanceDays == 0) continue;
      final notificationDate = expirationDate.subtractDays(advanceDays);
      if (!_isFutureSchedule(
        notificationDate,
        now,
        notificationHour,
        notificationMinute,
      )) {
        continue;
      }
      final key = (notificationDate, expirationDate, advanceDays);
      advanceGroups.putIfAbsent(key, () => []).add(product);
    }

    final plans =
        <ExpirationNotificationPlan>[
          for (final entry in expiryGroups.entries)
            _expiryPlan(entry.key, entry.value),
          for (final entry in advanceGroups.entries)
            _advancePlan(entry.key, entry.value),
        ]..sort((first, second) {
          final dateComparison = first.date.compareTo(second.date);
          return dateComparison != 0
              ? dateComparison
              : first.id.compareTo(second.id);
        });
    return plans;
  }

  CivilDate? dateFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(payloadPrefix)) return null;
    return CivilDate.tryParse(payload.substring(payloadPrefix.length));
  }

  ExpirationNotificationPlan _expiryPlan(
    CivilDate expirationDate,
    List<Product> products,
  ) {
    final count = products.length;
    return ExpirationNotificationPlan(
      id:
          expirationDate.year * 10000 +
          expirationDate.month * 100 +
          expirationDate.day,
      date: expirationDate,
      title: count == 1
          ? '${products.single.name} scade oggi'
          : '$count prodotti scadono oggi',
      body: count == 1 ? _expiryBody(products.single) : _productNames(products),
      payload: '$payloadPrefix${_isoDate(expirationDate)}',
    );
  }

  ExpirationNotificationPlan _advancePlan(
    (CivilDate, CivilDate, int) key,
    List<Product> products,
  ) {
    final (notificationDate, expirationDate, daysBefore) = key;
    final count = products.length;
    return ExpirationNotificationPlan(
      // The negative namespace cannot collide with positive expiry IDs.
      // One pre-alert per expiration date is active for the global setting.
      id:
          -(expirationDate.year * 10000 +
              expirationDate.month * 100 +
              expirationDate.day),
      date: notificationDate,
      title: count == 1
          ? '${products.single.name} scade tra $daysBefore ${daysBefore == 1 ? 'giorno' : 'giorni'}'
          : '$count prodotti scadono tra $daysBefore giorni',
      body: count == 1
          ? 'Scadenza ${_displayDate(expirationDate)}'
          : _productNames(products),
      payload: '$payloadPrefix${_isoDate(expirationDate)}',
    );
  }

  String _expiryBody(Product product) {
    if (product.category == ProductCategory.medicines) {
      return 'Controlla la scadenza. FreshTrack non sostituisce il parere di un medico o di un farmacista.';
    }
    return 'Usalo o consumalo oggi per evitare sprechi.';
  }

  String _productNames(List<Product> products) {
    final names = products.take(3).map((product) => product.name).join(', ');
    final remaining = products.length - 3;
    return remaining > 0 ? '$names e altri $remaining' : names;
  }

  bool _isFutureSchedule(CivilDate date, DateTime now, int hour, int minute) {
    final dateComparison = date.compareTo(CivilDate.fromDateTime(now));
    if (dateComparison != 0) return dateComparison > 0;
    final scheduledMinute = hour.clamp(0, 23) * 60 + minute.clamp(0, 59);
    return scheduledMinute > now.hour * 60 + now.minute;
  }

  String _isoDate(CivilDate date) => date.toIso8601String();

  String _displayDate(CivilDate date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
