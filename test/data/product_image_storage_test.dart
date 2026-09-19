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
    await source.writeAsBytes(_jpegBytes);

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

  test(
    'normalizza il PNG ricodificato in JPEG dal selettore Android',
    () async {
      final source = File(path.join(supportDirectory.path, 'scaled_foto.png'));
      await source.writeAsBytes(_jpegBytes);

      final savedPath = await storage.save(source.path);
      final savedBytes = await File(savedPath).readAsBytes();

      expect(path.extension(savedPath), '.jpg');
      expect(savedBytes, _jpegBytes);
      expect(
        ProductImageStorage.isSupportedImage(
          savedBytes,
          path.extension(savedPath),
        ),
        isTrue,
      );
    },
  );

  test('conserva il PNG con trasparenza anche con suffisso JPEG', () async {
    const pngBytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];
    final source = File(path.join(supportDirectory.path, 'scaled_foto.jpg'));
    await source.writeAsBytes(pngBytes);

    final savedPath = await storage.save(source.path);

    expect(path.extension(savedPath), '.png');
    expect(await File(savedPath).readAsBytes(), pngBytes);
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

  test('rifiuta contenuto non immagine anche con estensione valida', () async {
    final source = File(path.join(supportDirectory.path, 'falso.jpg'));
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
      await source.writeAsBytes(_jpegBytes);
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

const _jpegBytes = <int>[
  0xff,
  0xd8,
  0xff,
  0xe0,
  0x00,
  0x10,
  0x4a,
  0x46,
  0x49,
  0x46,
  0x00,
];

class _FailingDeleteStorage extends ProductImageStorage {
  @override
  Future<void> delete(String? imagePath) =>
      Future.error(const FileSystemException('Cleanup fallito'));
}
