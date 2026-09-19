import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la release conserva l’icona usata dalle notifiche', () {
    final icon = File('android/app/src/main/res/drawable/ic_notification.xml');
    final keepRules = File('android/app/src/main/res/raw/keep.xml');

    expect(icon.existsSync(), isTrue);
    expect(keepRules.existsSync(), isTrue);
    expect(
      keepRules.readAsStringSync(),
      contains('tools:keep="@drawable/ic_notification"'),
    );
  });

  test('il manifest limita fotocamera e rete alle funzioni dichiarate', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.CAMERA'));
    expect(manifest, contains('android.permission.INTERNET'));
    expect(manifest, contains('android.hardware.camera'));
    expect(manifest, contains('android:required="false"'));
    expect(manifest, contains('android:usesCleartextTraffic="false"'));
  });
}
