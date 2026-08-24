// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProductsTable extends Products with TableInfo<$ProductsTable, Product> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<int> category = GeneratedColumn<int>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<int> unit = GeneratedColumn<int>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _purchaseDateMeta = const VerificationMeta(
    'purchaseDate',
  );
  @override
  late final GeneratedColumn<DateTime> purchaseDate = GeneratedColumn<DateTime>(
    'purchase_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _expirationDateMeta = const VerificationMeta(
    'expirationDate',
  );
  @override
  late final GeneratedColumn<DateTime> expirationDate =
      GeneratedColumn<DateTime>(
        'expiration_date',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _purchaseDateCivilMeta = const VerificationMeta(
    'purchaseDateCivil',
  );
  @override
  late final GeneratedColumn<String> purchaseDateCivil =
      GeneratedColumn<String>(
        'purchase_date_civil',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('1970-01-01'),
      );
  static const VerificationMeta _expirationDateCivilMeta =
      const VerificationMeta('expirationDateCivil');
  @override
  late final GeneratedColumn<String> expirationDateCivil =
      GeneratedColumn<String>(
        'expiration_date_civil',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('1970-01-01'),
      );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  @override
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<int> status = GeneratedColumn<int>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryCodeMeta = const VerificationMeta(
    'categoryCode',
  );
  @override
  late final GeneratedColumn<String> categoryCode = GeneratedColumn<String>(
    'category_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('food'),
  );
  static const VerificationMeta _unitCodeMeta = const VerificationMeta(
    'unitCode',
  );
  @override
  late final GeneratedColumn<String> unitCode = GeneratedColumn<String>(
    'unit_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pieces'),
  );
  static const VerificationMeta _statusCodeMeta = const VerificationMeta(
    'statusCode',
  );
  @override
  late final GeneratedColumn<String> statusCode = GeneratedColumn<String>(
    'status_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('available'),
  );
  static const VerificationMeta _notificationDaysBeforeMeta =
      const VerificationMeta('notificationDaysBefore');
  @override
  late final GeneratedColumn<int> notificationDaysBefore = GeneratedColumn<int>(
    'notification_days_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    category,
    quantity,
    unit,
    purchaseDate,
    expirationDate,
    purchaseDateCivil,
    expirationDateCivil,
    imagePath,
    barcode,
    status,
    categoryCode,
    unitCode,
    statusCode,
    notificationDaysBefore,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'products';
  @override
  VerificationContext validateIntegrity(
    Insertable<Product> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('purchase_date')) {
      context.handle(
        _purchaseDateMeta,
        purchaseDate.isAcceptableOrUnknown(
          data['purchase_date']!,
          _purchaseDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_purchaseDateMeta);
    }
    if (data.containsKey('expiration_date')) {
      context.handle(
        _expirationDateMeta,
        expirationDate.isAcceptableOrUnknown(
          data['expiration_date']!,
          _expirationDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_expirationDateMeta);
    }
    if (data.containsKey('purchase_date_civil')) {
      context.handle(
        _purchaseDateCivilMeta,
        purchaseDateCivil.isAcceptableOrUnknown(
          data['purchase_date_civil']!,
          _purchaseDateCivilMeta,
        ),
      );
    }
    if (data.containsKey('expiration_date_civil')) {
      context.handle(
        _expirationDateCivilMeta,
        expirationDateCivil.isAcceptableOrUnknown(
          data['expiration_date_civil']!,
          _expirationDateCivilMeta,
        ),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('category_code')) {
      context.handle(
        _categoryCodeMeta,
        categoryCode.isAcceptableOrUnknown(
          data['category_code']!,
          _categoryCodeMeta,
        ),
      );
    }
    if (data.containsKey('unit_code')) {
      context.handle(
        _unitCodeMeta,
        unitCode.isAcceptableOrUnknown(data['unit_code']!, _unitCodeMeta),
      );
    }
    if (data.containsKey('status_code')) {
      context.handle(
        _statusCodeMeta,
        statusCode.isAcceptableOrUnknown(data['status_code']!, _statusCodeMeta),
      );
    }
    if (data.containsKey('notification_days_before')) {
      context.handle(
        _notificationDaysBeforeMeta,
        notificationDaysBefore.isAcceptableOrUnknown(
          data['notification_days_before']!,
          _notificationDaysBeforeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Product map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Product(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit'],
      )!,
      purchaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}purchase_date'],
      )!,
      expirationDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}expiration_date'],
      )!,
      purchaseDateCivil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}purchase_date_civil'],
      )!,
      expirationDateCivil: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}expiration_date_civil'],
      )!,
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status'],
      )!,
      categoryCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_code'],
      )!,
      unitCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit_code'],
      )!,
      statusCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status_code'],
      )!,
      notificationDaysBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}notification_days_before'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProductsTable createAlias(String alias) {
    return $ProductsTable(attachedDatabase, alias);
  }
}

