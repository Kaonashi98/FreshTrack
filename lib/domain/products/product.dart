import 'package:freshtrack/domain/common/civil_date.dart';

const maxProductNameLength = 160;
const maxProductDescriptionLength = 1000;
const maxProductQuantity = 1000000000.0;
const minProductBarcodeLength = 8;
const maxProductBarcodeLength = 14;

enum ProductCategory {
  food('Alimentari'),
  beverages('Bevande'),
  medicines('Farmaci'),
  personalCare('Cura personale'),
  cleaning('Pulizia'),
  other('Altro');

  const ProductCategory(this.label);
  final String label;
}

extension ProductCategoryLocalization on ProductCategory {
  String localizedLabel(String languageCode) => languageCode == 'it'
      ? label
      : switch (this) {
          ProductCategory.food => 'Food',
          ProductCategory.beverages => 'Beverages',
          ProductCategory.medicines => 'Medicines',
          ProductCategory.personalCare => 'Personal care',
          ProductCategory.cleaning => 'Cleaning',
          ProductCategory.other => 'Other',
        };
}

const selectableProductCategories = [
  ProductCategory.food,
  ProductCategory.beverages,
  ProductCategory.medicines,
  ProductCategory.personalCare,
];

enum ProductStatus {
  available('Disponibile'),
  consumed('Consumato'),
  expired('Scaduto'),
  discarded('Buttato');

  const ProductStatus(this.label);
  final String label;
}

extension ProductStatusLocalization on ProductStatus {
  String localizedLabel(String languageCode) => languageCode == 'it'
      ? label
      : switch (this) {
          ProductStatus.available => 'Available',
          ProductStatus.consumed => 'Consumed',
          ProductStatus.expired => 'Expired',
          ProductStatus.discarded => 'Discarded',
        };
}

enum MeasurementUnit {
  pieces('pz'),
  grams('g'),
  kilograms('kg'),
  milliliters('ml'),
  liters('l'),
  packs('confezioni');

  const MeasurementUnit(this.label);
  final String label;
}

extension MeasurementUnitLocalization on MeasurementUnit {
  String localizedLabel(String languageCode) => languageCode == 'it'
      ? label
      : switch (this) {
          MeasurementUnit.pieces => 'pcs',
          MeasurementUnit.packs => 'packs',
          _ => label,
        };
}

const selectableMeasurementUnits = [
  MeasurementUnit.pieces,
  MeasurementUnit.grams,
  MeasurementUnit.kilograms,
  MeasurementUnit.milliliters,
  MeasurementUnit.liters,
  MeasurementUnit.packs,
];

const _unsetProductField = Object();

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.purchaseDate,
    required this.expirationDate,
    required this.status,
    required this.notificationDaysBefore,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.imagePath,
    this.barcode,
  });

  final String id;
  final String name;
  final String? description;
  final ProductCategory category;
  final double quantity;
  final MeasurementUnit unit;
  final CivilDate purchaseDate;
  final CivilDate expirationDate;
  final String? imagePath;
  final String? barcode;
  final ProductStatus status;
  final int notificationDaysBefore;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get quantityText => quantity == quantity.truncateToDouble()
      ? quantity.toInt().toString()
      : quantity.toString();

  bool get isConsumable =>
      category == ProductCategory.food || category == ProductCategory.beverages;

  String get statusLabel => status == ProductStatus.consumed && !isConsumable
      ? 'Utilizzato'
      : status.label;

  String localizedStatusLabel(String languageCode) {
    if (languageCode == 'it') return statusLabel;
    if (status == ProductStatus.consumed && !isConsumable) return 'Used';
    return status.localizedLabel(languageCode);
  }

  Product copyWith({
    String? id,
    String? name,
    Object? description = _unsetProductField,
    ProductCategory? category,
    double? quantity,
    MeasurementUnit? unit,
    CivilDate? purchaseDate,
    CivilDate? expirationDate,
    Object? imagePath = _unsetProductField,
    Object? barcode = _unsetProductField,
    ProductStatus? status,
    int? notificationDaysBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    description: identical(description, _unsetProductField)
        ? this.description
        : description as String?,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    expirationDate: expirationDate ?? this.expirationDate,
    imagePath: identical(imagePath, _unsetProductField)
        ? this.imagePath
        : imagePath as String?,
    barcode: identical(barcode, _unsetProductField)
        ? this.barcode
        : barcode as String?,
    status: status ?? this.status,
    notificationDaysBefore:
        notificationDaysBefore ?? this.notificationDaysBefore,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
