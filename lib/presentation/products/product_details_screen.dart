import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/shared/widgets/product_card.dart';
import 'dart:io';
import 'package:freshtrack/domain/common/async_mutex.dart';

import 'package:flutter/material.dart';
import 'package:freshtrack/shared/widgets/current_date_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/domain/products/expiration_service.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

bool _usesConsumedCopy(ProductCategory category) =>
    category == ProductCategory.food || category == ProductCategory.beverages;

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Dettaglio prodotto', 'Product details')),
      ),
      body: product.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _ErrorState(
          onRetry: () => ref.invalidate(productByIdProvider(productId)),
        ),
        data: (item) => item == null
            ? const _NotFoundState()
            : _ProductDetails(
                product: item,
                onEdit: () async {
                  await context.push('/products/${item.id}/edit');
                  if (context.mounted) {
                    ref.invalidate(productByIdProvider(item.id));
                  }
                },
                onDuplicate: () => context.push(
                  '/products/new?template=${Uri.encodeQueryComponent(item.id)}',
                ),
                onComplete: () =>
                    _updateStatus(context, ref, item, ProductStatus.consumed),
                onDiscard: () => _confirmDiscard(context, ref, item),
                onRestore: () =>
                    _updateStatus(context, ref, item, ProductStatus.available),
                onDelete: () => _delete(context, ref, item),
              ),
      ),
    );
  }

  Future<void> _confirmDiscard(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: Text(
              context.tr(
                'Segnare il prodotto come buttato?',
                'Mark this product as discarded?',
              ),
            ),
            content: Text(
              context.tr(
                '${product.name} resterà nell’elenco con lo stato Buttato.',
                '${product.name} will remain in the list with the Discarded status.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('Annulla', 'Cancel')),
              ),
              FilledButton(
                key: const Key('confirm-discard-product'),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  context.tr('Segna come buttato', 'Mark as discarded'),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;
    await _updateStatus(context, ref, product, ProductStatus.discarded);
  }

  Future<void> _updateStatus(
    BuildContext context,
    WidgetRef ref,
    Product product,
    ProductStatus status,
  ) async {
    final repository = ref.read(productRepositoryProvider);
    final synchronization = ref.read(notificationSynchronizationProvider);
    try {
      await mutationLockFor(repository).run(() async {
        final current = await repository.getById(product.id);
        if (current == null) throw StateError('Prodotto rimosso');
        await repository.save(
          current.copyWith(status: status, updatedAt: DateTime.now()),
        );
      });
      var notificationsComplete = true;
      try {
        final result = await synchronization.synchronizeLatest();
        notificationsComplete = result.isComplete;
      } catch (_) {
        notificationsComplete = false;
      }
      if (!context.mounted) return;
      ref.invalidate(productByIdProvider(product.id));

      final message = switch (status) {
        ProductStatus.consumed =>
          _usesConsumedCopy(product.category)
              ? context.tr(
                  'Prodotto segnato come consumato.',
                  'Product marked as consumed.',
                )
              : context.tr(
                  'Prodotto segnato come utilizzato.',
                  'Product marked as used.',
                ),
        ProductStatus.discarded => context.tr(
          'Prodotto segnato come buttato.',
          'Product marked as discarded.',
        ),
        ProductStatus.available => context.tr(
          'Prodotto ripristinato come disponibile.',
          'Product restored as available.',
        ),
        ProductStatus.expired => context.tr(
          'Stato del prodotto aggiornato.',
          'Product status updated.',
        ),
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            notificationsComplete
                ? message
                : '$message ${context.tr('Alcuni promemoria non sono stati aggiornati.', 'Some reminders were not updated.')}',
          ),
        ),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Aggiornamento non riuscito. Riprova.',
                'Update failed. Try again.',
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            scrollable: true,
            title: Text(
              context.tr('Eliminare il prodotto?', 'Delete product?'),
            ),
            content: Text(
              context.tr(
                '${product.name} verrà rimosso definitivamente.',
                '${product.name} will be permanently removed.',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.tr('Annulla', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(context.tr('Elimina', 'Delete')),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;

    final repository = ref.read(productRepositoryProvider);
    final images = ref.read(productImageStorageProvider);
    final synchronization = ref.read(notificationSynchronizationProvider);
    try {
      await mutationLockFor(repository).run(() async {
        final current = await repository.getById(product.id);
        await repository.delete(product.id);
        try {
          await images.delete(current?.imagePath ?? product.imagePath);
        } catch (_) {
          /* The record is already removed. */
        }
      });
      var notificationsComplete = true;
      try {
        final result = await synchronization.synchronizeLatest();
        notificationsComplete = result.isComplete;
      } catch (_) {
        notificationsComplete = false;
      }
      if (context.mounted) {
        context.go('/products');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              notificationsComplete
                  ? context.tr('Prodotto eliminato.', 'Product deleted.')
                  : context.tr(
                      'Prodotto eliminato, ma alcuni promemoria non sono stati aggiornati.',
                      'Product deleted, but some reminders were not updated.',
                    ),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('Eliminazione non riuscita.', 'Deletion failed.'),
            ),
          ),
        );
      }
    }
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({
    required this.product,
    required this.onEdit,
    required this.onDuplicate,
    required this.onComplete,
    required this.onDiscard,
    required this.onRestore,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onComplete;
  final VoidCallback onDiscard;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMd(context.strings.languageCode);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        if (product.imagePath != null) ...[
          _ProductHero(product: product),
          const SizedBox(height: 22),
        ],
        if (product.imagePath == null) ...[
          Center(child: ProductThumbnail(product: product, size: 76)),
          const SizedBox(height: 16),
        ],
        Text(
          product.name,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        if (product.description case final description?) ...[
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyLarge),
        ],
        const SizedBox(height: 18),
        _ExpirationBanner(product: product),
        const SizedBox(height: 24),
        Text(
          context.tr('Informazioni', 'Information'),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _DetailRow(
                  label: context.tr('Categoria', 'Category'),
                  value: product.category.localizedLabel(
                    context.strings.languageCode,
                  ),
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: context.tr('Quantità', 'Quantity'),
                  value:
                      '${product.quantityText} ${product.unit.localizedLabel(context.strings.languageCode)}',
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: context.tr('Acquistato il', 'Purchased on'),
                  value: dateFormat.format(
                    product.purchaseDate.toLocalDateTime(),
                  ),
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: context.tr('Scade il', 'Expires on'),
                  value: dateFormat.format(
                    product.expirationDate.toLocalDateTime(),
                  ),
                ),
                if (product.barcode case final barcode?) ...[
                  const Divider(height: 24),
                  _DetailRow(label: 'Barcode', value: barcode),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ProductActions(
          product: product,
          onEdit: onEdit,
          onDuplicate: onDuplicate,
          onComplete: onComplete,
          onDiscard: onDiscard,
          onRestore: onRestore,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _ProductHero extends StatelessWidget {
  const _ProductHero({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final imagePath = product.imagePath;
    final fallback = const Center(
      child: Icon(Icons.inventory_2_outlined, size: 72),
    );
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: imagePath == null
              ? fallback
              : Semantics(
                  button: true,
                  label: context.tr(
                    'Apri foto di ${product.name}',
                    'Open photo of ${product.name}',
                  ),
                  child: InkWell(
                    key: const Key('open-product-image'),
                    onTap: () => _openImage(context, imagePath),
                    child: Image.file(
                      File(imagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => fallback,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  void _openImage(BuildContext context, String imagePath) {
    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: const Color(0xFF0C192B),
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined, size: 72),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IconButton.filled(
                    key: const Key('close-product-image'),
                    tooltip: context.tr('Chiudi foto', 'Close photo'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpirationBanner extends StatelessWidget {
  const _ExpirationBanner({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final info = ExpirationService.evaluate(
      now: CurrentDateScope.now(context),
      expirationDate: product.expirationDate,
    );
    final (icon, label, color) = switch (product.status) {
      ProductStatus.consumed => (
        Icons.check_circle_outline_rounded,
        _usesConsumedCopy(product.category)
            ? context.tr('Prodotto consumato', 'Product consumed')
            : context.tr('Prodotto utilizzato', 'Product used'),
        Theme.of(context).colorScheme.primary,
      ),
      ProductStatus.discarded => (
        Icons.delete_outline_rounded,
        context.tr('Prodotto buttato', 'Product discarded'),
        Theme.of(context).colorScheme.error,
      ),
      ProductStatus.expired => (
        Icons.warning_amber_rounded,
        context.tr('Questo prodotto è scaduto', 'This product has expired'),
        Theme.of(context).colorScheme.error,
      ),
      ProductStatus.available => switch (info.state) {
        ExpirationState.expired => (
          Icons.warning_amber_rounded,
          context.tr('Questo prodotto è scaduto', 'This product has expired'),
          Theme.of(context).colorScheme.error,
        ),
        ExpirationState.expiresToday => (
          Icons.schedule_rounded,
          context.tr(
            'Questo prodotto scade oggi',
            'This product expires today',
          ),
          AppTheme.dangerText(context),
        ),
        ExpirationState.dueSoon => (
          Icons.schedule_rounded,
          info.daysRemaining == 1
              ? context.tr('Scade domani', 'Expires tomorrow')
              : context.tr(
                  'Scade tra ${info.daysRemaining} giorni',
                  'Expires in ${info.daysRemaining} days',
                ),
          AppTheme.warningText(context),
        ),
        ExpirationState.fresh => (
          Icons.eco_outlined,
          context.tr('Scadenza sotto controllo', 'Expiration under control'),
          Theme.of(context).colorScheme.primary,
        ),
      },
    };
    final date = product.expirationDate.toLocalDateTime();
    final text = Theme.of(context).textTheme;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color:
            product.status == ProductStatus.available && info.daysRemaining >= 0
            ? AppTheme.warningSurface(context)
            : color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (!largeText) ...[
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat(
                    'd MMMM yyyy',
                    context.strings.languageCode,
                  ).format(date),
                  style: text.titleLarge?.copyWith(color: color),
                ),
                const SizedBox(height: 5),
                Text(label, style: text.bodySmall?.copyWith(color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label)),
      const SizedBox(width: 16),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    ],
  );
}

class _ProductActions extends StatelessWidget {
  const _ProductActions({
    required this.product,
    required this.onEdit,
    required this.onDuplicate,
    required this.onComplete,
    required this.onDiscard,
    required this.onRestore,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onComplete;
  final VoidCallback onDiscard;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final available = product.status == ProductStatus.available;
    final completeLabel = _usesConsumedCopy(product.category)
        ? context.tr('Segna come consumato', 'Mark as consumed')
        : context.tr('Segna come utilizzato', 'Mark as used');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (available) ...[
          FilledButton.icon(
            key: const Key('complete-product'),
            onPressed: onComplete,
            icon: const Icon(Icons.task_alt_rounded),
            label: Text(completeLabel),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            key: const Key('discard-product'),
            onPressed: onDiscard,
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            icon: const Icon(Icons.delete_sweep_outlined),
            label: Text(context.tr('Segna come buttato', 'Mark as discarded')),
          ),
        ] else
          FilledButton.tonalIcon(
            key: const Key('restore-product'),
            onPressed: onRestore,
            icon: const Icon(Icons.restore_rounded),
            label: Text(
              context.tr('Ripristina come disponibile', 'Restore as available'),
            ),
          ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                key: const Key('edit-product'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.secondaryContainer,
                  foregroundColor: Theme.of(
                    context,
                  ).colorScheme.onSecondaryContainer,
                ),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(context.tr('Modifica', 'Edit')),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filledTonal(
              key: const Key('duplicate-product'),
              tooltip: context.tr('Duplica prodotto', 'Duplicate product'),
              onPressed: onDuplicate,
              icon: const Icon(Icons.copy_all_outlined),
            ),
            const SizedBox(width: 2),
            IconButton(
              key: const Key('delete-product'),
              tooltip: context.tr('Elimina prodotto', 'Delete product'),
              onPressed: onDelete,
              color: Theme.of(context).colorScheme.error,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, size: 56),
        const SizedBox(height: 12),
        Text(
          context.tr(
            'Impossibile caricare il prodotto.',
            'Product could not be loaded.',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: onRetry,
          child: Text(context.tr('Riprova', 'Try again')),
        ),
      ],
    ),
  );
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.search_off_rounded, size: 56),
        const SizedBox(height: 12),
        Text(context.tr('Prodotto non trovato', 'Product not found')),
      ],
    ),
  );
}
