import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/data/backup/freshtrack_backup_service.dart';
import 'package:freshtrack/data/backup/product_csv_export_service.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:freshtrack/presentation/providers/data_transfer_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/settings_providers.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:intl/intl.dart';

class DataSettingsScreen extends ConsumerStatefulWidget {
  const DataSettingsScreen({super.key});

  @override
  ConsumerState<DataSettingsScreen> createState() => _DataSettingsScreenState();
}

class _DataSettingsScreenState extends ConsumerState<DataSettingsScreen> {
  bool _busy = false;
  String? _operation;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('Dati e backup', 'Data and backup'))),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        _BenefitCard(
          icon: Icons.shield_outlined,
          title: context.tr(
            'Proteggi il tuo inventario',
            'Protect your inventory',
          ),
          description: context.tr(
            'Il backup include prodotti, preferenze e foto. Salvalo dove preferisci e potrai ripristinarlo anche dopo una reinstallazione.',
            'The backup includes products, preferences and photos. Save it wherever you prefer and restore it even after reinstalling.',
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.tr('Backup completo', 'Full backup'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        GlassSurface(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              _DataAction(
                key: const Key('create-backup'),
                icon: Icons.backup_outlined,
                title: context.tr('Crea backup', 'Create backup'),
                subtitle: context.tr(
                  'Un file ZIP con inventario, impostazioni e foto',
                  'A ZIP file with inventory, settings and photos',
                ),
                onTap: _busy ? null : _createBackup,
              ),
              const _DataDivider(),
              _DataAction(
                key: const Key('restore-backup'),
                icon: Icons.restore_rounded,
                title: context.tr('Ripristina backup', 'Restore backup'),
                subtitle: context.tr(
                  'Controlla il contenuto prima di importarlo',
                  'Review the contents before importing',
                ),
                onTap: _busy ? null : _restoreBackup,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.tr('Esportazione', 'Export'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        GlassSurface(
          padding: const EdgeInsets.all(8),
          child: _DataAction(
            key: const Key('export-csv'),
            icon: Icons.table_view_outlined,
            title: context.tr('Esporta CSV', 'Export CSV'),
            subtitle: context.tr(
              'Apri l’inventario con Excel o Fogli Google',
              'Open your inventory with Excel or Google Sheets',
            ),
            onTap: _busy ? null : _exportCsv,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          context.tr('Operazioni irreversibili', 'Irreversible actions'),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        GlassSurface(
          padding: const EdgeInsets.all(8),
          child: _DataAction(
            key: const Key('clear-data'),
            icon: Icons.delete_forever_outlined,
            title: context.tr('Cancella tutti i dati', 'Delete all data'),
            subtitle: context.tr(
              'Rimuove prodotti, immagini e preferenze dall’app',
              'Removes products, images and preferences from the app',
            ),
            color: AppTheme.dangerText(context),
            onTap: _busy ? null : _clearData,
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 18),
          const LinearProgressIndicator(),
          if (_operation != null) ...[
            const SizedBox(height: 8),
            Text(_operation!, textAlign: TextAlign.center),
          ],
        ],
      ],
    ),
  );

  Future<void> _createBackup() async {
    await _run(
      context.tr('Preparazione del backup…', 'Preparing backup…'),
      () async {
        final service = ref.read(freshTrackBackupServiceProvider);
        final appVersion = await ref.read(appVersionProvider.future);
        final bytes = await service.createBackup(appVersion: appVersion);
        if (!mounted) return;
        final uri = await FilePicker.saveFile(
          dialogTitle: context.tr(
            'Salva il backup FreshTrack',
            'Save FreshTrack backup',
          ),
          fileName: 'freshtrack-backup-${_fileTimestamp()}.zip',
          bytes: bytes,
          mimeType: 'application/zip',
        );
        if (uri != null && mounted) {
          _message(
            context.tr(
              'Backup salvato. Conservalo in un luogo sicuro.',
              'Backup saved. Keep it in a safe place.',
            ),
          );
        }
      },
    );
  }

  Future<void> _exportCsv() async {
    final strings = context.strings;
    await _run(context.tr('Preparazione del CSV…', 'Preparing CSV…'), () async {
      final products = await ref.read(productRepositoryProvider).getAll();
      final uri = await FilePicker.saveFile(
        dialogTitle: strings.text('Esporta l’inventario', 'Export inventory'),
        fileName: 'freshtrack-inventory-${_fileTimestamp()}.csv',
        bytes: ProductCsvExportService.encode(
          products,
          languageCode: strings.languageCode,
        ),
        mimeType: 'text/csv',
      );
      if (uri != null && mounted) {
        _message(
          context.tr(
            'Inventario esportato in CSV.',
            'Inventory exported to CSV.',
          ),
        );
      }
    });
  }

  Future<void> _restoreBackup() async {
    Uint8List? bytes;
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: context.tr(
          'Scegli un backup FreshTrack',
          'Choose a FreshTrack backup',
        ),
        type: FileType.custom,
        allowedExtensions: const ['zip'],
      );
      if (file == null || !mounted) return;
      final fileTooLarge =
          await file.length() > FreshTrackBackupService.maxBackupBytes;
      if (!mounted) return;
      if (fileTooLarge) {
        _message(
          context.tr(
            'Il backup supera il limite massimo di 250 MB.',
            'The backup exceeds the 250 MB limit.',
          ),
        );
        return;
      }
      bytes = await file.readAsBytes();
    } catch (_) {
      if (mounted) {
        _message(
          context.tr(
            'Non è stato possibile leggere il file scelto.',
            'The selected file could not be read.',
          ),
        );
      }
      return;
    }
    if (!mounted) return;

    late BackupPreview preview;
    try {
      preview = await ref
          .read(freshTrackBackupServiceProvider)
          .inspectAsync(bytes);
      if (!mounted) return;
    } on BackupFormatException catch (error) {
      if (mounted) _message(_backupError(error));
      return;
    } catch (_) {
      if (mounted) {
        _message(
          context.tr(
            'Il file non è un backup FreshTrack valido.',
            'The file is not a valid FreshTrack backup.',
          ),
        );
      }
      return;
    }
    final mode = await _chooseRestoreMode(preview);
    if (mode == null || !mounted) return;

    await _run(context.tr('Ripristino in corso…', 'Restoring…'), () async {
      final outcome = await ref
          .read(inventoryDataServiceProvider)
          .restore(bytes!, mode);
      final result = outcome.result;
      if (!outcome.notificationsComplete) {
        if (mounted) {
          _message(
            context.tr(
              'Dati ripristinati. Alcuni promemoria verranno aggiornati alla prossima apertura.',
              'Data restored. Some reminders will be updated the next time the app opens.',
            ),
          );
        }
        return;
      }
      if (mounted) {
        _message(
          context.tr(
            'Ripristino completato: ${_productCountLabelIt(result.productCount)} e ${_imageCountLabelIt(result.imageCount)}.',
            'Restore complete: ${_productCountLabelEn(result.productCount)} and ${_imageCountLabelEn(result.imageCount)}.',
          ),
        );
      }
    });
  }

  Future<BackupImportMode?> _chooseRestoreMode(
    BackupPreview preview,
  ) => showDialog<BackupImportMode>(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      title: Text(context.tr('Controlla il backup', 'Review backup')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.strings.isEnglish
                ? _productCountLabelEn(preview.productCount)
                : _productCountLabelIt(preview.productCount),
          ),
          Text(
            context.strings.isEnglish
                ? _imageCountLabelEn(preview.imageCount)
                : _imageCountLabelIt(preview.imageCount),
          ),
          Text(
            context.tr(
              'Creato il ${DateFormat('dd/MM/yyyy HH:mm').format(preview.exportedAt.toLocal())}',
              'Created on ${DateFormat.yMd('en').add_Hm().format(preview.exportedAt.toLocal())}',
            ),
          ),
          Text(preview.appVersion),
          const SizedBox(height: 14),
          Text(
            context.tr(
              'Unisci mantiene la versione più recente di ogni prodotto; a parità di data conserva quella attuale. Sostituisci rimuove i prodotti attuali e usa soltanto quelli del backup. In entrambi i casi vengono ripristinate anche le impostazioni.',
              'Merge keeps the newest version of each product; when dates match, it keeps the current one. Replace removes current products and uses only those in the backup. Both options also restore settings.',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('Annulla', 'Cancel')),
        ),
        FilledButton.tonal(
          key: const Key('merge-backup'),
          onPressed: () => Navigator.pop(context, BackupImportMode.merge),
          child: Text(context.tr('Unisci', 'Merge')),
        ),
        FilledButton(
          key: const Key('replace-backup'),
          onPressed: () => Navigator.pop(context, BackupImportMode.replace),
          child: Text(context.tr('Sostituisci', 'Replace')),
        ),
      ],
    ),
  );

  Future<void> _clearData() async {
    final choice = await showDialog<_ClearChoice>(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: Text(context.tr('Cancellare tutti i dati?', 'Delete all data?')),
        content: Text(
          context.tr(
            'Prodotti, scadenze, immagini e preferenze verranno rimossi definitivamente. Crea prima un backup se vuoi recuperarli.',
            'Products, expiration dates, images and preferences will be permanently removed. Create a backup first if you want to recover them.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Annulla', 'Cancel')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, _ClearChoice.backup),
            child: Text(context.tr('Crea backup', 'Create backup')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(context, _ClearChoice.delete),
            child: Text(context.tr('Cancella', 'Delete')),
          ),
        ],
      ),
    );
    if (choice == _ClearChoice.backup) {
      await _createBackup();
      return;
    }
    if (choice != _ClearChoice.delete || !mounted) return;

    await _run(context.tr('Cancellazione in corso…', 'Deleting…'), () async {
      final incomplete = await ref.read(inventoryDataServiceProvider).clear();
      if (!mounted) return;
      if (incomplete.isEmpty) {
        _message(
          context.tr(
            'Tutti i dati sono stati cancellati.',
            'All data has been deleted.',
          ),
        );
      } else {
        _message(
          context.tr(
            'Prodotti cancellati, ma non è stato possibile rimuovere ${incomplete.join(' e ')}. Riprova.',
            'Products deleted, but some related data could not be removed. Try again.',
          ),
        );
      }
    });
  }

  Future<void> _run(String label, Future<void> Function() operation) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _operation = label;
    });
    try {
      await operation();
    } on BackupFormatException catch (error) {
      if (mounted) _message(_backupError(error));
    } catch (_) {
      if (mounted) {
        _message(
          context.tr(
            'Operazione non riuscita. Riprova senza chiudere l’app.',
            'Operation failed. Try again without closing the app.',
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _operation = null;
        });
      }
    }
  }

  String _fileTimestamp() => DateFormat('yyyyMMdd-HHmm').format(DateTime.now());

  String _productCountLabelIt(int count) =>
      count == 1 ? '1 prodotto' : '$count prodotti';

  String _imageCountLabelIt(int count) =>
      count == 1 ? '1 immagine' : '$count immagini';

  String _productCountLabelEn(int count) =>
      count == 1 ? '1 product' : '$count products';
  String _imageCountLabelEn(int count) =>
      count == 1 ? '1 image' : '$count images';

  String _backupError(BackupFormatException error) => context.strings.isEnglish
      ? 'The backup is invalid, damaged, or incompatible.'
      : error.message;

  void _message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }
}

enum _ClearChoice { backup, delete }

class _BenefitCard extends StatelessWidget {
  const _BenefitCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => GlassSurface(
    padding: const EdgeInsets.all(18),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _DataAction extends StatelessWidget {
  const _DataAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: effectiveColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w700, color: color),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.chevron_right_rounded, color: effectiveColor),
    );
  }
}

class _DataDivider extends StatelessWidget {
  const _DataDivider();

  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    indent: 64,
    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: .3),
  );
}
