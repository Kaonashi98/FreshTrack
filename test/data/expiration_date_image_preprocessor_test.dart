import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/ocr/expiration_date_image_preprocessor.dart';
import 'package:image/image.dart' as img;

void main() {
  test('ritaglia una fascia centrale e scrive un JPEG', () async {
    final directory = await Directory.systemTemp.createTemp(
      'freshtrack_ocr_crop_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final source = File('${directory.path}/packaging.png');
    final image = img.Image(width: 200, height: 100);
    img.fill(image, color: img.ColorRgb8(20, 20, 20));
    img.fillRect(
      image,
      x1: 20,
      y1: 30,
      x2: 180,
      y2: 70,
      color: img.ColorRgb8(240, 240, 240),
    );
    await source.writeAsBytes(img.encodePng(image));

    final croppedPath = await const ExpirationDateImagePreprocessor()
        .cropDateBand(source.path);

    expect(croppedPath, isNot(source.path));
    final cropped = img.decodeImage(await File(croppedPath).readAsBytes());
    expect(cropped, isNotNull);
    expect(cropped!.width, lessThan(image.width));
    expect(cropped.height, lessThan(image.height));
  });
}
