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
  TextColumn get imagePath => text().nullable()();
  // Colonna legacy mantenuta per aprire senza perdita i database già creati.
  TextColumn get barcode => text().nullable()();
  IntColumn get status => integer()();
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await (update(products)
              ..where((product) => product.notificationDaysBefore.equals(3)))
            .write(const ProductsCompanion(notificationDaysBefore: Value(0)));
      }
    },
  );
}
