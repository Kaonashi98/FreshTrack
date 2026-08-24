import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/media/product_image_storage.dart';
import 'package:path/path.dart' as path;

void main() {
  late Directory supportDirectory;
  late ProductImageStorage storage;

  setUp(() async {
    supportDirectory = await Directory.systemTemp.createTemp(
      'freshtrack-images-',
    );
    storage = ProductImageStorage(
      appSupportDirectoryProvider: () async => supportDirectory,
    );
  });

  tearDown(() async {
    if (await supportDirectory.exists()) {
      await supportDirectory.delete(recursive: true);
    }
  });

  test('salva e cancella soltanto immagini nella cartella gestita', () async {
    final source = File(path.join(supportDirectory.path, 'origine.jpg'));
    await source.writeAsBytes([1, 2, 3, 4]);

    final savedPath = await storage.save(source.path);
    expect(
      path.isWithin(
        path.join(supportDirectory.path, 'product_images'),
        savedPath,
      ),
      isTrue,
    );
    expect(await File(savedPath).exists(), isTrue);

    await storage.delete(savedPath);
    expect(await File(savedPath).exists(), isFalse);
  });

  test('rifiuta la cancellazione di file esterni', () async {
    final external = File(
      path.join(supportDirectory.path, 'da-conservare.jpg'),
    );
    await external.writeAsBytes([1, 2, 3]);

    await expectLater(
      storage.delete(external.path),
      throwsA(isA<FileSystemException>()),
    );
    expect(await external.exists(), isTrue);
  });

  test('deleteAll rimuove anche immagini rimaste senza record', () async {
    final imagesDirectory = Directory(
      path.join(supportDirectory.path, 'product_images'),
    );
    await imagesDirectory.create(recursive: true);
    await File(path.join(imagesDirectory.path, 'orfana.png')).writeAsBytes([1]);

    await storage.deleteAll();

    expect(await imagesDirectory.exists(), isFalse);
  });

  test('rifiuta estensioni che non rappresentano immagini', () async {
    final source = File(path.join(supportDirectory.path, 'documento.txt'));
    await source.writeAsString('non è un’immagine');

    await expectLater(
      storage.save(source.path),
      throwsA(isA<FileSystemException>()),
    );
  });

  test(
    'propaga un errore copia/storage pieno senza creare un path valido',
    () async {
      final source = File(path.join(supportDirectory.path, 'origine.jpg'));
      await source.writeAsBytes([1, 2, 3]);
      final failing = ProductImageStorage(
        appSupportDirectoryProvider: () async => supportDirectory,
        copyFile: (_, _) =>
            Future.error(const FileSystemException('Spazio esaurito')),
      );
      await expectLater(
        failing.save(source.path),
        throwsA(isA<FileSystemException>()),
      );
    },
  );

  test('cleanup best-effort non nasconde l’errore primario', () async {
    final failing = _FailingDeleteStorage();
    expect(
      await deleteProductImageBestEffort(failing, 'immagine.jpg'),
      isFalse,
    );
  });
}

class _FailingDeleteStorage extends ProductImageStorage {
  @override
  Future<void> delete(String? imagePath) =>
      Future.error(const FileSystemException('Cleanup fallito'));
}
