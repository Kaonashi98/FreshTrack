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

const selectableProductCategories = [
  ProductCategory.food,
  ProductCategory.medicines,
];

enum ProductStatus {
  available('Disponibile'),
  consumed('Consumato'),
  expired('Scaduto'),
  discarded('Buttato');

  const ProductStatus(this.label);
  final String label;
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

const selectableMeasurementUnits = [
  MeasurementUnit.pieces,
  MeasurementUnit.grams,
  MeasurementUnit.kilograms,
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
  });

  final String id;
  final String name;
  final String? description;
  final ProductCategory category;
  final double quantity;
  final MeasurementUnit unit;
  final DateTime purchaseDate;
  final DateTime expirationDate;
  final String? imagePath;
  final ProductStatus status;
  final int notificationDaysBefore;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product copyWith({
    String? id,
    String? name,
    Object? description = _unsetProductField,
    ProductCategory? category,
    double? quantity,
    MeasurementUnit? unit,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    Object? imagePath = _unsetProductField,
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
    status: status ?? this.status,
    notificationDaysBefore:
        notificationDaysBefore ?? this.notificationDaysBefore,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
