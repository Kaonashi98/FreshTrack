import 'dart:typed_data';

import 'package:freshtrack/data/backup/freshtrack_backup_service.dart';
import 'package:freshtrack/data/media/product_image_storage.dart';
import 'package:freshtrack/domain/common/async_mutex.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';

/// Finishes a confirmed operation even if its initiating page is disposed.
class InventoryDataService {
  InventoryDataService({
    required this.products,
    required this.settings,
    required this.images,
    required this.backup,
    required this.refreshState,
    required this.synchronize,
  });
  final ProductRepository products;
  final AppSettingsRepository settings;
  final ProductImageStorage images;
  final FreshTrackBackupService backup;
  final void Function() refreshState;
  final Future<NotificationSynchronizationResult> Function() synchronize;

  Future<List<String>> clear() async {
    final incomplete = <String>[];
    await mutationLockFor(products).run(
      () => mutationLockFor(settings).run(() async {
        await products.clear();
        try {
          await images.deleteAll();
        } catch (_) {
          incomplete.add('alcune immagini');
        }
        try {
          await settings.clear();
        } catch (_) {
          incomplete.add('le preferenze');
        }
        refreshState();
      }),
    );
    try {
      if (!(await synchronize()).isComplete) {
        incomplete.add('alcuni promemoria');
      }
    } catch (_) {
      incomplete.add('alcuni promemoria');
    }
    return incomplete;
  }

  Future<({BackupRestoreResult result, bool notificationsComplete})> restore(
    Uint8List bytes,
    BackupImportMode mode,
  ) async {
    final result = await backup.restore(bytes, mode: mode);
    refreshState();
    var notificationsComplete = false;
    try {
      notificationsComplete = (await synchronize()).isComplete;
    } catch (_) {
      /* Report a committed restore separately from notifications. */
    }
    return (result: result, notificationsComplete: notificationsComplete);
  }
}
