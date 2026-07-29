import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ProductImageStorage {
  ProductImageStorage({this.uuid = const Uuid()});

  final Uuid uuid;

  Future<String> save(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const FileSystemException('Immagine selezionata non disponibile');
    }

    final appDirectory = await getApplicationSupportDirectory();
    final imagesDirectory = Directory(
      path.join(appDirectory.path, 'product_images'),
    );
    await imagesDirectory.create(recursive: true);

    final extension = path.extension(sourcePath).toLowerCase();
    final safeExtension = extension.isEmpty ? '.jpg' : extension;
    final destination = path.join(
      imagesDirectory.path,
      '${uuid.v4()}$safeExtension',
    );
    return (await source.copy(destination)).path;
  }

  Future<void> delete(String? imagePath) async {
    if (imagePath == null) return;
    final image = File(imagePath);
    if (await image.exists()) {
      await image.delete();
    }
  }
}
