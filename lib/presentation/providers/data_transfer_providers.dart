import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/data/backup/freshtrack_backup_service.dart';
import 'package:freshtrack/data/backup/inventory_data_service.dart';
import 'package:freshtrack/data/ocr/expiration_date_ocr_service.dart';
import 'package:freshtrack/data/products/open_food_facts_service.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:http/http.dart' as http;

final openFoodFactsServiceProvider = FutureProvider<OpenFoodFactsService>((
  ref,
) async {
  final appVersion = await ref.watch(appVersionProvider.future);
  final client = http.Client();
  ref.onDispose(client.close);
  return OpenFoodFactsService(client, appVersion: appVersion);
});

final expirationDateOcrServiceProvider = Provider<ExpirationDateOcrService>((
  ref,
) {
  final service = ExpirationDateOcrService();
  ref.onDispose(service.close);
  return service;
});

final freshTrackBackupServiceProvider = Provider<FreshTrackBackupService>((
  ref,
) {
  return FreshTrackBackupService(
    productRepository: ref.read(productRepositoryProvider),
    settingsRepository: ref.read(appSettingsRepositoryProvider),
    imageStorage: ref.read(productImageStorageProvider),
  );
});

final inventoryDataServiceProvider = Provider<InventoryDataService>((ref) {
  final synchronization = ref.read(notificationSynchronizationProvider);
  return InventoryDataService(
    products: ref.read(productRepositoryProvider),
    settings: ref.read(appSettingsRepositoryProvider),
    images: ref.read(productImageStorageProvider),
    backup: ref.read(freshTrackBackupServiceProvider),
    refreshState: () {
      if (!ref.mounted) return;
      ref.invalidate(productsProvider);
      ref.invalidate(productByIdProvider);
      ref.invalidate(appSettingsProvider);
    },
    synchronize: synchronization.synchronizeLatest,
  );
});
