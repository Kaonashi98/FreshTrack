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

    final imagesDirectory = await _imagesDirectory();
    await imagesDirectory.create(recursive: true);

    final extension = path.extension(sourcePath).toLowerCase();
    if (!_supportedExtensions.contains(extension)) {
      throw const FileSystemException('Formato immagine non supportato');
    }
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
