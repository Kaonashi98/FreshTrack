import 'dart:async';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:freshtrack/data/media/product_image_storage.dart';
import 'package:freshtrack/data/backup/freshtrack_backup_service.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/products/product_repository.dart';
import 'package:freshtrack/domain/settings/app_settings.dart';
import 'package:freshtrack/domain/settings/app_settings_repository.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/data_transfer_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/presentation/settings/about_settings_screen.dart';
import 'package:freshtrack/presentation/settings/appearance_settings_screen.dart';
import 'package:freshtrack/presentation/settings/data_settings_screen.dart';
import 'package:freshtrack/presentation/settings/notification_settings_screen.dart';
import 'package:freshtrack/presentation/settings/settings_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  testWidgets('anteprima backup leggibile in landscape con testo al 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(915, 412);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final picker = FilePickerPlatform.instance;
    FilePickerPlatform.instance = _BackupPicker();
    addTearDown(() => FilePickerPlatform.instance = picker);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          freshTrackBackupServiceProvider.overrideWithValue(_PreviewService()),
        ],
        child: const MaterialApp(
          locale: Locale('it'),
          supportedLocales: [Locale('it'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: DataSettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final restore = find.text('Ripristina backup');
    await tester.scrollUntilVisible(restore, 200);
    await tester.pumpAndSettle();
    await tester.tap(restore);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Unisci').hitTestable(), findsOneWidget);
    expect(find.text('Sostituisci').hitTestable(), findsOneWidget);
    final explanation = find.textContaining('Unisci mantiene');
    final scroll = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(SingleChildScrollView),
    );
    await tester.drag(scroll, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomRight(explanation).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.text('Unisci')).dy),
    );
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('conferma cancellazione accessibile in landscape al 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(568, 320);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final products = _MemoryProductRepository([_product()]);
    await tester.pumpWidget(
      _app(
        const DataSettingsScreen(),
        settingsRepository: _MemorySettingsRepository(),
        productRepository: products,
      ),
    );
    await tester.pumpAndSettle();
    final clear = find.text('Cancella tutti i dati');
    await tester.scrollUntilVisible(clear, 200);
    await tester.pumpAndSettle();
    await tester.tap(clear);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Cancella').hitTestable(), findsOneWidget);
    await tester.tap(find.text('Annulla'));
    await tester.pumpAndSettle();
    expect(products.products, hasLength(1));
  });

  testWidgets(
    'regressione: cancellazione completa anche uscendo dalla schermata',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _AuditDelayedClearRepository([_product()]);
      final imageStorage = _FakeProductImageStorage();
      final settings = _MemorySettingsRepository()
        ..saved = AppSettings.defaults.copyWith(
          themePreference: AppThemePreference.light,
        );
      final scheduler = _FakeNotificationScheduler();
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const DataSettingsScreen(),
                  ),
                ),
                child: const Text('Apri dati audit'),
              ),
            ),
          ),
          settingsRepository: settings,
          scheduler: scheduler,
          productRepository: repo,
          imageStorage: imageStorage,
        ),
      );
      await tester.tap(find.text('Apri dati audit'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const Key('clear-data')), 250);
      await tester.tap(find.byKey(const Key('clear-data')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancella'));
      await tester.pump();
      expect(repo.started, isTrue);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Apri dati audit'), findsOneWidget);
      repo.release.complete();
      await tester.pumpAndSettle();
      expect(repo.products, isEmpty);
      expect(
        imageStorage.deleteAllCalls,
        1,
        reason:
            'La navigazione non deve interrompere la cancellazione gia confermata',
      );
      expect(settings.saved, AppSettings.defaults);
      expect(scheduler.synchronizeCalls, 1);
    },
  );
  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'FreshTrack',
      packageName: 'io.github.kaonashi98.freshtrack',
      version: '1.0.0',
      buildNumber: '3',
      buildSignature: '',
    );
  });

  testWidgets('la schermata principale è un hub essenziale', (tester) async {
    await tester.pumpWidget(
      _app(
        const Scaffold(body: SettingsScreen()),
        settingsRepository: _MemorySettingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aspetto'), findsOneWidget);
    expect(find.text('Notifiche'), findsOneWidget);
    expect(find.text('Dati e backup'), findsOneWidget);
    expect(find.text('Privacy e informazioni'), findsOneWidget);
    expect(find.text('Preavviso'), findsNothing);
    expect(find.byKey(const Key('clear-data')), findsNothing);
  });

  testWidgets('cambia tema nella pagina Aspetto', (tester) async {
    final repository = _MemorySettingsRepository();
    await tester.pumpWidget(
      _app(const AppearanceSettingsScreen(), settingsRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tema dell’app'), findsOneWidget);
    await tester.tap(find.text('Chiaro'));
    await tester.pumpAndSettle();

    expect(repository.saved.themePreference, AppThemePreference.light);
  });

  testWidgets('permette di scegliere manualmente la lingua inglese', (
    tester,
  ) async {
    final repository = _MemorySettingsRepository();
    await tester.pumpWidget(
      _app(const AppearanceSettingsScreen(), settingsRepository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('language-selector')), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(repository.saved.languagePreference, AppLanguagePreference.english);
  });

  testWidgets('richiede le notifiche solo dopo un gesto esplicito', (
    tester,
  ) async {
    final scheduler = _FakeNotificationScheduler(enabled: false);
    await tester.pumpWidget(
      _app(
        const NotificationSettingsScreen(),
        settingsRepository: _MemorySettingsRepository(),
        scheduler: scheduler,
      ),
    );
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 0);
    expect(find.byKey(const Key('enable-notifications')), findsOneWidget);
    await tester.tap(find.byKey(const Key('enable-notifications')));
    await tester.pumpAndSettle();

    expect(scheduler.permissionRequests, 1);
    expect(
      find.text('Attivi. Gli avvisi restano sul dispositivo.'),
      findsOneWidget,
    );
  });

  testWidgets('un diniego delle notifiche mantiene uno stato coerente', (
    tester,
  ) async {
    final scheduler = _FakeNotificationScheduler(
      enabled: false,
      grantPermission: false,
    );
    await tester.pumpWidget(
      _app(
        const NotificationSettingsScreen(),
        settingsRepository: _MemorySettingsRepository(),
        scheduler: scheduler,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('enable-notifications')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Permesso non concesso'), findsOneWidget);
    expect(scheduler.enabled, isFalse);
  });

  testWidgets('cancella prodotti immagini e preferenze dopo conferma', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final settingsRepository = _MemorySettingsRepository()
      ..saved = AppSettings.defaults.copyWith(
        themePreference: AppThemePreference.light,
        notificationDaysBefore: 4,
      );
    final productRepository = _MemoryProductRepository([_product()]);
    final imageStorage = _FakeProductImageStorage();
    final scheduler = _FakeNotificationScheduler();

    await tester.pumpWidget(
      _app(
        const DataSettingsScreen(),
        settingsRepository: settingsRepository,
        scheduler: scheduler,
        productRepository: productRepository,
        imageStorage: imageStorage,
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('clear-data')), 250);
    await tester.tap(find.byKey(const Key('clear-data')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Cancella'));
    await tester.pumpAndSettle();

    expect(productRepository.products, isEmpty);
    expect(imageStorage.deleteAllCalls, 1);
    expect(settingsRepository.saved, AppSettings.defaults);
    expect(scheduler.synchronizeCalls, 1);
    expect(find.text('Tutti i dati sono stati cancellati.'), findsOneWidget);
  });

  testWidgets('mostra privacy avvertenza e versione', (tester) async {
    await tester.pumpWidget(
      _app(
        const AboutSettingsScreen(),
        settingsRepository: _MemorySettingsRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('privacy-policy')), findsOneWidget);
    expect(
      find.byKey(const Key('open-food-facts-attribution')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('open-source-licenses')), findsOneWidget);
    expect(find.textContaining('Non è un dispositivo medico'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Versione 1.0.0 · build 3'), 250);
    expect(find.text('Versione 1.0.0 · build 3'), findsOneWidget);
  });
}

Widget _app(
  Widget home, {
  required AppSettingsRepository settingsRepository,
  ExpirationNotificationScheduler? scheduler,
  ProductRepository? productRepository,
  ProductImageStorage? imageStorage,
}) => ProviderScope(
  overrides: [
    appSettingsRepositoryProvider.overrideWithValue(settingsRepository),
    expirationNotificationSchedulerProvider.overrideWithValue(
      scheduler ?? _FakeNotificationScheduler(),
    ),
    if (productRepository != null)
      productRepositoryProvider.overrideWithValue(productRepository),
    if (imageStorage != null)
      productImageStorageProvider.overrideWithValue(imageStorage),
  ],
  child: MaterialApp(
    locale: const Locale('it'),
    supportedLocales: const [Locale('it'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: home,
  ),
);

class _FakeNotificationScheduler implements ExpirationNotificationScheduler {
  _FakeNotificationScheduler({
    this.enabled = true,
    this.grantPermission = true,
  });

  bool enabled;
  final bool grantPermission;
  int permissionRequests = 0;
  int synchronizeCalls = 0;

  @override
  Stream<CivilDate> get openedExpirationDates => const Stream.empty();

  @override
  Future<bool> areNotificationsEnabled() async => enabled;

  @override
  void dispose() {}

  @override
  Future<CivilDate?> initialize() async => null;

  @override
  Future<bool> requestNotificationPermission() async {
    permissionRequests++;
    enabled = grantPermission;
    return enabled;
  }

  @override
  Future<NotificationSynchronizationResult> synchronize(
    List<Product> products, {
    required int hour,
    required int minute,
    required int daysBefore,
    String languageCode = 'it',
  }) async {
    synchronizeCalls++;
    return const NotificationSynchronizationResult();
  }
}

class _MemorySettingsRepository implements AppSettingsRepository {
  AppSettings saved = AppSettings.defaults;

  @override
  Future<void> clear() async => saved = AppSettings.defaults;

  @override
  Future<AppSettings> load() async => saved;

  @override
  Future<void> save(AppSettings settings) async => saved = settings;
}

class _MemoryProductRepository implements ProductRepository {
  _MemoryProductRepository(this.products);
  final List<Product> products;

  @override
  Future<void> clear() async => products.clear();

  @override
  Future<void> replaceAll(List<Product> next) async {
    products
      ..clear()
      ..addAll(next);
  }

  @override
  Future<void> delete(String id) async {
    products.removeWhere((product) => product.id == id);
  }

  @override
  Future<List<Product>> getAll() async => products;

  @override
  Future<Product?> getById(String id) async {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<void> save(Product product) async {
    products.removeWhere((existing) => existing.id == product.id);
    products.add(product);
  }

  @override
  Stream<List<Product>> watchAll() => Stream.value(products);
}

class _FakeProductImageStorage extends ProductImageStorage {
  int deleteAllCalls = 0;

  @override
  Future<void> deleteAll() async => deleteAllCalls++;
}

Product _product() => Product(
  id: 'latte',
  name: 'Latte',
  category: ProductCategory.food,
  quantity: 1,
  unit: MeasurementUnit.liters,
  purchaseDate: CivilDate(2026, 8, 20),
  expirationDate: CivilDate(2026, 8, 25),
  status: ProductStatus.available,
  notificationDaysBefore: 0,
  createdAt: DateTime(2026, 8, 20),
  updatedAt: DateTime(2026, 8, 20),
);

class _AuditDelayedClearRepository extends _MemoryProductRepository {
  _AuditDelayedClearRepository(super.products);
  final release = Completer<void>();
  bool started = false;
  @override
  Future<void> clear() async {
    started = true;
    await release.future;
    await super.clear();
  }
}

class _PreviewService extends FreshTrackBackupService {
  _PreviewService()
    : super(
        productRepository: _MemoryProductRepository([]),
        settingsRepository: _MemorySettingsRepository(),
        imageStorage: _FakeProductImageStorage(),
      );

  @override
  Future<BackupPreview> inspectAsync(Uint8List bytes) async => BackupPreview(
    productCount: 3,
    imageCount: 1,
    exportedAt: DateTime(2026, 9, 7, 16, 23),
    appVersion: '1.0.0+7',
  );
}

class _BackupPicker extends FilePickerPlatform {
  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => _BackupFile();
}

final class _BackupFile extends PlatformFile {
  @override
  String get name => 'backup.zip';
  @override
  Uri get uri => Uri.parse('memory:backup.zip');
  @override
  Never get xFile => throw UnimplementedError();
  @override
  Future<int> length() async => 1;
  @override
  Future<Uint8List> readAsBytes() async => Uint8List.fromList([0]);
  @override
  Stream<Uint8List> readAsByteStream() => Stream.value(Uint8List.fromList([0]));
}
