import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/domain/products/expiration_service.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    return products.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          _ErrorState(onRetry: () => ref.invalidate(productsProvider)),
      data: (items) {
        final now = DateTime.now();
        final available = items
            .where((product) => product.status == ProductStatus.available)
            .toList();
        final expiredProducts =
            items
                .where(
                  (product) => ExpirationService.isExpired(product, now: now),
                )
                .toList()
              ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
        final priorities =
            available.where((product) {
                final info = ExpirationService.evaluate(
                  expirationDate: product.expirationDate,
                  now: now,
                );
                return info.daysRemaining >= 0 && info.daysRemaining <= 7;
              }).toList()
              ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
        final dueSoon = priorities.length;
        final visiblePriorities = priorities.take(3).toList();
        final stats = <_DashboardStat>[
          (
            'Totali',
            items.length,
            Icons.inventory_2_rounded,
            AppTheme.primary,
            () => context.go('/products'),
          ),
          (
            'In scadenza',
            dueSoon,
            Icons.schedule_rounded,
            AppTheme.warning,
            () => _showProductsSheet(
              context,
              title: 'Prodotti in scadenza',
              description: 'Scadono entro i prossimi 7 giorni.',
              products: priorities,
            ),
          ),
          (
            'Scaduti',
            expiredProducts.length,
            Icons.warning_amber_rounded,
            AppTheme.danger,
            () => _showProductsSheet(
              context,
              title: 'Prodotti scaduti',
              description: 'Controlla ed elimina ciò che non serve più.',
              products: expiredProducts,
              allowDeletion: true,
            ),
          ),
        ];

        return CustomScrollView(
          key: const Key('dashboard-scroll'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 116),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'La tua dispensa',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scadenze e prodotti, tutto sotto controllo.',
                      key: const Key('dashboard-summary'),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _StatsPanel(stats: stats),
                    const SizedBox(height: 26),
                    Text(
                      'Priorità',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      priorities.length > 3
                          ? 'Le 3 scadenze più vicine dei prossimi 7 giorni.'
                          : 'Scadenze nei prossimi 7 giorni, dalla più vicina.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (priorities.isEmpty)
                      const _EmptyPriority()
                    else ...[
                      _PriorityPanel(products: visiblePriorities),
                      if (priorities.length > 3) ...[
                        const SizedBox(height: 12),
                        _ShowAllPrioritiesButton(
                          remainingCount:
                              priorities.length - visiblePriorities.length,
                          onPressed: () => context.go('/products'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showProductsSheet(
    BuildContext context, {
    required String title,
    required String description,
    required List<Product> products,
    bool allowDeletion = false,
  }) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DashboardProductsSheet(
        title: title,
        description: description,
        products: products,
        allowDeletion: allowDeletion,
      ),
    );
  }
}

typedef _DashboardStat = (String, int, IconData, Color, VoidCallback);

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({required this.stats});

  final List<_DashboardStat> stats;

  @override
  Widget build(BuildContext context) => GlassSurface(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 17),
    child: IntrinsicHeight(
      child: Row(
        children: [
          for (var index = 0; index < stats.length; index++) ...[
            Expanded(child: _StatItem(stat: stats[index])),
            if (index != stats.length - 1)
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: .38),
              ),
          ],
        ],
      ),
    ),
  );
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.stat});

  final _DashboardStat stat;

  @override
  Widget build(BuildContext context) {
    final keyName = switch (stat.$1) {
      'Totali' => 'total',
      'In scadenza' => 'due-soon',
      _ => 'expired',
    };
    return Semantics(
      button: true,
      label: '${stat.$1}: ${stat.$2}. Apri elenco.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: Key('dashboard-stat-$keyName'),
          onTap: stat.$5,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: stat.$4.withValues(alpha: .14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(stat.$3, color: stat.$4, size: 21),
                ),
                const SizedBox(height: 10),
                Text(
                  '${stat.$2}',
                  maxLines: 1,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat.$1,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriorityPanel extends StatelessWidget {
  const _PriorityPanel({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) => GlassSurface(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Column(
      children: [
        for (var index = 0; index < products.length; index++) ...[
          _PriorityRow(product: products[index]),
          if (index != products.length - 1)
            Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: .28),
            ),
        ],
      ],
    ),
  );
}

class _PriorityRow extends StatelessWidget {
  const _PriorityRow({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final info = ExpirationService.evaluate(
      expirationDate: product.expirationDate,
    );
    final (label, color) = switch (info.state) {
      ExpirationState.expired => ('Scaduto', AppTheme.danger),
      ExpirationState.expiresToday => ('Scade oggi', AppTheme.danger),
      ExpirationState.dueSoon => (
        'Tra ${info.daysRemaining} giorni',
        AppTheme.warning,
      ),
      ExpirationState.fresh => ('Sotto controllo', AppTheme.primary),
    };
    final day = product.expirationDate.day.toString().padLeft(2, '0');
    final month = product.expirationDate.month.toString().padLeft(2, '0');
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final dateTileSize = 50.0 + ((textScale - 1).clamp(0, 1) * 56);

    return InkWell(
      key: Key('priority-${product.id}'),
      onTap: () => context.push('/products/${product.id}'),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: dateTileSize,
              height: dateTileSize,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    month,
                    style: TextStyle(
                      color: color.withValues(alpha: .85),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$label · ${product.quantity.toStringAsFixed(product.quantity % 1 == 0 ? 0 : 1)} ${product.unit.label}',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardProductsSheet extends ConsumerStatefulWidget {
  const _DashboardProductsSheet({
    required this.title,
    required this.description,
    required this.products,
    required this.allowDeletion,
  });

  final String title;
  final String description;
  final List<Product> products;
  final bool allowDeletion;

  @override
  ConsumerState<_DashboardProductsSheet> createState() =>
      _DashboardProductsSheetState();
}

class _DashboardProductsSheetState
    extends ConsumerState<_DashboardProductsSheet> {
  late final List<Product> _products;
  final Set<String> _deletingIds = {};
  bool _deletingAll = false;

  @override
  void initState() {
    super.initState();
    _products = List.of(widget.products)
      ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
  }

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: .78,
    child: GlassSurface(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Chiudi',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          if (widget.allowDeletion && _products.isNotEmpty) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              key: const Key('delete-all-expired'),
              onPressed: _deletingAll ? null : _deleteAll,
              icon: _deletingAll
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_sweep_outlined),
              label: const Text('Elimina tutti gli scaduti'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: .5),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: _products.isEmpty
                ? _SheetEmptyState(isExpired: widget.allowDeletion)
                : ListView.separated(
                    key: const Key('dashboard-products-sheet'),
                    itemCount: _products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final product = _products[index];
                      return _SheetProductRow(
                        product: product,
                        onTap: () => _openProduct(product),
                        onDelete: widget.allowDeletion
                            ? () => _deleteOne(product)
                            : null,
                        deleting: _deletingIds.contains(product.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );

  void _openProduct(Product product) {
    final router = GoRouter.of(context);
    Navigator.pop(context);
    router.push('/products/${product.id}');
  }

  Future<void> _deleteOne(Product product) async {
    final confirmed = await _confirmDelete(
      title: 'Eliminare ${product.name}?',
      message:
          'Il prodotto e la sua fotografia verranno rimossi definitivamente.',
      confirmLabel: 'Elimina',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deletingIds.add(product.id));
    try {
      await _deleteProduct(product);
      if (!mounted) return;
      setState(() => _products.removeWhere((item) => item.id == product.id));
      _showMessage('${product.name} eliminato.');
    } catch (_) {
      if (mounted) _showMessage('Eliminazione non riuscita. Riprova.');
    } finally {
      if (mounted) setState(() => _deletingIds.remove(product.id));
    }
  }

  Future<void> _deleteAll() async {
    final count = _products.length;
    final confirmed = await _confirmDelete(
      title: 'Eliminare tutti i prodotti scaduti?',
      message:
          '$count ${count == 1 ? 'prodotto verrà rimosso' : 'prodotti verranno rimossi'} definitivamente.',
      confirmLabel: 'Elimina tutti',
    );
    if (!confirmed || !mounted) return;

    setState(() => _deletingAll = true);
    final deletedIds = <String>[];
    for (final product in List<Product>.of(_products)) {
      try {
        await _deleteProduct(product);
        deletedIds.add(product.id);
      } catch (_) {
        // Gli eventuali elementi non eliminati restano visibili per un nuovo tentativo.
      }
    }
    if (!mounted) return;
    setState(() {
      _products.removeWhere((product) => deletedIds.contains(product.id));
      _deletingAll = false;
    });
    final failures = count - deletedIds.length;
    _showMessage(
      failures == 0
          ? 'Prodotti scaduti eliminati.'
          : '$failures prodotti non sono stati eliminati. Riprova.',
    );
  }

  Future<void> _deleteProduct(Product product) async {
    await ref.read(productRepositoryProvider).delete(product.id);
    try {
      await ref.read(productImageStorageProvider).delete(product.imagePath);
    } catch (_) {
      // Il record resta eliminato anche se il file era già assente.
    }
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
    required String confirmLabel,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Annulla'),
            ),
            FilledButton(
              key: const Key('confirm-dashboard-delete'),
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: Text(confirmLabel),
            ),
          ],
        ),
      ) ??
      false;

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SheetProductRow extends StatelessWidget {
  const _SheetProductRow({
    required this.product,
    required this.onTap,
    required this.onDelete,
    required this.deleting,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    final info = ExpirationService.evaluate(
      expirationDate: product.expirationDate,
    );
    final (label, color) = switch (info.state) {
      ExpirationState.expired => ('Scaduto', AppTheme.danger),
      ExpirationState.expiresToday => ('Scade oggi', AppTheme.danger),
      ExpirationState.dueSoon => (
        'Tra ${info.daysRemaining} giorni',
        AppTheme.warning,
      ),
      ExpirationState.fresh => ('Sotto controllo', AppTheme.primary),
    };

    return Material(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: .45),
      borderRadius: BorderRadius.circular(18),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              key: Key('sheet-product-${product.id}'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: .13),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        product.category == ProductCategory.medicines
                            ? Icons.medication_rounded
                            : Icons.restaurant_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$label · ${DateFormat('dd/MM/yyyy').format(product.expirationDate.toLocalDateTime())}',
                            style: TextStyle(
                              color: color,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onDelete == null)
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (onDelete != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton.filledTonal(
                key: Key('delete-expired-${product.id}'),
                tooltip: 'Elimina ${product.name}',
                onPressed: deleting ? null : onDelete,
                icon: deleting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetEmptyState extends StatelessWidget {
  const _SheetEmptyState({required this.isExpired});

  final bool isExpired;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            size: 54,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            isExpired
                ? 'Nessun prodotto scaduto'
                : 'Nessun prodotto in scadenza',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

class _ShowAllPrioritiesButton extends StatelessWidget {
  const _ShowAllPrioritiesButton({
    required this.remainingCount,
    required this.onPressed,
  });

  final int remainingCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final description = remainingCount == 1
        ? 'C’è un altro prodotto in scadenza nei prossimi 7 giorni.'
        : 'Ci sono altri $remainingCount prodotti in scadenza nei prossimi 7 giorni.';

    return FilledButton.tonal(
      key: const Key('show-all-priorities'),
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_available_rounded, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mostra tutti',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.onSecondaryContainer,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSecondaryContainer.withValues(alpha: .78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_rounded),
        ],
      ),
    );
  }
}

class _EmptyPriority extends StatelessWidget {
  const _EmptyPriority();

  @override
  Widget build(BuildContext context) => GlassSurface(
    padding: const EdgeInsets.all(22),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nessuna urgenza',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 3),
              Text('Le scadenze entro 7 giorni compariranno qui.'),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: GlassSurface(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            const Text('Non è stato possibile caricare i prodotti'),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Riprova'),
            ),
          ],
        ),
      ),
    ),
  );
}
