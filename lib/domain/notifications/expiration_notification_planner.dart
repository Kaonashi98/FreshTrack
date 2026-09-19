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
    String languageCode = 'it',
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
            _expiryPlan(entry.key, entry.value, languageCode),
          for (final entry in advanceGroups.entries)
            _advancePlan(entry.key, entry.value, languageCode),
        ]..sort((first, second) {
          final dateComparison = first.date.compareTo(second.date);
          return dateComparison != 0
              ? dateComparison
              : first.id.compareTo(second.id);
        });
    return plans;
  }

  /// Plans whose civil date is today and whose configured time has already
  /// passed. Used to recover reminders that Android delayed or dropped.
  List<ExpirationNotificationPlan> missedToday(
    List<Product> products, {
    required DateTime now,
    int notificationHour = defaultNotificationHour,
    int notificationMinute = defaultNotificationMinute,
    int daysBefore = 0,
    String languageCode = 'it',
  }) {
    final today = CivilDate.fromDateTime(now);
    if (_isFutureSchedule(today, now, notificationHour, notificationMinute)) {
      return const [];
    }

    final expiryGroups = <CivilDate, List<Product>>{};
    final advanceGroups = <(CivilDate, CivilDate, int), List<Product>>{};
    final advanceDays = daysBefore.clamp(0, 30);

    for (final product in products) {
      final expirationDate = product.expirationDate;
      if (product.status != ProductStatus.available) continue;

      if (expirationDate == today) {
        expiryGroups.putIfAbsent(expirationDate, () => []).add(product);
      }

      if (advanceDays == 0) continue;
      final notificationDate = expirationDate.subtractDays(advanceDays);
      if (notificationDate != today || !expirationDate.isAfter(today)) {
        continue;
      }
      final key = (notificationDate, expirationDate, advanceDays);
      advanceGroups.putIfAbsent(key, () => []).add(product);
    }

    return [
      for (final entry in expiryGroups.entries)
        _expiryPlan(entry.key, entry.value, languageCode),
      for (final entry in advanceGroups.entries)
        _advancePlan(entry.key, entry.value, languageCode),
    ];
  }

  CivilDate? dateFromPayload(String? payload) {
    if (payload == null || !payload.startsWith(payloadPrefix)) return null;
    return CivilDate.tryParse(payload.substring(payloadPrefix.length));
  }

  ExpirationNotificationPlan _expiryPlan(
    CivilDate expirationDate,
    List<Product> products,
    String languageCode,
  ) {
    final count = products.length;
    final english = languageCode != 'it';
    return ExpirationNotificationPlan(
      id:
          expirationDate.year * 10000 +
          expirationDate.month * 100 +
          expirationDate.day,
      date: expirationDate,
      title: count == 1
          ? english
                ? '${products.single.name} expires today'
                : '${products.single.name} scade oggi'
          : english
          ? '$count products expire today'
          : '$count prodotti scadono oggi',
      body: count == 1
          ? _expiryBody(products.single, english)
          : _productNames(products, english),
      payload: '$payloadPrefix${_isoDate(expirationDate)}',
    );
  }

  ExpirationNotificationPlan _advancePlan(
    (CivilDate, CivilDate, int) key,
    List<Product> products,
    String languageCode,
  ) {
    final (notificationDate, expirationDate, daysBefore) = key;
    final count = products.length;
    final english = languageCode != 'it';
    return ExpirationNotificationPlan(
      // The negative namespace cannot collide with positive expiry IDs.
      // One pre-alert per expiration date is active for the global setting.
      id:
          -(expirationDate.year * 10000 +
              expirationDate.month * 100 +
              expirationDate.day),
      date: notificationDate,
      title: count == 1
          ? english
                ? '${products.single.name} expires in $daysBefore ${daysBefore == 1 ? 'day' : 'days'}'
                : '${products.single.name} scade tra $daysBefore ${daysBefore == 1 ? 'giorno' : 'giorni'}'
          : english
          ? '$count products expire in $daysBefore days'
          : '$count prodotti scadono tra $daysBefore giorni',
      body: count == 1
          ? english
                ? 'Expiration date ${_displayDate(expirationDate, true)}'
                : 'Scadenza ${_displayDate(expirationDate, false)}'
          : _productNames(products, english),
      payload: '$payloadPrefix${_isoDate(expirationDate)}',
    );
  }

  String _expiryBody(Product product, bool english) {
    if (product.category == ProductCategory.medicines) {
      return english
          ? 'Check the expiration date. FreshTrack is not a medical device: consult a healthcare professional for advice or treatment.'
          : 'Controlla la scadenza. FreshTrack non è un dispositivo medico: per pareri o trattamenti consulta un professionista sanitario.';
    }
    return english
        ? 'Use or consume it today to avoid waste.'
        : 'Usalo o consumalo oggi per evitare sprechi.';
  }

  String _productNames(List<Product> products, bool english) {
    final names = products.take(3).map((product) => product.name).join(', ');
    final remaining = products.length - 3;
    return remaining > 0
        ? english
              ? '$names and $remaining more'
              : '$names e altri $remaining'
        : names;
  }

  bool _isFutureSchedule(CivilDate date, DateTime now, int hour, int minute) {
    final dateComparison = date.compareTo(CivilDate.fromDateTime(now));
    if (dateComparison != 0) return dateComparison > 0;
    final scheduledMinute = hour.clamp(0, 23) * 60 + minute.clamp(0, 59);
    return scheduledMinute > now.hour * 60 + now.minute;
  }

  String _isoDate(CivilDate date) => date.toIso8601String();

  String _displayDate(CivilDate date, bool english) => english
      ? '${date.month.toString().padLeft(2, '0')}/'
            '${date.day.toString().padLeft(2, '0')}/${date.year}'
      : '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/${date.year}';
}
