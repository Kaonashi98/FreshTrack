import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ProductImageStorage {
  ProductImageStorage({
    this.uuid = const Uuid(),
    Future<Directory> Function()? appSupportDirectoryProvider,
    Future<File> Function(File source, String destination)? copyFile,
  }) : _appSupportDirectoryProvider =
           appSupportDirectoryProvider ?? getApplicationSupportDirectory,
       _copyFile = copyFile ?? _defaultCopyFile;

  static const maxImageBytes = 20 * 1024 * 1024;
  static bool isSupportedImage(List<int> header, String extension) =>
      _supportedExtensions.contains(extension) &&
      _matchesImageHeader(header, extension);
  static const _supportedExtensions = {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
    '.bmp',
    '.heic',
    '.heif',
    '.avif',
  };

  final Uuid uuid;
  final Future<Directory> Function() _appSupportDirectoryProvider;
  final Future<File> Function(File source, String destination) _copyFile;

  Future<String> save(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const FileSystemException('Immagine selezionata non disponibile');
    }

    if (await source.length() > maxImageBytes) {
      throw const FileSystemException('Immagine troppo grande');
    }

    final sourceExtension = path.extension(sourcePath).toLowerCase();
    if (!_supportedExtensions.contains(sourceExtension)) {
      throw const FileSystemException('Formato immagine non supportato');
    }
    final handle = await source.open();
    late List<int> header;
    try {
      header = await handle.read(16);
    } finally {
      await handle.close();
    }
    // Android's image picker may re-encode a PNG/HEIF as JPEG while retaining
    // its original suffix. Store it with the actual format so backup validation
    // and consumers of the saved file see a consistent name and payload.
    String? extension;
    for (final candidate in {sourceExtension, ..._supportedExtensions}) {
      if (_matchesImageHeader(header, candidate)) {
        extension = candidate;
        break;
      }
    }
    if (extension == null) {
      throw const FileSystemException('Contenuto immagine non valido');
    }
    final imagesDirectory = await _imagesDirectory();
    await imagesDirectory.create(recursive: true);
    final destination = path.join(
      imagesDirectory.path,
      '${uuid.v4()}$extension',
    );
    return (await _copyFile(source, destination)).path;
  }

  Future<void> delete(String? imagePath) async {
    if (imagePath == null) return;
    final imagesDirectory = await _imagesDirectory();
    final normalizedDirectory = path.normalize(
      path.absolute(imagesDirectory.path),
    );
    final normalizedImage = path.normalize(path.absolute(imagePath));
    if (!path.isWithin(normalizedDirectory, normalizedImage)) {
      throw FileSystemException(
        'Percorso immagine non gestito da FreshTrack',
        imagePath,
      );
    }
    final image = File(normalizedImage);
    if (await image.exists()) {
      await image.delete();
    }
  }

  Future<void> deleteAll() async {
    final imagesDirectory = await _imagesDirectory();
    if (await imagesDirectory.exists()) {
      await imagesDirectory.delete(recursive: true);
    }
  }

  Future<Directory> _imagesDirectory() async {
    final appDirectory = await _appSupportDirectoryProvider();
    return Directory(path.join(appDirectory.path, 'product_images'));
  }

  static Future<File> _defaultCopyFile(File source, String destination) =>
      source.copy(destination);

  static bool _matchesImageHeader(List<int> bytes, String extension) {
    bool startsWith(List<int> signature) {
      if (bytes.length < signature.length) return false;
      for (var index = 0; index < signature.length; index++) {
        if (bytes[index] != signature[index]) return false;
      }
      return true;
    }

    final isJpeg = startsWith(const [0xff, 0xd8, 0xff]);
    final isPng = startsWith(const [
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
    ]);
    final isGif =
        startsWith(const [0x47, 0x49, 0x46, 0x38, 0x37, 0x61]) ||
        startsWith(const [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]);
    final isBmp = startsWith(const [0x42, 0x4d]);
    final isWebp =
        bytes.length >= 12 &&
        startsWith(const [0x52, 0x49, 0x46, 0x46]) &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    final brand = bytes.length >= 12
        ? String.fromCharCodes(bytes.sublist(8, 12))
        : '';
    final isIsoImage =
        bytes.length >= 12 &&
        bytes[4] == 0x66 &&
        bytes[5] == 0x74 &&
        bytes[6] == 0x79 &&
        bytes[7] == 0x70;
    final isHeif =
        isIsoImage &&
        const {'heic', 'heix', 'hevc', 'hevx', 'mif1', 'msf1'}.contains(brand);
    final isAvif = isIsoImage && const {'avif', 'avis'}.contains(brand);

    return switch (extension) {
      '.jpg' || '.jpeg' => isJpeg,
      '.png' => isPng,
      '.gif' => isGif,
      '.bmp' => isBmp,
      '.webp' => isWebp,
      '.heic' || '.heif' => isHeif,
      '.avif' => isAvif,
      _ => false,
    };
  }
}

Future<bool> deleteProductImageBestEffort(
  ProductImageStorage storage,
  String? imagePath,
) async {
  try {
    await storage.delete(imagePath);
    return true;
  } catch (_) {
    return false;
  }
}
