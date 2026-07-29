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
  final DateTime date;
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
  }) {
    final expiryGroups = <DateTime, List<Product>>{};
    final advanceGroups = <(DateTime, DateTime, int), List<Product>>{};

    for (final product in products) {
      final expirationDate = _dateOnly(product.expirationDate);
      if (product.status != ProductStatus.available ||
          expirationDate.isBefore(_dateOnly(now))) {
        continue;
      }
      if (_scheduledAt(
        expirationDate,
        notificationHour,
        notificationMinute,
      ).isAfter(now)) {
        expiryGroups.putIfAbsent(expirationDate, () => []).add(product);
      }

      final daysBefore = product.notificationDaysBefore.clamp(0, 30);
      if (daysBefore == 0) continue;
      final notificationDate = expirationDate.subtract(
        Duration(days: daysBefore),
      );
      if (!_scheduledAt(
        notificationDate,
        notificationHour,
        notificationMinute,
      ).isAfter(now)) {
        continue;
      }
      final key = (notificationDate, expirationDate, daysBefore);
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

  DateTime? dateFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(payloadPrefix)) return null;
    return DateTime.tryParse(payload.substring(payloadPrefix.length));
  }

  ExpirationNotificationPlan _expiryPlan(
    DateTime expirationDate,
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
      body: count == 1
          ? 'Consumalo oggi per evitare sprechi.'
          : _productNames(products),
      payload: '$payloadPrefix${_isoDate(expirationDate)}',
    );
  }

  ExpirationNotificationPlan _advancePlan(
    (DateTime, DateTime, int) key,
    List<Product> products,
  ) {
    final (notificationDate, expirationDate, daysBefore) = key;
    final count = products.length;
    return ExpirationNotificationPlan(
      id: _stableId(
        'advance:${_isoDate(notificationDate)}:${_isoDate(expirationDate)}:$daysBefore',
      ),
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

  String _productNames(List<Product> products) {
    final names = products.take(3).map((product) => product.name).join(', ');
    final remaining = products.length - 3;
    return remaining > 0 ? '$names e altri $remaining' : names;
  }

  int _stableId(String value) {
    var hash = 17;
    for (final codeUnit in value.codeUnits) {
      hash = (hash * 31 + codeUnit) & 0x7fffffff;
    }
    return hash;
  }

  DateTime _scheduledAt(DateTime date, int hour, int minute) => DateTime(
    date.year,
    date.month,
    date.day,
    hour.clamp(0, 23),
    minute.clamp(0, 59),
  );

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _isoDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
