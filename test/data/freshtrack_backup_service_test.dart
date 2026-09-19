import 'dart:async';
import 'package:freshtrack/domain/common/async_mutex.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/backup/freshtrack_backup_service.dart';
import 'package:freshtrack/data/media/product_image_storage.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';

void main() {
  test(
    'interrompe la decompressione quando supera la dimensione dichiarata',
    () async {
      final root = await Directory.systemTemp.createTemp('freshtrack_inflate_');
      addTearDown(() => root.delete(recursive: true));
      final service = _service(
        root: root,
        products: _MemoryProductRepository([]),
        settings: _MemorySettingsRepository(AppSettings.defaults),
      );
      final archive = Archive()
        ..add(ArchiveFile.bytes('manifest.json', List.filled(1024 * 1024, 65)));
      final bytes = Uint8List.fromList(ZipEncoder().encode(archive));
      final data = ByteData.sublistView(bytes);
      // Advertise a tiny output in both headers while keeping valid compressed data.
      data.setUint32(22, 16, Endian.little);
      for (var i = 0; i < bytes.length - 28; i++) {
        if (data.getUint32(i, Endian.little) == 0x02014b50) {
          data.setUint32(i + 24, 16, Endian.little);
          break;
        }
      }
      expect(
        () => service.inspect(bytes),
        throwsA(
          isA<BackupFormatException>().having(
            (e) => e.message,
            'limit error',
            contains('troppo grandi'),
          ),
        ),
      );
    },
  );
  test(
    'rifiuta nomi ZIP duplicati prima di interpretare il manifest',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'freshtrack_duplicates_',
      );
      addTearDown(() => root.delete(recursive: true));
      final service = _service(
        root: root,
        products: _MemoryProductRepository([]),
        settings: _MemorySettingsRepository(AppSettings.defaults),
      );
      final valid = await service.createBackup(appVersion: 'test');
      final manifest = ZipDecoder()
          .decodeBytes(valid)
          .find('manifest.json')!
          .readBytes()!;
      final output = OutputMemoryStream();
      final encoder = ZipEncoder()..startEncode(output);
      encoder.add(ArchiveFile.bytes('manifest.json', manifest));
      encoder.add(ArchiveFile.bytes('manifest.json', manifest));
      encoder.endEncode();
      expect(
        () => service.inspect(output.getBytes()),
        throwsA(isA<BackupFormatException>()),
      );
    },
  );
  test('non dichiara completo un backup con foto mancanti', () async {
    final root = await Directory.systemTemp.createTemp(
      'freshtrack_missing_export_',
    );
    addTearDown(() => root.delete(recursive: true));
    final service = _service(
      root: root,
      products: _MemoryProductRepository([
        _product(imagePath: '${root.path}/missing.png'),
      ]),
      settings: _MemorySettingsRepository(AppSettings.defaults),
    );
    await expectLater(
      service.createBackup(appVersion: 'test'),
      throwsA(isA<BackupFormatException>()),
    );
  });
  for (final failRollback in [false, true]) {
    test(
      'errore impostazioni con rollback fallito=$failRollback conserva le foto necessarie',
      () async {
        final root = await Directory.systemTemp.createTemp(
          'freshtrack_rollback_',
        );
        addTearDown(() => root.delete(recursive: true));
        final photo = File('${root.path}/photo.png');
        await photo.writeAsBytes(_pngBytes);
        final source = _service(
          root: root,
          products: _MemoryProductRepository([
            _product(id: 'backup', imagePath: photo.path),
          ]),
          settings: _MemorySettingsRepository(AppSettings.defaults),
        );
        final bytes = await source.createBackup(appVersion: 'test');
        final repo = _RollbackRepository([
          _product(id: 'originale'),
        ], failRollback: failRollback);
        final service = _service(
          root: root,
          products: repo,
          settings: _FailOnceSettings(),
        );
        await expectLater(
          service.restore(bytes, mode: BackupImportMode.replace),
          failRollback
              ? throwsA(isA<BackupFormatException>())
              : throwsStateError,
        );
        if (failRollback) {
          expect(repo.products.single.id, 'backup');
          expect(await File(repo.products.single.imagePath!).exists(), isTrue);
        } else {
          expect(repo.products.single.id, 'originale');
          final images = Directory('${root.path}/support/product_images');
          expect(await images.list().toList(), isEmpty);
        }
      },
    );
  }

  test(
    'regressione: backup creato deve essere ripristinabile entro i limiti dichiarati',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'freshtrack_roundtrip_audit_',
      );
      addTearDown(() => root.delete(recursive: true));
      final products = List.generate(
        4000,
        (index) =>
            _product(id: 'audit-$index').copyWith(description: 'a' * 1000),
      );
      final service = _service(
        root: root,
        products: _MemoryProductRepository(products),
        settings: _MemorySettingsRepository(AppSettings.defaults),
      );
      final bytes = await service.createBackup(appVersion: 'audit');
      expect(service.inspect(bytes).productCount, 4000);
    },
  );
  test(
    'regressione: unione backup conserva un prodotto aggiunto durante importazione',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'freshtrack_restore_race_audit_',
      );
      addTearDown(() => root.delete(recursive: true));
      final photo = File('${root.path}/photo.png');
      await photo.writeAsBytes(_pngBytes);
      final source = _service(
        root: Directory('${root.path}/source'),
        products: _MemoryProductRepository([
          _product(id: 'backup', imagePath: photo.path),
        ]),
        settings: _MemorySettingsRepository(AppSettings.defaults),
      );
      final bytes = await source.createBackup(appVersion: 'audit');
      final repo = _MemoryProductRepository([_product(id: 'esistente')]);
      final storage = _AuditDelayedImageStorage(
        Directory('${root.path}/target'),
      );
      final target = FreshTrackBackupService(
        productRepository: repo,
        settingsRepository: _MemorySettingsRepository(AppSettings.defaults),
        imageStorage: storage,
        temporaryDirectoryProvider: () async => Directory('${root.path}/temp'),
      );
      final restoring = target.restore(bytes, mode: BackupImportMode.merge);
      await storage.started.future;
      final adding = mutationLockFor(
        repo,
      ).run(() => repo.save(_product(id: 'aggiunto-durante-ripristino')));
      storage.release.complete();
      await restoring;
      await adding;
      expect(
        repo.products.map((product) => product.id),
        contains('aggiunto-durante-ripristino'),
      );
    },
  );
  test(
    'regressione: unisci non sovrascrive in silenzio una modifica piu recente',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'freshtrack_merge_old_audit_',
      );
      addTearDown(() => root.delete(recursive: true));
      final old = _product();
      final source = _service(
        root: root,
        products: _MemoryProductRepository([old]),
        settings: _MemorySettingsRepository(AppSettings.defaults),
      );
      final bytes = await source.createBackup(appVersion: 'audit');
      final repo = _MemoryProductRepository([
        old.copyWith(
          status: ProductStatus.consumed,
          updatedAt: old.updatedAt.add(const Duration(days: 1)),
        ),
      ]);
      final target = _service(
        root: root,
        products: repo,
        settings: _MemorySettingsRepository(AppSettings.defaults),
      );
      await target.restore(bytes, mode: BackupImportMode.merge);
      expect(repo.products.single.status, ProductStatus.consumed);
    },
  );
  test('crea, controlla e ripristina prodotti impostazioni e foto', () async {
    final root = await Directory.systemTemp.createTemp('freshtrack_backup_');
    addTearDown(() => root.delete(recursive: true));
    final sourcePhoto = File('${root.path}${Platform.pathSeparator}latte.png');
    await sourcePhoto.writeAsBytes(_pngBytes);
    final sourceProducts = _MemoryProductRepository([
      _product(imagePath: sourcePhoto.path),
    ]);
    final sourceSettings = _MemorySettingsRepository(
      AppSettings.defaults.copyWith(
        themePreference: AppThemePreference.light,
        notificationDaysBefore: 5,
      ),
    );
    final sourceService = _service(
      root: Directory('${root.path}${Platform.pathSeparator}source'),
      products: sourceProducts,
      settings: sourceSettings,
    );

    final bytes = await sourceService.createBackup(appVersion: '1.1.0+4');
    final preview = sourceService.inspect(bytes);

    expect(preview.productCount, 1);
    expect(preview.imageCount, 1);
    expect(preview.appVersion, '1.1.0+4');

    final targetProducts = _MemoryProductRepository([_product(id: 'vecchio')]);
    final targetSettings = _MemorySettingsRepository(AppSettings.defaults);
    final targetService = _service(
      root: Directory('${root.path}${Platform.pathSeparator}target'),
      products: targetProducts,
      settings: targetSettings,
    );
    final result = await targetService.restore(
      bytes,
      mode: BackupImportMode.replace,
    );

    expect(result.productCount, 1);
    expect(result.imageCount, 1);
    expect(targetProducts.products.single.id, 'latte');
    expect(targetProducts.products.single.barcode, '8001234567890');
    expect(
      await File(targetProducts.products.single.imagePath!).readAsBytes(),
      _pngBytes,
    );
    expect(targetSettings.value.themePreference, AppThemePreference.light);
    expect(targetSettings.value.notificationDaysBefore, 5);
  });

  test(
    'in modalità unisci conserva i prodotti non presenti nel backup',
    () async {
      final root = await Directory.systemTemp.createTemp('freshtrack_merge_');
      addTearDown(() => root.delete(recursive: true));
      final source = _service(
        root: Directory('${root.path}${Platform.pathSeparator}source'),
        products: _MemoryProductRepository([_product()]),
        settings: _MemorySettingsRepository(AppSettings.defaults),
      );
      final bytes = await source.createBackup(appVersion: 'test');
      final targetProducts = _MemoryProductRepository([
        _product(id: 'pasta', name: 'Pasta'),
      ]);
      final target = _service(
        root: Directory('${root.path}${Platform.pathSeparator}target'),
        products: targetProducts,
        settings: _MemorySettingsRepository(AppSettings.defaults),
      );

      await target.restore(bytes, mode: BackupImportMode.merge);

      expect(targetProducts.products.map((product) => product.id), {
        'latte',
        'pasta',
      });
    },
  );

  test('rifiuta file non validi senza modificare il repository', () async {
    final root = await Directory.systemTemp.createTemp('freshtrack_invalid_');
    addTearDown(() => root.delete(recursive: true));
    final products = _MemoryProductRepository([_product()]);
    final service = _service(
      root: root,
      products: products,
      settings: _MemorySettingsRepository(AppSettings.defaults),
    );

    expect(
      () => service.inspect(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<BackupFormatException>()),
    );
    expect(products.products.single.id, 'latte');
  });

  test('rifiuta inventari oltre il limite prima di creare un backup', () async {
    final root = await Directory.systemTemp.createTemp('freshtrack_limit_');
    addTearDown(() => root.delete(recursive: true));
    final products = List.generate(
      FreshTrackBackupService.maxProducts + 1,
      (index) => _product(id: 'prodotto-$index'),
    );
    final service = _service(
      root: root,
      products: _MemoryProductRepository(products),
      settings: _MemorySettingsRepository(AppSettings.defaults),
    );

    await expectLater(
      service.createBackup(appVersion: 'test'),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('rifiuta un manifest che riferisce un’immagine assente', () async {
    final root = await Directory.systemTemp.createTemp(
      'freshtrack_missing_image_',
    );
    addTearDown(() => root.delete(recursive: true));
    final photo = File('${root.path}${Platform.pathSeparator}latte.png');
    await photo.writeAsBytes(_pngBytes);
    final service = _service(
      root: root,
      products: _MemoryProductRepository([_product(imagePath: photo.path)]),
      settings: _MemorySettingsRepository(AppSettings.defaults),
    );
    final valid = await service.createBackup(appVersion: 'test');
    final decoded = ZipDecoder().decodeBytes(valid);
    final withoutImage = Archive();
    for (final entry in decoded) {
      if (entry.name == 'manifest.json') {
        withoutImage.add(ArchiveFile.bytes(entry.name, entry.readBytes()!));
      }
    }
    final invalid = Uint8List.fromList(ZipEncoder().encode(withoutImage));

    expect(
      () => service.inspect(invalid),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test('mantiene immagini distinte anche con identificatori simili', () async {
    final root = await Directory.systemTemp.createTemp(
      'freshtrack_image_names_',
    );
    addTearDown(() => root.delete(recursive: true));
    final firstPhoto = File('${root.path}${Platform.pathSeparator}uno.png');
    final secondPhoto = File('${root.path}${Platform.pathSeparator}due.png');
    await firstPhoto.writeAsBytes(_pngBytes);
    await secondPhoto.writeAsBytes(_pngBytes);
    final service = _service(
      root: root,
      products: _MemoryProductRepository([
        _product(id: 'latte/a', imagePath: firstPhoto.path),
        _product(id: 'latte:a', imagePath: secondPhoto.path),
      ]),
      settings: _MemorySettingsRepository(AppSettings.defaults),
    );

    final backup = await service.createBackup(appVersion: 'test');
    final preview = service.inspect(backup);

    expect(preview.productCount, 2);
    expect(preview.imageCount, 2);
  });
}

const _pngBytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00];

FreshTrackBackupService _service({
  required Directory root,
  required ProductRepository products,
  required AppSettingsRepository settings,
}) {
  final appSupport = Directory('${root.path}${Platform.pathSeparator}support');
  final temporary = Directory('${root.path}${Platform.pathSeparator}temporary');
  return FreshTrackBackupService(
    productRepository: products,
    settingsRepository: settings,
    imageStorage: ProductImageStorage(
      appSupportDirectoryProvider: () async => appSupport,
    ),
    temporaryDirectoryProvider: () async => temporary,
  );
}

class _MemoryProductRepository implements ProductRepository {
  _MemoryProductRepository(this.products);
  final List<Product> products;

  @override
  Future<void> clear() async => products.clear();

  @override
  Future<void> delete(String id) async {
    products.removeWhere((product) => product.id == id);
  }

  @override
  Future<List<Product>> getAll() async => List.unmodifiable(products);

  @override
  Future<Product?> getById(String id) async {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<void> replaceAll(List<Product> next) async {
    products
      ..clear()
      ..addAll(next);
  }

  @override
  Future<void> save(Product product) async {
    products.removeWhere((existing) => existing.id == product.id);
    products.add(product);
  }

  @override
  Stream<List<Product>> watchAll() => Stream.value(products);
}

class _MemorySettingsRepository implements AppSettingsRepository {
  _MemorySettingsRepository(this.value);
  AppSettings value;

  @override
  Future<void> clear() async => value = AppSettings.defaults;

  @override
  Future<AppSettings> load() async => value;

  @override
  Future<void> save(AppSettings settings) async => value = settings;
}

Product _product({
  String id = 'latte',
  String name = 'Latte',
  String? imagePath,
}) => Product(
  id: id,
  name: name,
  description: 'Intero',
  category: ProductCategory.food,
  quantity: 1,
  unit: MeasurementUnit.liters,
  purchaseDate: CivilDate(2026, 8, 20),
  expirationDate: CivilDate(2026, 8, 30),
  imagePath: imagePath,
  barcode: '8001234567890',
  status: ProductStatus.available,
  notificationDaysBefore: 2,
  createdAt: DateTime.utc(2026, 8, 20),
  updatedAt: DateTime.utc(2026, 8, 20),
);

class _AuditDelayedImageStorage extends ProductImageStorage {
  _AuditDelayedImageStorage(Directory root)
    : super(appSupportDirectoryProvider: () async => root);
  final started = Completer<void>();
  final release = Completer<void>();
  @override
  Future<String> save(String sourcePath) async {
    started.complete();
    await release.future;
    return super.save(sourcePath);
  }
}

class _RollbackRepository extends _MemoryProductRepository {
  _RollbackRepository(super.products, {required this.failRollback});
  final bool failRollback;
  int writes = 0;
  @override
  Future<void> replaceAll(List<Product> next) async {
    writes++;
    if (writes == 2 && failRollback) throw StateError('rollback unavailable');
    await super.replaceAll(next);
  }
}

class _FailOnceSettings extends _MemorySettingsRepository {
  _FailOnceSettings() : super(AppSettings.defaults);
  bool fail = true;
  @override
  Future<void> save(AppSettings settings) async {
    if (fail) {
      fail = false;
      throw StateError('settings unavailable');
    }
    await super.save(settings);
  }
}