class Product extends DataClass implements Insertable<Product> {
  final String id;
  final String name;
  final String? description;
  final int category;
  final double quantity;
  final int unit;
  final DateTime purchaseDate;
  final DateTime expirationDate;
  final String purchaseDateCivil;
  final String expirationDateCivil;
  final String? imagePath;
  final String? barcode;
  final int status;
  final String categoryCode;
  final String unitCode;
  final String statusCode;
  final int notificationDaysBefore;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Product({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.purchaseDate,
    required this.expirationDate,
    required this.purchaseDateCivil,
    required this.expirationDateCivil,
    this.imagePath,
    this.barcode,
    required this.status,
    required this.categoryCode,
    required this.unitCode,
    required this.statusCode,
    required this.notificationDaysBefore,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['category'] = Variable<int>(category);
    map['quantity'] = Variable<double>(quantity);
    map['unit'] = Variable<int>(unit);
    map['purchase_date'] = Variable<DateTime>(purchaseDate);
    map['expiration_date'] = Variable<DateTime>(expirationDate);
    map['purchase_date_civil'] = Variable<String>(purchaseDateCivil);
    map['expiration_date_civil'] = Variable<String>(expirationDateCivil);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    map['status'] = Variable<int>(status);
    map['category_code'] = Variable<String>(categoryCode);
    map['unit_code'] = Variable<String>(unitCode);
    map['status_code'] = Variable<String>(statusCode);
    map['notification_days_before'] = Variable<int>(notificationDaysBefore);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProductsCompanion toCompanion(bool nullToAbsent) {
    return ProductsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: Value(category),
      quantity: Value(quantity),
      unit: Value(unit),
      purchaseDate: Value(purchaseDate),
      expirationDate: Value(expirationDate),
      purchaseDateCivil: Value(purchaseDateCivil),
      expirationDateCivil: Value(expirationDateCivil),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      status: Value(status),
      categoryCode: Value(categoryCode),
      unitCode: Value(unitCode),
      statusCode: Value(statusCode),
      notificationDaysBefore: Value(notificationDaysBefore),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Product.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Product(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<int>(json['category']),
      quantity: serializer.fromJson<double>(json['quantity']),
      unit: serializer.fromJson<int>(json['unit']),
      purchaseDate: serializer.fromJson<DateTime>(json['purchaseDate']),
      expirationDate: serializer.fromJson<DateTime>(json['expirationDate']),
      purchaseDateCivil: serializer.fromJson<String>(json['purchaseDateCivil']),
      expirationDateCivil: serializer.fromJson<String>(
        json['expirationDateCivil'],
      ),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      status: serializer.fromJson<int>(json['status']),
      categoryCode: serializer.fromJson<String>(json['categoryCode']),
      unitCode: serializer.fromJson<String>(json['unitCode']),
      statusCode: serializer.fromJson<String>(json['statusCode']),
      notificationDaysBefore: serializer.fromJson<int>(
        json['notificationDaysBefore'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<int>(category),
      'quantity': serializer.toJson<double>(quantity),
      'unit': serializer.toJson<int>(unit),
      'purchaseDate': serializer.toJson<DateTime>(purchaseDate),
      'expirationDate': serializer.toJson<DateTime>(expirationDate),
      'purchaseDateCivil': serializer.toJson<String>(purchaseDateCivil),
      'expirationDateCivil': serializer.toJson<String>(expirationDateCivil),
      'imagePath': serializer.toJson<String?>(imagePath),
      'barcode': serializer.toJson<String?>(barcode),
      'status': serializer.toJson<int>(status),
      'categoryCode': serializer.toJson<String>(categoryCode),
      'unitCode': serializer.toJson<String>(unitCode),
      'statusCode': serializer.toJson<String>(statusCode),
      'notificationDaysBefore': serializer.toJson<int>(notificationDaysBefore),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    int? category,
    double? quantity,
    int? unit,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    String? purchaseDateCivil,
    String? expirationDateCivil,
    Value<String?> imagePath = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    int? status,
    String? categoryCode,
    String? unitCode,
    String? statusCode,
    int? notificationDaysBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Product(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    category: category ?? this.category,
    quantity: quantity ?? this.quantity,
    unit: unit ?? this.unit,
    purchaseDate: purchaseDate ?? this.purchaseDate,
    expirationDate: expirationDate ?? this.expirationDate,
    purchaseDateCivil: purchaseDateCivil ?? this.purchaseDateCivil,
    expirationDateCivil: expirationDateCivil ?? this.expirationDateCivil,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    barcode: barcode.present ? barcode.value : this.barcode,
    status: status ?? this.status,
    categoryCode: categoryCode ?? this.categoryCode,
    unitCode: unitCode ?? this.unitCode,
    statusCode: statusCode ?? this.statusCode,
    notificationDaysBefore:
        notificationDaysBefore ?? this.notificationDaysBefore,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Product copyWithCompanion(ProductsCompanion data) {
    return Product(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      unit: data.unit.present ? data.unit.value : this.unit,
      purchaseDate: data.purchaseDate.present
          ? data.purchaseDate.value
          : this.purchaseDate,
      expirationDate: data.expirationDate.present
          ? data.expirationDate.value
          : this.expirationDate,
      purchaseDateCivil: data.purchaseDateCivil.present
          ? data.purchaseDateCivil.value
          : this.purchaseDateCivil,
      expirationDateCivil: data.expirationDateCivil.present
          ? data.expirationDateCivil.value
          : this.expirationDateCivil,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      status: data.status.present ? data.status.value : this.status,
      categoryCode: data.categoryCode.present
          ? data.categoryCode.value
          : this.categoryCode,
      unitCode: data.unitCode.present ? data.unitCode.value : this.unitCode,
      statusCode: data.statusCode.present
          ? data.statusCode.value
          : this.statusCode,
      notificationDaysBefore: data.notificationDaysBefore.present
          ? data.notificationDaysBefore.value
          : this.notificationDaysBefore,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Product(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('expirationDate: $expirationDate, ')
          ..write('purchaseDateCivil: $purchaseDateCivil, ')
          ..write('expirationDateCivil: $expirationDateCivil, ')
          ..write('imagePath: $imagePath, ')
          ..write('barcode: $barcode, ')
          ..write('status: $status, ')
          ..write('categoryCode: $categoryCode, ')
          ..write('unitCode: $unitCode, ')
          ..write('statusCode: $statusCode, ')
          ..write('notificationDaysBefore: $notificationDaysBefore, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    category,
    quantity,
    unit,
    purchaseDate,
    expirationDate,
    purchaseDateCivil,
    expirationDateCivil,
    imagePath,
    barcode,
    status,
    categoryCode,
    unitCode,
    statusCode,
    notificationDaysBefore,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Product &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.category == this.category &&
          other.quantity == this.quantity &&
          other.unit == this.unit &&
          other.purchaseDate == this.purchaseDate &&
          other.expirationDate == this.expirationDate &&
          other.purchaseDateCivil == this.purchaseDateCivil &&
          other.expirationDateCivil == this.expirationDateCivil &&
          other.imagePath == this.imagePath &&
          other.barcode == this.barcode &&
          other.status == this.status &&
          other.categoryCode == this.categoryCode &&
          other.unitCode == this.unitCode &&
          other.statusCode == this.statusCode &&
          other.notificationDaysBefore == this.notificationDaysBefore &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProductsCompanion extends UpdateCompanion<Product> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> category;
  final Value<double> quantity;
  final Value<int> unit;
  final Value<DateTime> purchaseDate;
  final Value<DateTime> expirationDate;
  final Value<String> purchaseDateCivil;
  final Value<String> expirationDateCivil;
  final Value<String?> imagePath;
  final Value<String?> barcode;
  final Value<int> status;
  final Value<String> categoryCode;
  final Value<String> unitCode;
  final Value<String> statusCode;
  final Value<int> notificationDaysBefore;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProductsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.quantity = const Value.absent(),
    this.unit = const Value.absent(),
    this.purchaseDate = const Value.absent(),
    this.expirationDate = const Value.absent(),
    this.purchaseDateCivil = const Value.absent(),
    this.expirationDateCivil = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.barcode = const Value.absent(),
    this.status = const Value.absent(),
    this.categoryCode = const Value.absent(),
    this.unitCode = const Value.absent(),
    this.statusCode = const Value.absent(),
    this.notificationDaysBefore = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProductsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    required int category,
    required double quantity,
    required int unit,
    required DateTime purchaseDate,
    required DateTime expirationDate,
    this.purchaseDateCivil = const Value.absent(),
    this.expirationDateCivil = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.barcode = const Value.absent(),
    required int status,
    this.categoryCode = const Value.absent(),
    this.unitCode = const Value.absent(),
    this.statusCode = const Value.absent(),
    this.notificationDaysBefore = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       category = Value(category),
       quantity = Value(quantity),
       unit = Value(unit),
       purchaseDate = Value(purchaseDate),
       expirationDate = Value(expirationDate),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Product> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? category,
    Expression<double>? quantity,
    Expression<int>? unit,
    Expression<DateTime>? purchaseDate,
    Expression<DateTime>? expirationDate,
    Expression<String>? purchaseDateCivil,
    Expression<String>? expirationDateCivil,
    Expression<String>? imagePath,
    Expression<String>? barcode,
    Expression<int>? status,
    Expression<String>? categoryCode,
    Expression<String>? unitCode,
    Expression<String>? statusCode,
    Expression<int>? notificationDaysBefore,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (quantity != null) 'quantity': quantity,
      if (unit != null) 'unit': unit,
      if (purchaseDate != null) 'purchase_date': purchaseDate,
      if (expirationDate != null) 'expiration_date': expirationDate,
      if (purchaseDateCivil != null) 'purchase_date_civil': purchaseDateCivil,
      if (expirationDateCivil != null)
        'expiration_date_civil': expirationDateCivil,
      if (imagePath != null) 'image_path': imagePath,
      if (barcode != null) 'barcode': barcode,
      if (status != null) 'status': status,
      if (categoryCode != null) 'category_code': categoryCode,
      if (unitCode != null) 'unit_code': unitCode,
      if (statusCode != null) 'status_code': statusCode,
      if (notificationDaysBefore != null)
        'notification_days_before': notificationDaysBefore,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProductsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? category,
    Value<double>? quantity,
    Value<int>? unit,
    Value<DateTime>? purchaseDate,
    Value<DateTime>? expirationDate,
    Value<String>? purchaseDateCivil,
    Value<String>? expirationDateCivil,
    Value<String?>? imagePath,
    Value<String?>? barcode,
    Value<int>? status,
    Value<String>? categoryCode,
    Value<String>? unitCode,
    Value<String>? statusCode,
    Value<int>? notificationDaysBefore,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProductsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      expirationDate: expirationDate ?? this.expirationDate,
      purchaseDateCivil: purchaseDateCivil ?? this.purchaseDateCivil,
      expirationDateCivil: expirationDateCivil ?? this.expirationDateCivil,
      imagePath: imagePath ?? this.imagePath,
      barcode: barcode ?? this.barcode,
      status: status ?? this.status,
      categoryCode: categoryCode ?? this.categoryCode,
      unitCode: unitCode ?? this.unitCode,
      statusCode: statusCode ?? this.statusCode,
      notificationDaysBefore:
          notificationDaysBefore ?? this.notificationDaysBefore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<int>(category.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (unit.present) {
      map['unit'] = Variable<int>(unit.value);
    }
    if (purchaseDate.present) {
      map['purchase_date'] = Variable<DateTime>(purchaseDate.value);
    }
    if (expirationDate.present) {
      map['expiration_date'] = Variable<DateTime>(expirationDate.value);
    }
    if (purchaseDateCivil.present) {
      map['purchase_date_civil'] = Variable<String>(purchaseDateCivil.value);
    }
    if (expirationDateCivil.present) {
      map['expiration_date_civil'] = Variable<String>(
        expirationDateCivil.value,
      );
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (status.present) {
      map['status'] = Variable<int>(status.value);
    }
    if (categoryCode.present) {
      map['category_code'] = Variable<String>(categoryCode.value);
    }
    if (unitCode.present) {
      map['unit_code'] = Variable<String>(unitCode.value);
    }
    if (statusCode.present) {
      map['status_code'] = Variable<String>(statusCode.value);
    }
    if (notificationDaysBefore.present) {
      map['notification_days_before'] = Variable<int>(
        notificationDaysBefore.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('quantity: $quantity, ')
          ..write('unit: $unit, ')
          ..write('purchaseDate: $purchaseDate, ')
          ..write('expirationDate: $expirationDate, ')
          ..write('purchaseDateCivil: $purchaseDateCivil, ')
          ..write('expirationDateCivil: $expirationDateCivil, ')
          ..write('imagePath: $imagePath, ')
          ..write('barcode: $barcode, ')
          ..write('status: $status, ')
          ..write('categoryCode: $categoryCode, ')
          ..write('unitCode: $unitCode, ')
          ..write('statusCode: $statusCode, ')
          ..write('notificationDaysBefore: $notificationDaysBefore, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProductsTable products = $ProductsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [products];
}

typedef $$ProductsTableCreateCompanionBuilder =
    ProductsCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      required int category,
      required double quantity,
      required int unit,
      required DateTime purchaseDate,
      required DateTime expirationDate,
      Value<String> purchaseDateCivil,
      Value<String> expirationDateCivil,
      Value<String?> imagePath,
      Value<String?> barcode,
      required int status,
      Value<String> categoryCode,
      Value<String> unitCode,
      Value<String> statusCode,
      Value<int> notificationDaysBefore,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProductsTableUpdateCompanionBuilder =
    ProductsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<int> category,
      Value<double> quantity,
      Value<int> unit,
      Value<DateTime> purchaseDate,
      Value<DateTime> expirationDate,
      Value<String> purchaseDateCivil,
      Value<String> expirationDateCivil,
      Value<String?> imagePath,
      Value<String?> barcode,
      Value<int> status,
      Value<String> categoryCode,
      Value<String> unitCode,
      Value<String> statusCode,
      Value<int> notificationDaysBefore,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProductsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get expirationDate => $composableBuilder(
    column: $table.expirationDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get purchaseDateCivil => $composableBuilder(
    column: $table.purchaseDateCivil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get expirationDateCivil => $composableBuilder(
    column: $table.expirationDateCivil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unitCode => $composableBuilder(
    column: $table.unitCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statusCode => $composableBuilder(
    column: $table.statusCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get notificationDaysBefore => $composableBuilder(
    column: $table.notificationDaysBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProductsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get expirationDate => $composableBuilder(
    column: $table.expirationDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get purchaseDateCivil => $composableBuilder(
    column: $table.purchaseDateCivil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get expirationDateCivil => $composableBuilder(
    column: $table.expirationDateCivil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unitCode => $composableBuilder(
    column: $table.unitCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statusCode => $composableBuilder(
    column: $table.statusCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get notificationDaysBefore => $composableBuilder(
    column: $table.notificationDaysBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProductsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductsTable> {
  $$ProductsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get purchaseDate => $composableBuilder(
    column: $table.purchaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get expirationDate => $composableBuilder(
    column: $table.expirationDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get purchaseDateCivil => $composableBuilder(
    column: $table.purchaseDateCivil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get expirationDateCivil => $composableBuilder(
    column: $table.expirationDateCivil,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<int> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get categoryCode => $composableBuilder(
    column: $table.categoryCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unitCode =>
      $composableBuilder(column: $table.unitCode, builder: (column) => column);

  GeneratedColumn<String> get statusCode => $composableBuilder(
    column: $table.statusCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get notificationDaysBefore => $composableBuilder(
    column: $table.notificationDaysBefore,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProductsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProductsTable,
          Product,
          $$ProductsTableFilterComposer,
          $$ProductsTableOrderingComposer,
          $$ProductsTableAnnotationComposer,
          $$ProductsTableCreateCompanionBuilder,
          $$ProductsTableUpdateCompanionBuilder,
          (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
          Product,
          PrefetchHooks Function()
        > {
  $$ProductsTableTableManager(_$AppDatabase db, $ProductsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> category = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<int> unit = const Value.absent(),
                Value<DateTime> purchaseDate = const Value.absent(),
                Value<DateTime> expirationDate = const Value.absent(),
                Value<String> purchaseDateCivil = const Value.absent(),
                Value<String> expirationDateCivil = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<int> status = const Value.absent(),
                Value<String> categoryCode = const Value.absent(),
                Value<String> unitCode = const Value.absent(),
                Value<String> statusCode = const Value.absent(),
                Value<int> notificationDaysBefore = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion(
                id: id,
                name: name,
                description: description,
                category: category,
                quantity: quantity,
                unit: unit,
                purchaseDate: purchaseDate,
                expirationDate: expirationDate,
                purchaseDateCivil: purchaseDateCivil,
                expirationDateCivil: expirationDateCivil,
                imagePath: imagePath,
                barcode: barcode,
                status: status,
                categoryCode: categoryCode,
                unitCode: unitCode,
                statusCode: statusCode,
                notificationDaysBefore: notificationDaysBefore,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                required int category,
                required double quantity,
                required int unit,
                required DateTime purchaseDate,
                required DateTime expirationDate,
                Value<String> purchaseDateCivil = const Value.absent(),
                Value<String> expirationDateCivil = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                required int status,
                Value<String> categoryCode = const Value.absent(),
                Value<String> unitCode = const Value.absent(),
                Value<String> statusCode = const Value.absent(),
                Value<int> notificationDaysBefore = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProductsCompanion.insert(
                id: id,
                name: name,
                description: description,
                category: category,
                quantity: quantity,
                unit: unit,
                purchaseDate: purchaseDate,
                expirationDate: expirationDate,
                purchaseDateCivil: purchaseDateCivil,
                expirationDateCivil: expirationDateCivil,
                imagePath: imagePath,
                barcode: barcode,
                status: status,
                categoryCode: categoryCode,
                unitCode: unitCode,
                statusCode: statusCode,
                notificationDaysBefore: notificationDaysBefore,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProductsTable,
      Product,
      $$ProductsTableFilterComposer,
      $$ProductsTableOrderingComposer,
      $$ProductsTableAnnotationComposer,
      $$ProductsTableCreateCompanionBuilder,
      $$ProductsTableUpdateCompanionBuilder,
      (Product, BaseReferences<_$AppDatabase, $ProductsTable, Product>),
      Product,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db, _db.products);
}
