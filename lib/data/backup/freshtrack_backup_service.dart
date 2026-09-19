import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:freshtrack/data/media/product_image_storage.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/common/async_mutex.dart';
import 'package:freshtrack/domain/products/product_validation.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

enum BackupImportMode { merge, replace }

final class BackupPreview {
  const BackupPreview({
    required this.productCount,
    required this.imageCount,
    required this.exportedAt,
    required this.appVersion,
  });

  final int productCount;
  final int imageCount;
  final DateTime exportedAt;
  final String appVersion;
}

final class BackupRestoreResult {
  const BackupRestoreResult({
    required this.productCount,
    required this.imageCount,
  });

  final int productCount;
  final int imageCount;
}

class BackupFormatException implements Exception {
  const BackupFormatException(this.message);
  final String message;

  @override
  String toString() => message;
}

class FreshTrackBackupService {
  FreshTrackBackupService({
    required ProductRepository productRepository,
    required AppSettingsRepository settingsRepository,
    required ProductImageStorage imageStorage,
    Future<Directory> Function()? temporaryDirectoryProvider,
  }) : this._(
         productRepository,
         settingsRepository,
         imageStorage,
         temporaryDirectoryProvider ?? getTemporaryDirectory,
       );

  FreshTrackBackupService._(
    this._productRepository,
    this._settingsRepository,
    this._imageStorage,
    this._temporaryDirectoryProvider,
  );

  static const formatVersion = 1;
  static const maxBackupBytes = 250 * 1024 * 1024;
  // Accommodates 5000 products, including full Unicode descriptions.
  static const maxManifestBytes = 32 * 1024 * 1024;
  static const maxProducts = 5000;
  static const maxEntries = maxProducts + 1;

  final ProductRepository _productRepository;
  final AppSettingsRepository _settingsRepository;
  final ProductImageStorage _imageStorage;
  final Future<Directory> Function() _temporaryDirectoryProvider;

  Future<Uint8List> createBackup({required String appVersion}) =>
      mutationLockFor(_productRepository).run(() async {
        final products = await _productRepository.getAll();
        final settings = await _settingsRepository.load();
        return _encodeAsync(products, settings, appVersion);
      });

  static Future<Uint8List> _encodeAsync(
    List<Product> products,
    AppSettings settings,
    String appVersion,
  ) => Isolate.run(() => _encodeBackup(products, settings, appVersion));

  static Future<_ParsedBackup> _parseAsync(Uint8List bytes) =>
      Isolate.run(() => _parse(bytes));

  static Uint8List _encodeBackup(
    List<Product> products,
    AppSettings settings,
    String appVersion,
  ) {
    if (products.length > maxProducts) {
      throw const BackupFormatException(
        'L’inventario contiene troppi prodotti per un singolo backup.',
      );
    }
    final imageFiles = <String, String>{};
    final serializedProducts = <Map<String, Object?>>[];
    var totalSize = 0;

    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      ProductValidation.requireValid(product);
      String? imageEntry;
      final imagePath = product.imagePath;
      if (imagePath != null) {
        final image = File(imagePath);
        if (!image.existsSync()) {
          throw BackupFormatException(
            'Foto di ${product.name} non disponibile. Ripristinala o rimuovila dal prodotto prima del backup.',
          );
        }
        final length = image.lengthSync();
        totalSize += length;
        if (length > ProductImageStorage.maxImageBytes ||
            totalSize > maxBackupBytes) {
          throw const BackupFormatException(
            'Le immagini superano i limiti del backup.',
          );
        }
        final extension = path.extension(image.path).toLowerCase();
        final handle = image.openSync();
        try {
          if (!ProductImageStorage.isSupportedImage(
            handle.readSync(16),
            extension,
          )) {
            throw BackupFormatException(
              'Foto di ${product.name} non valida. Sostituiscila o rimuovila prima del backup.',
            );
          }
        } finally {
          handle.closeSync();
        }
        imageEntry = 'images/${index}_${_safeId(product.id)}$extension';
        imageFiles[imageEntry] = image.path;
      }
      serializedProducts.add(_productToJson(product, imageEntry: imageEntry));
    }

