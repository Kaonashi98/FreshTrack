import 'package:freshtrack/domain/notifications/expiration_notification_scheduler.dart';
import 'package:freshtrack/domain/common/async_mutex.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/domain/products/expiration_service.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/presentation/providers/notification_providers.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:freshtrack/shared/widgets/current_date_scope.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:freshtrack/shared/widgets/page_heading.dart';
import 'package:freshtrack/shared/widgets/product_card.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(productsProvider)
      .when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            _ErrorState(onRetry: () => ref.invalidate(productsProvider)),
        data: (items) {
          final now = CurrentDateScope.now(context);
          final available =
              items.where((p) => p.status == ProductStatus.available).toList()
                ..sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
          int days(Product p) => ExpirationService.evaluate(
            expirationDate: p.expirationDate,
            now: now,
          ).daysRemaining;
          final expired = items
              .where((p) => ExpirationService.isExpired(p, now: now))
              .toList();
          final today = available.where((p) => days(p) == 0).toList();
          final upcoming = available
              .where((p) => days(p) > 0 && days(p) <= 7)
              .toList();
          final priorities = [...today, ...upcoming];
          return CustomScrollView(
            key: const Key('dashboard-scroll'),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      PageHeading(
                        title: context.tr('Cosa scade?', 'What expires next?'),
                        eyebrow: DateFormat(
                          'EEEE d MMMM',
                          context.strings.languageCode,
                        ).format(now),
                        eyebrowKey: const Key('dashboard-summary'),
                        subtitle: priorities.isEmpty
                            ? context.tr(
                                'Le prossime scadenze sono sotto controllo.',
                                'Your upcoming expirations are under control.',
                              )
                            : context.strings.isEnglish
                            ? '${priorities.length} ${priorities.length == 1 ? 'product' : 'products'} to keep an eye on this week.'
                            : '${priorities.length} ${priorities.length == 1 ? 'prodotto' : 'prodotti'} da tenere d’occhio questa settimana.',
                      ),
                      if (expired.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Material(
                          key: const Key('review-expired-products'),
                          color: AppTheme.dangerSurface(context),
                          borderRadius: BorderRadius.circular(13),
                          child: InkWell(
                            key: const Key('dashboard-stat-expired'),
                            borderRadius: BorderRadius.circular(13),
                            onTap: () => _showProductsSheet(
                              context,
                              title: context.tr(
                                'Prodotti scaduti',
                                'Expired products',
                              ),
                              description: context.tr(
                                'Controlla e aggiorna i prodotti scaduti.',
                                'Review and update expired products.',
                              ),
                              products: expired,
                              allowDeletion: true,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline_rounded,
                                    size: 20,
                                    color: AppTheme.dangerText(context),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      context.strings.isEnglish
                                          ? '${expired.length} expired ${expired.length == 1 ? 'product' : 'products'} to review'
                                          : '${expired.length} ${expired.length == 1 ? 'prodotto scaduto' : 'prodotti scaduti'} da controllare',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppTheme.dangerText(context),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 20,
                                    color: AppTheme.dangerText(context),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _SectionHeading(
                        title: context.tr('In scadenza oggi', 'Expiring today'),
                        trailing: Text(
                          DateFormat(
                            'd MMM',
                            context.strings.languageCode,
                          ).format(now),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (today.isEmpty)
                        _QuietState(
                          firstProduct: items.isEmpty,
                          title: items.isEmpty
                              ? context.tr(
                                  'Inizia dalla prima scadenza',
                                  'Start with your first expiration',
                                )
                              : context.tr(
                                  'Nessuna scadenza oggi',
                                  'Nothing expires today',
                                ),
                          description: items.isEmpty
                              ? context.tr(
                                  'Tocca Aggiungi per registrare il primo prodotto.',
                                  'Tap Add to record your first product.',
                                )
                              : context.tr(
                                  'Qui trovi i prodotti in scadenza nella giornata.',
                                  'Products expiring today will appear here.',
                                ),
                        ),
                      for (final product in today) ...[
                        GlassSurface(
                          padding: const EdgeInsets.all(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.warningSurface(context),
                                      borderRadius: BorderRadius.circular(7),
                                    ),
                                    child: Text(
                                      context.tr('Scade oggi', 'Expires today'),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppTheme.warningText(
                                              context,
                                            ),
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    product.category.localizedLabel(
                                      context.strings.languageCode,
                                    ),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              ProductCard(
                                product: product,
                                embedded: true,
                                showDate: false,
                                onTap: () =>
                                    context.push('/products/${product.id}'),
                              ),
                              FilledButton.tonalIcon(
                                key: Key('complete-today-${product.id}'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                                onPressed: () =>
                                    _complete(context, ref, product),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: Text(
                                  product.isConsumable
                                      ? context.tr(
                                          'Segna consumato',
                                          'Mark as consumed',
                                        )
                                      : context.tr(
                                          'Segna utilizzato',
                                          'Mark as used',
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 18),
                      _SectionHeading(
                        title: context.tr(
                          'Nei prossimi giorni',
                          'In the next few days',
                        ),
                        trailing: TextButton(
                          key: const Key('dashboard-stat-due-soon'),
                          onPressed: () => _showProductsSheet(
                            context,
                            title: context.tr(
                              'Prodotti in scadenza',
                              'Products expiring soon',
                            ),
                            description: context.tr(
                              'Scadono entro i prossimi 7 giorni.',
                              'They expire within the next 7 days.',
                            ),
                            products: priorities,
                          ),
                          child: Text(context.tr('Vedi tutti', 'View all')),
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (upcoming.isEmpty)
                        _QuietState(
                          title: expired.isEmpty && today.isEmpty
                              ? context.tr('Nessuna urgenza', 'Nothing urgent')
                              : context.tr(
                                  'Nessun’altra scadenza vicina',
                                  'No other upcoming expirations',
                                ),
                          description: context.tr(
                            'Nessun prodotto in scadenza nei prossimi 7 giorni.',
                            'No products expire within the next 7 days.',
                          ),
                        )
                      else
                        GlassSurface(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Column(
                            children: [
                              for (
                                var i = 0;
                                i < upcoming.take(3).length;
                                i++
                              ) ...[
                                if (i > 0) const Divider(height: 1),
                                ProductCard(
                                  product: upcoming[i],
                                  embedded: true,
                                  onTap: () => context.push(
                                    '/products/${upcoming[i].id}',
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      if (upcoming.length > 3)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            key: const Key('show-all-priorities'),
                            onPressed: () => _showProductsSheet(
                              context,
                              title: context.tr(
                                'Prodotti in scadenza',
                                'Products expiring soon',
                              ),
                              description: context.tr(
                                'Scadono entro i prossimi 7 giorni.',
                                'They expire within the next 7 days.',
                              ),
                              products: priorities,
                            ),
                            child: Text(
                              context.tr(
                                'Mostra altri ${upcoming.length - 3}',
                                'Show ${upcoming.length - 3} more',
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Center(
                        child: TextButton(
                          key: const Key('dashboard-stat-total'),
                          onPressed: () => context.go('/products'),
                          child: Text(
                            context.tr(
                              'Tutti i prodotti (${items.length})',
                              'All products (${items.length})',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );

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

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    Product product,
  ) async {
    final repository = ref.read(productRepositoryProvider);
    final synchronization = ref.read(notificationSynchronizationProvider);
    try {
      final saved = await mutationLockFor(repository).run(() async {
        final current = await repository.getById(product.id);
        if (current == null || current.status != ProductStatus.available) {
          return null;
        }
        final next = current.copyWith(
          status: ProductStatus.consumed,
          updatedAt: DateTime.now(),
        );
        await repository.save(next);
        // Compare the persisted revision: SQLite normalizes timestamp precision.
        return repository.getById(next.id);
      });
      if (saved == null) return;
      ref.invalidate(productByIdProvider(product.id));
      final result = await synchronization.synchronizeLatest().catchError(
        (_) => const NotificationSynchronizationResult(failed: 1),
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.strings.isEnglish
                ? '${product.name} marked as ${product.isConsumable ? 'consumed' : 'used'}.${result.isComplete ? '' : ' Some reminders were not updated.'}'
                : '${product.name} ${product.isConsumable ? 'consumato' : 'utilizzato'}.${result.isComplete ? '' : ' Alcuni promemoria non sono stati aggiornati.'}',
          ),
          action: SnackBarAction(
            label: context.tr('Annulla', 'Undo'),
            onPressed: () async {
              try {
                final restored = await mutationLockFor(repository).run(() async {
                  final current = await repository.getById(saved.id);
                  // Do not overwrite a later edit or recreate a deleted product.
                  if (current == null ||
                      current.updatedAt != saved.updatedAt ||
                      current.status != saved.status ||
                      current.name != saved.name ||
                      current.description != saved.description ||
                      current.quantity != saved.quantity ||
                      current.unit != saved.unit ||
                      current.category != saved.category ||
                      current.expirationDate != saved.expirationDate ||
                      current.purchaseDate != saved.purchaseDate ||
                      current.barcode != saved.barcode ||
                      current.imagePath != saved.imagePath ||
                      current.notificationDaysBefore !=
                          saved.notificationDaysBefore) {
                    return false;
                  }
                  await repository.save(
                    current.copyWith(
                      status: ProductStatus.available,
                      updatedAt: DateTime.now(),
                    ),
                  );
                  return true;
                });
                final sync = restored
                    ? await synchronization.synchronizeLatest().catchError(
                        (_) =>
                            const NotificationSynchronizationResult(failed: 1),
                      )
                    : null;
                if (!context.mounted) return;
                ref.invalidate(productByIdProvider(product.id));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      !restored
                          ? context.tr(
                              'Il prodotto è stato modificato: aprilo per verificarne lo stato.',
                              'The product was modified: open it to check its status.',
                            )
                          : sync!.isComplete
                          ? context.tr('Modifica annullata.', 'Change undone.')
                          : context.tr(
                              'Modifica annullata. Alcuni promemoria non sono stati aggiornati.',
                              'Change undone. Some reminders were not updated.',
                            ),
                    ),
                  ),
                );
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        context.tr(
                          'Ripristino non riuscito. Riprova dal prodotto.',
                          'Could not restore the product. Try again from its details.',
                        ),
                      ),
                    ),
                  );
                }
              }
            },
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
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.trailing});
  final String title;
  final Widget trailing;
  @override
  Widget build(BuildContext context) =>
      MediaQuery.textScalerOf(context).scale(14) > 18
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Align(alignment: Alignment.centerRight, child: trailing),
          ],
        )
      : Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(width: 8),
            trailing,
          ],
        );
}

class _QuietState extends StatelessWidget {
  const _QuietState({
    required this.title,
    required this.description,
    this.firstProduct = false,
  });
  final String title;
  final String description;
  final bool firstProduct;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = firstProduct
        ? scheme.onPrimaryContainer
        : scheme.onSecondaryContainer;
    final iconColor = firstProduct ? scheme.primary : scheme.secondary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: firstProduct
            ? scheme.primaryContainer
            : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: iconColor.withValues(alpha: .5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              firstProduct ? Icons.inventory_2_outlined : Icons.check_rounded,
              color: firstProduct ? scheme.onPrimary : scheme.onSecondary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: foreground),
                ),
                const SizedBox(height: 7),
                Text(
                  description,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ],
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
                tooltip: context.tr('Chiudi', 'Close'),
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
              label: Text(
                context.tr(
                  'Elimina tutti gli scaduti',
                  'Delete all expired products',
                ),
              ),
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
      title: context.tr(
        'Eliminare ${product.name}?',
        'Delete ${product.name}?',
      ),
      message: context.tr(
        'Il prodotto e la sua fotografia verranno rimossi definitivamente.',
        'The product and its photo will be permanently removed.',
      ),
      confirmLabel: context.tr('Elimina', 'Delete'),
    );
    if (!confirmed || !mounted) return;

    final deleteProduct = _deleteAction();
    final synchronization = ref.read(notificationSynchronizationProvider);
    setState(() => _deletingIds.add(product.id));
    try {
      await deleteProduct(product);
      await synchronization.synchronizeLatest().catchError(
        (_) => const NotificationSynchronizationResult(failed: 1),
      );
      if (!mounted) return;
      setState(() => _products.removeWhere((item) => item.id == product.id));
      _showMessage(
        context.tr('${product.name} eliminato.', '${product.name} deleted.'),
      );
    } catch (_) {
      if (mounted) {
        _showMessage(
          context.tr(
            'Eliminazione non riuscita. Riprova.',
            'Deletion failed. Try again.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _deletingIds.remove(product.id));
    }
  }

  Future<void> _deleteAll() async {
    final count = _products.length;
    final confirmed = await _confirmDelete(
      title: context.tr(
        'Eliminare tutti i prodotti scaduti?',
        'Delete all expired products?',
      ),
      message: context.strings.isEnglish
          ? '$count ${count == 1 ? 'product will' : 'products will'} be permanently removed.'
          : '$count ${count == 1 ? 'prodotto verrà rimosso' : 'prodotti verranno rimossi'} definitivamente.',
      confirmLabel: context.tr('Elimina tutti', 'Delete all'),
    );
    if (!confirmed || !mounted) return;

    final deleteProduct = _deleteAction();
    final synchronization = ref.read(notificationSynchronizationProvider);
    setState(() => _deletingAll = true);
    final deletedIds = <String>[];
    for (final product in List<Product>.of(_products)) {
      try {
        await deleteProduct(product);
        deletedIds.add(product.id);
      } catch (_) {
        // Gli eventuali elementi non eliminati restano visibili per un nuovo tentativo.
      }
    }
    if (deletedIds.isNotEmpty) {
      await synchronization.synchronizeLatest().catchError(
        (_) => const NotificationSynchronizationResult(failed: 1),
      );
    }
    if (!mounted) return;
    setState(() {
      _products.removeWhere((product) => deletedIds.contains(product.id));
      _deletingAll = false;
    });
    final failures = count - deletedIds.length;
    _showMessage(
      failures == 0
          ? context.tr(
              'Prodotti scaduti eliminati.',
              'Expired products deleted.',
            )
          : context.strings.isEnglish
          ? '$failures products were not deleted. Try again.'
          : '$failures prodotti non sono stati eliminati. Riprova.',
    );
  }

  Future<void> Function(Product) _deleteAction() {
    final repository = ref.read(productRepositoryProvider);
    final images = ref.read(productImageStorageProvider);
    return (product) => mutationLockFor(repository).run(() async {
      final current = await repository.getById(product.id);
      await repository.delete(product.id);
      try {
        await images.delete(current?.imagePath ?? product.imagePath);
      } catch (_) {
        /* Deletion of an absent image is best effort. */
      }
    });
  }

  Future<bool> _confirmDelete({
    required String title,
    required String message,
    required String confirmLabel,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          scrollable: true,
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('Annulla', 'Cancel')),
            ),
            FilledButton(
              key: const Key('confirm-dashboard-delete'),
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Theme.of(context).colorScheme.onError,
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
      ExpirationState.expired => (
        context.tr('Scaduto', 'Expired'),
        AppTheme.dangerText(context),
      ),
      ExpirationState.expiresToday => (
        context.tr('Scade oggi', 'Expires today'),
        AppTheme.dangerText(context),
      ),
      ExpirationState.dueSoon => (
        info.daysRemaining == 1
            ? context.tr('Domani', 'Tomorrow')
            : context.tr(
                'Tra ${info.daysRemaining} giorni',
                'In ${info.daysRemaining} days',
              ),
        AppTheme.warningText(context),
      ),
      ExpirationState.fresh => (
        context.tr('Sotto controllo', 'Under control'),
        Theme.of(context).colorScheme.primary,
      ),
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
                      child: Icon(switch (product.category) {
                        ProductCategory.food => Icons.restaurant_rounded,
                        ProductCategory.beverages => Icons.local_drink_rounded,
                        ProductCategory.medicines => Icons.medication_rounded,
                        ProductCategory.personalCare => Icons.spa_rounded,
                        ProductCategory.cleaning =>
                          Icons.cleaning_services_rounded,
                        ProductCategory.other => Icons.category_rounded,
                      }, color: color),
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
                            '$label · ${DateFormat.yMd(context.strings.languageCode).format(product.expirationDate.toLocalDateTime())}',
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
                tooltip: context.tr(
                  'Elimina ${product.name}',
                  'Delete ${product.name}',
                ),
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
                ? context.tr('Nessun prodotto scaduto', 'No expired products')
                : context.tr(
                    'Nessun prodotto in scadenza',
                    'No products expiring soon',
                  ),
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
            Text(
              context.tr(
                'Non è stato possibile caricare i prodotti',
                'Products could not be loaded',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(context.tr('Riprova', 'Try again')),
            ),
          ],
        ),
      ),
    ),
  );
}
