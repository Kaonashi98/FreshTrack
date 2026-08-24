import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 160)();
  TextColumn get description => text().nullable()();
  IntColumn get category => integer()();
  RealColumn get quantity => real()();
  IntColumn get unit => integer()();
  DateTimeColumn get purchaseDate => dateTime()();
  DateTimeColumn get expirationDate => dateTime()();
  TextColumn get purchaseDateCivil =>
      text().withDefault(const Constant('1970-01-01'))();
  TextColumn get expirationDateCivil =>
      text().withDefault(const Constant('1970-01-01'))();
  TextColumn get imagePath => text().nullable()();
  // Colonna legacy mantenuta per aprire senza perdita i database già creati.
  TextColumn get barcode => text().nullable()();
  IntColumn get status => integer()();
  TextColumn get categoryCode => text().withDefault(const Constant('food'))();
  TextColumn get unitCode => text().withDefault(const Constant('pieces'))();
  TextColumn get statusCode =>
      text().withDefault(const Constant('available'))();
  IntColumn get notificationDaysBefore =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Products])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);
  AppDatabase.open()
    : super(
        driftDatabase(
          name: 'freshtrack',
          native: const DriftNativeOptions(shareAcrossIsolates: true),
        ),
      );

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 3) {
        await migrator.addColumn(products, products.purchaseDateCivil);
        await migrator.addColumn(products, products.expirationDateCivil);
        await migrator.addColumn(products, products.categoryCode);
        await migrator.addColumn(products, products.unitCode);
        await migrator.addColumn(products, products.statusCode);

        // The v1/v2 schema stored selected calendar dates as instants. During
        // upgrade we capture the same local calendar components users saw and
        // thereafter the canonical YYYY-MM-DD values are time-zone independent.
        await customStatement('''
          UPDATE products
          SET purchase_date_civil = strftime('%Y-%m-%d', purchase_date, 'unixepoch', 'localtime'),
              expiration_date_civil = strftime('%Y-%m-%d', expiration_date, 'unixepoch', 'localtime'),
              category_code = CASE category
                WHEN 0 THEN 'food' WHEN 1 THEN 'beverages'
                WHEN 2 THEN 'medicines' WHEN 3 THEN 'personalCare'
                WHEN 4 THEN 'cleaning' WHEN 5 THEN 'other' ELSE 'other' END,
              unit_code = CASE unit
                WHEN 0 THEN 'pieces' WHEN 1 THEN 'grams'
                WHEN 2 THEN 'kilograms' WHEN 3 THEN 'milliliters'
                WHEN 4 THEN 'liters' WHEN 5 THEN 'packs' ELSE 'pieces' END,
              status_code = CASE status
                WHEN 0 THEN 'available' WHEN 1 THEN 'consumed'
                WHEN 2 THEN 'expired' WHEN 3 THEN 'discarded' ELSE 'available' END
        ''');
      }
    },
  );
}