    final manifest = <String, Object?>{
      'format': 'freshtrack-backup',
      'formatVersion': formatVersion,
      'appVersion': appVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'settings': _settingsToJson(settings),
      'products': serializedProducts,
    };
    final manifestBytes = utf8.encode(jsonEncode(manifest));
    if (manifestBytes.length > maxManifestBytes ||
        totalSize + manifestBytes.length > maxBackupBytes) {
      throw const BackupFormatException(
        'Il contenuto del backup supera i limiti consentiti.',
      );
    }
    if (imageFiles.length + 1 > maxEntries) {
      throw const BackupFormatException('Il backup contiene troppi elementi.');
    }
    final output = _BoundedOutput(maxBackupBytes);
    final encoder = ZipEncoder()..startEncode(output);
    encoder.add(ArchiveFile.bytes('manifest.json', manifestBytes));
    // Read and compress one image at a time, without retaining the full photo set.
    for (final entry in imageFiles.entries) {
      final file = ArchiveFile.stream(entry.key, InputFileStream(entry.value));
      try {
        encoder.add(file, autoClose: false);
      } finally {
        file.closeSync();
      }
    }
    encoder.endEncode();
    return output.getBytes();
  }

  BackupPreview inspect(Uint8List bytes) {
    return _preview(_parse(bytes));
  }

  Future<BackupPreview> inspectAsync(Uint8List bytes) async =>
      _preview(await _parseAsync(bytes));

  static BackupPreview _preview(_ParsedBackup parsed) {
    return BackupPreview(
      productCount: parsed.products.length,
      imageCount: parsed.imageEntries.length,
      exportedAt: parsed.exportedAt,
      appVersion: parsed.appVersion,
    );
  }

  Future<BackupRestoreResult> restore(
    Uint8List bytes, {
    required BackupImportMode mode,
  }) async {
    final parsed = await _parseAsync(bytes);
    return mutationLockFor(_productRepository).run(
      () => mutationLockFor(
        _settingsRepository,
      ).run(() => _restore(parsed, mode)),
    );
  }

  Future<BackupRestoreResult> _restore(
    _ParsedBackup parsed,
    BackupImportMode mode,
  ) async {
    final previousProducts = await _productRepository.getAll();
    final previousSettings = await _settingsRepository.load();
    final tempRoot = await _temporaryDirectoryProvider();
    await tempRoot.create(recursive: true);
    final staging = await tempRoot.createTemp('freshtrack_restore_');
    final newImagePaths = <String>[];
    var preserveNewImages = false;

    try {
      final imported = <Product>[];
      for (final item in parsed.products) {
        String? importedImagePath;
        final imageEntry = item.imageEntry;
        if (imageEntry != null) {
          final bytes = parsed.imageEntries[imageEntry];
          if (bytes == null) {
            throw BackupFormatException(
              'Immagine mancante nel backup: $imageEntry',
            );
          }
          final staged = File(
            path.join(staging.path, path.basename(imageEntry)),
          );
          await staged.writeAsBytes(bytes, flush: true);
          importedImagePath = await _imageStorage.save(staged.path);
          newImagePaths.add(importedImagePath);
        }
        imported.add(item.product.copyWith(imagePath: importedImagePath));
      }

      final nextProducts = switch (mode) {
        BackupImportMode.replace => imported,
        BackupImportMode.merge => _mergeProducts(previousProducts, imported),
      };
      if (nextProducts.length > maxProducts) {
        throw const BackupFormatException(
          'L’unione supera il limite di 5000 prodotti.',
        );
      }

      try {
        preserveNewImages = true;
        await _productRepository.replaceAll(nextProducts);
        await _settingsRepository.save(parsed.settings);
      } catch (_) {
        try {
          await _productRepository.replaceAll(previousProducts);
          preserveNewImages = false;
          await _settingsRepository.save(previousSettings);
        } catch (_) {
          throw const BackupFormatException(
            'Ripristino interrotto: non è stato possibile recuperare tutti i dati precedenti. Le foto sono state conservate; controlla l’inventario prima di riprovare.',
          );
        }
        rethrow;
      }

      final retainedImages = nextProducts
          .map((product) => product.imagePath)
          .whereType<String>()
          .toSet();
      for (final product in previousProducts) {
        final oldPath = product.imagePath;
        if (oldPath != null && !retainedImages.contains(oldPath)) {
          await deleteProductImageBestEffort(_imageStorage, oldPath);
        }
      }
      // Images from older conflicting records were staged but not retained.
      for (final imagePath in newImagePaths.where(
        (value) => !retainedImages.contains(value),
      )) {
        await deleteProductImageBestEffort(_imageStorage, imagePath);
      }
      return BackupRestoreResult(
        productCount: imported.length,
        imageCount: newImagePaths.where(retainedImages.contains).length,
      );
    } catch (_) {
      if (!preserveNewImages) {
        for (final imagePath in newImagePaths) {
          await deleteProductImageBestEffort(_imageStorage, imagePath);
        }
      }
      rethrow;
    } finally {
      try {
        if (await staging.exists()) await staging.delete(recursive: true);
      } catch (_) {
        /* Temporary cleanup must not turn a committed restore into a failure. */
      }
    }
  }

  static _ParsedBackup _parse(Uint8List bytes) {
    if (bytes.isEmpty || bytes.length > maxBackupBytes) {
      throw const BackupFormatException('Dimensione del backup non valida.');
    }
    late ZipDirectory directory;
    try {
      directory = ZipDirectory()..read(InputMemoryStream(bytes));
    } catch (_) {
      throw const BackupFormatException('Il file non è un backup valido.');
    }
    if (directory.fileHeaders.length > maxEntries) {
      throw const BackupFormatException('Il backup contiene troppi elementi.');
    }

    final imageEntries = <String, Uint8List>{};
    Uint8List? manifestBytes;
    var totalSize = 0;
    final names = <String>{};
    for (final header in directory.fileHeaders) {
      final entry = header.file!;
      final name = header.filename;
      final fileType = (header.externalFileAttributes >> 16) & 0xf000;
      if (!_safeArchivePath(name) ||
          fileType == 0xa000 ||
          !names.add(name) ||
          entry.filename != name) {
        throw const BackupFormatException(
          'Il backup contiene un percorso non sicuro.',
        );
      }
      if (name.endsWith('/')) continue;
      final limit = name == 'manifest.json'
          ? maxManifestBytes
          : ProductImageStorage.maxImageBytes;
      if (header.uncompressedSize > limit ||
          entry.uncompressedSize != header.uncompressedSize ||
          (header.generalPurposeBitFlag & 1) != 0 ||
          (entry.flags & 1) != 0) {
        throw const BackupFormatException(
          'Dimensione o formato di un elemento non valido.',
        );
      }
      totalSize += header.uncompressedSize;
      if (totalSize > maxBackupBytes) {
        throw const BackupFormatException('Il backup è troppo grande.');
      }
      final output = _BoundedOutput(header.uncompressedSize);
      try {
        if (header.compressionMethod == 8 &&
            entry.compressionMethod == CompressionType.deflate) {
          Inflate.stream(entry.getStream(decompress: false), output: output);
        } else if (header.compressionMethod == 0 &&
            entry.compressionMethod == CompressionType.none) {
          output.writeStream(entry.getStream(decompress: false));
        } else {
          throw const BackupFormatException(
            'Compressione del backup non supportata.',
          );
        }
      } catch (_) {
        throw const BackupFormatException(
          'Il backup contiene dati danneggiati o troppo grandi.',
        );
      }
      final content = output.getBytes();
      if (content.length != header.uncompressedSize ||
          getCrc32(content) != header.crc32 ||
          getCrc32(content) != entry.crc32) {
        throw const BackupFormatException(
          'Il backup contiene dati danneggiati.',
        );
      }
      if (name == 'manifest.json') {
        if (manifestBytes != null || content.length > maxManifestBytes) {
          throw const BackupFormatException('Manifest del backup non valido.');
        }
        manifestBytes = content;
      } else if (name.startsWith('images/')) {
        if (imageEntries.containsKey(name) ||
            content.length > ProductImageStorage.maxImageBytes) {
          throw const BackupFormatException(
            'Il backup contiene un’immagine non valida.',
          );
        }
        imageEntries[name] = content;
      } else {
        throw const BackupFormatException(
          'Il backup contiene un elemento non riconosciuto.',
        );
      }
    }
    if (manifestBytes == null) {
      throw const BackupFormatException('Manifest del backup non valido.');
    }

    late Map<String, dynamic> manifest;
    try {
      final decoded = jsonDecode(utf8.decode(manifestBytes));
      if (decoded is! Map<String, dynamic>) throw const FormatException();
      manifest = decoded;
    } catch (_) {
      throw const BackupFormatException('Manifest del backup danneggiato.');
    }
    if (manifest['format'] != 'freshtrack-backup' ||
        manifest['formatVersion'] != formatVersion) {
      throw const BackupFormatException('Versione del backup non supportata.');
    }

    try {
      final rawProducts = manifest['products'];
      if (rawProducts is! List<dynamic> || rawProducts.length > maxProducts) {
        throw const FormatException();
      }
      final products = rawProducts
          .map((value) {
            if (value is! Map<String, dynamic>) throw const FormatException();
            return _backupProductFromJson(value);
          })
          .toList(growable: false);
      if (products.map((item) => item.product.id).toSet().length !=
          products.length) {
        throw const FormatException();
      }
      final referencedImages = products
          .map((item) => item.imageEntry)
          .whereType<String>()
          .toSet();
      if (referencedImages.length != imageEntries.length ||
          !referencedImages.containsAll(imageEntries.keys)) {
        throw const FormatException();
      }
      final settingsJson = manifest['settings'];
      if (settingsJson is! Map<String, dynamic>) throw const FormatException();
      final exportedAt = DateTime.parse(
        manifest['exportedAt'] as String,
      ).toUtc();
      final appVersion = manifest['appVersion'] as String;
      return _ParsedBackup(
        products: products,
        settings: _settingsFromJson(settingsJson),
        exportedAt: exportedAt,
        appVersion: appVersion,
        imageEntries: imageEntries,
      );
    } catch (_) {
      throw const BackupFormatException('Dati del backup non validi.');
    }
  }

  List<Product> _mergeProducts(List<Product> existing, List<Product> imported) {
    final merged = {for (final product in existing) product.id: product};
    for (final product in imported) {
      final current = merged[product.id];
      if (current == null || product.updatedAt.isAfter(current.updatedAt)) {
        merged[product.id] = product;
      }
    }
    return merged.values.toList(growable: false);
  }

  static Map<String, Object?> _productToJson(
    Product product, {
    required String? imageEntry,
  }) => {
    'id': product.id,
    'name': product.name,
    'description': product.description,
    'category': product.category.name,
    'quantity': product.quantity,
    'unit': product.unit.name,
    'purchaseDate': product.purchaseDate.toIso8601String(),
    'expirationDate': product.expirationDate.toIso8601String(),
    'imageEntry': imageEntry,
    'barcode': product.barcode,
    'status': product.status.name,
    'notificationDaysBefore': product.notificationDaysBefore,
    'createdAt': product.createdAt.toUtc().toIso8601String(),
    'updatedAt': product.updatedAt.toUtc().toIso8601String(),
  };

  static _BackupProduct _backupProductFromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final name = (json['name'] as String).trim();
    if (id.isEmpty ||
        id.length > 128 ||
        name.isEmpty ||
        name.length > maxProductNameLength) {
      throw const FormatException();
    }
    final imageEntry = json['imageEntry'] as String?;
    if (imageEntry != null &&
        (!imageEntry.startsWith('images/') || !_safeArchivePath(imageEntry))) {
      throw const FormatException();
    }
    final quantity = (json['quantity'] as num).toDouble();
    if (!quantity.isFinite || quantity <= 0 || quantity > maxProductQuantity) {
      throw const FormatException();
    }
    final description = (json['description'] as String?)?.trim();
    if (description != null &&
        description.length > maxProductDescriptionLength) {
      throw const FormatException();
    }
    final rawBarcode = (json['barcode'] as String?)?.trim();
    final barcode = rawBarcode == null || rawBarcode.isEmpty
        ? null
        : rawBarcode;
    if (barcode != null &&
        !RegExp(
          '^\\d{$minProductBarcodeLength,$maxProductBarcodeLength}\$',
        ).hasMatch(barcode)) {
      throw const FormatException();
    }
    final result = _BackupProduct(
      product: Product(
        id: id,
        name: name,
        description: description == null || description.isEmpty
            ? null
            : description,
        category: ProductCategory.values.byName(json['category'] as String),
        quantity: quantity,
        unit: MeasurementUnit.values.byName(json['unit'] as String),
        purchaseDate: _requiredDate(json['purchaseDate']),
        expirationDate: _requiredDate(json['expirationDate']),
        imagePath: null,
        barcode: barcode,
        status: ProductStatus.values.byName(json['status'] as String),
        notificationDaysBefore: (json['notificationDaysBefore'] as int).clamp(
          0,
          30,
        ),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      ),
      imageEntry: imageEntry,
    );
    ProductValidation.requireValid(result.product);
    return result;
  }

  static CivilDate _requiredDate(Object? value) {
    final date = CivilDate.tryParse(value as String?);
    if (date == null) throw const FormatException();
    return date;
  }

  static Map<String, Object> _settingsToJson(AppSettings settings) => {
    'themePreference': settings.themePreference.name,
    'languagePreference': settings.languagePreference.name,
    'notificationDaysBefore': settings.notificationDaysBefore,
    'notificationHour': settings.notificationHour,
    'notificationMinute': settings.notificationMinute,
  };

  static AppSettings _settingsFromJson(Map<String, dynamic> json) =>
      AppSettings(
        themePreference: AppThemePreference.values.byName(
          json['themePreference'] as String,
        ),
        languagePreference: AppLanguagePreference.values.firstWhere(
          (value) => value.name == json['languagePreference'],
          orElse: () => AppSettings.defaults.languagePreference,
        ),
        notificationDaysBefore: (json['notificationDaysBefore'] as int).clamp(
          0,
          30,
        ),
        notificationHour: (json['notificationHour'] as int).clamp(0, 23),
        notificationMinute: (json['notificationMinute'] as int).clamp(0, 59),
      );

  static bool _safeArchivePath(String value) {
    final normalized = value.replaceAll('\\', '/');
    return normalized.isNotEmpty &&
        !normalized.startsWith('/') &&
        !normalized.contains(':') &&
        !normalized.split('/').contains('..');
  }

  static String _safeId(String value) =>
      value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
}

/// Enforces the declared size while inflating, before growing the buffer.
class _BoundedOutput extends OutputMemoryStream {
  _BoundedOutput(this.limit) : super(size: limit.clamp(1, 32768));
  final int limit;
  void _check(int count) {
    if (count < 0 || length + count > limit) {
      throw const BackupFormatException('Elemento troppo grande.');
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    super.writeStream(stream);
  }

  @override
  void writeBackReference(int distance, int count) {
    _check(count);
    super.writeBackReference(distance, count);
  }
}

final class _BackupProduct {
  const _BackupProduct({required this.product, required this.imageEntry});
  final Product product;
  final String? imageEntry;
}

final class _ParsedBackup {
  const _ParsedBackup({
    required this.products,
    required this.settings,
    required this.exportedAt,
    required this.appVersion,
    required this.imageEntries,
  });

  final List<_BackupProduct> products;
  final AppSettings settings;
  final DateTime exportedAt;
  final String appVersion;
  final Map<String, Uint8List> imageEntries;
}
