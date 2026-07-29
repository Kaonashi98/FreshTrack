import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/domain/products/expiration_service.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = ref.watch(productByIdProvider(productId));
    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio prodotto')),
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
                  ref.invalidate(productByIdProvider(item.id));
                },
                onDelete: () => _delete(context, ref, item),
              ),
      ),
    );
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
            title: const Text('Eliminare il prodotto?'),
            content: Text('${product.name} verrà rimosso definitivamente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Elimina'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(productRepositoryProvider).delete(product.id);
      try {
        await ref.read(productImageStorageProvider).delete(product.imagePath);
      } catch (_) {
        // La rimozione del record resta valida anche se il file è già assente.
      }
      if (context.mounted) {
        context.go('/products');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Prodotto eliminato.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminazione non riuscita.')),
        );
      }
    }
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        _ProductHero(product: product),
        const SizedBox(height: 22),
        Text(
          product.name,
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
          'Informazioni',
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
                _DetailRow(label: 'Categoria', value: product.category.label),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Quantità',
                  value:
                      '${product.quantity.toStringAsFixed(product.quantity % 1 == 0 ? 0 : 1)} ${product.unit.label}',
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Acquistato il',
                  value: dateFormat.format(product.purchaseDate),
                ),
                const Divider(height: 24),
                _DetailRow(
                  label: 'Scade il',
                  value: dateFormat.format(product.expirationDate),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _ProductActions(onEdit: onEdit, onDelete: onDelete),
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
                  label: 'Apri foto di ${product.name}',
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
        backgroundColor: const Color(0xFF020817),
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
                    tooltip: 'Chiudi foto',
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
      expirationDate: product.expirationDate,
    );
    final (icon, label, color) = switch (product.status) {
      ProductStatus.consumed => (
        Icons.check_circle_outline_rounded,
        'Prodotto consumato',
        Theme.of(context).colorScheme.primary,
      ),
      ProductStatus.discarded => (
        Icons.delete_outline_rounded,
        'Prodotto buttato',
        Theme.of(context).colorScheme.error,
      ),
      ProductStatus.expired => (
        Icons.warning_amber_rounded,
        'Questo prodotto è scaduto',
        Theme.of(context).colorScheme.error,
      ),
      ProductStatus.available => switch (info.state) {
        ExpirationState.expired => (
          Icons.warning_amber_rounded,
          'Questo prodotto è scaduto',
          Theme.of(context).colorScheme.error,
        ),
        ExpirationState.expiresToday => (
          Icons.schedule_rounded,
          'Questo prodotto scade oggi',
          const Color(0xFFF05D67),
        ),
        ExpirationState.dueSoon => (
          Icons.schedule_rounded,
          'Scade tra ${info.daysRemaining} giorni',
          const Color(0xFFF59E0B),
        ),
        ExpirationState.fresh => (
          Icons.eco_outlined,
          'Scadenza sotto controllo',
          Theme.of(context).colorScheme.primary,
        ),
      },
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
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
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ],
  );
}

class _ProductActions extends StatelessWidget {
  const _ProductActions({required this.onEdit, required this.onDelete});

  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: FilledButton.icon(
          key: const Key('edit-product'),
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Modifica'),
        ),
      ),

      const SizedBox(width: 4),
      IconButton(
        key: const Key('delete-product'),
        tooltip: 'Elimina prodotto',
        onPressed: onDelete,
        color: Theme.of(context).colorScheme.error,
        icon: const Icon(Icons.delete_outline_rounded),
      ),
    ],
  );
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
        const Text('Impossibile caricare il prodotto.'),
        const SizedBox(height: 12),
        FilledButton.tonal(onPressed: onRetry, child: const Text('Riprova')),
      ],
    ),
  );
}

class _NotFoundState extends StatelessWidget {
  const _NotFoundState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.search_off_rounded, size: 56),
        SizedBox(height: 12),
        Text('Prodotto non trovato'),
      ],
    ),
  );
}
