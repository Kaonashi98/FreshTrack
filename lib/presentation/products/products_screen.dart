import 'package:flutter/material.dart';
import 'package:freshtrack/shared/widgets/page_heading.dart';
import 'package:freshtrack/domain/products/expiration_service.dart';
import 'package:freshtrack/shared/widgets/current_date_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:freshtrack/shared/widgets/product_card.dart';
import 'package:freshtrack/shared/text/search_normalization.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

enum ProductSort { expiration, name, newest }

enum ProductListFilter { all, dueSoon, expired, archived }

List<Product> filterAndSortProducts(
  List<Product> products, {
  String query = '',
  ProductCategory? category,
  CivilDate? expirationDate,
  ProductSort sort = ProductSort.expiration,
  ProductListFilter filter = ProductListFilter.all,
  DateTime? now,
}) {
  final normalizedQuery = normalizeForSearch(query);
  final filtered = products
      .where(
        (product) =>
            normalizeForSearch(product.name).contains(normalizedQuery) &&
            _matchesStatus(product, filter, now) &&
            (category == null || product.category == category) &&
            (expirationDate == null ||
                (product.status == ProductStatus.available &&
                    product.expirationDate == expirationDate)),
      )
      .toList();
  switch (sort) {
    case ProductSort.expiration:
      filtered.sort(
        (first, second) =>
            first.expirationDate.compareTo(second.expirationDate),
      );
    case ProductSort.name:
      filtered.sort(
        (first, second) => normalizeForSearch(
          first.name,
        ).compareTo(normalizeForSearch(second.name)),
      );
    case ProductSort.newest:
      filtered.sort(
        (first, second) => second.createdAt.compareTo(first.createdAt),
      );
  }
  return filtered;
}

bool _matchesStatus(Product p, ProductListFilter filter, DateTime? now) {
  if (filter == ProductListFilter.all) return true;
  final days = ExpirationService.evaluate(
    expirationDate: p.expirationDate,
    now: now,
  ).daysRemaining;
  return switch (filter) {
    ProductListFilter.all => true,
    ProductListFilter.dueSoon =>
      p.status == ProductStatus.available && days >= 0 && days <= 7,
    ProductListFilter.expired => ExpirationService.isExpired(p, now: now),
    ProductListFilter.archived =>
      p.status == ProductStatus.consumed || p.status == ProductStatus.discarded,
  };
}

String _formatDate(BuildContext context, CivilDate date) =>
    DateFormat.yMd(context.strings.languageCode).format(date.toLocalDateTime());

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({this.expirationDate, super.key});

  final CivilDate? expirationDate;

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = SearchController();
  String _query = '';
  ProductCategory? _category;
  ProductSort _sort = ProductSort.expiration;
  ProductListFilter _filter = ProductListFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsProvider);
    return products.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.tr(
                  'Non è stato possibile caricare i prodotti.',
                  'Products could not be loaded.',
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(productsProvider),
                child: Text(context.tr('Riprova', 'Try again')),
              ),
            ],
          ),
        ),
      ),
      data: (loadedItems) {
        final filtered = filterAndSortProducts(
          loadedItems,
          query: _query,
          category: _category,
          expirationDate: widget.expirationDate,
          sort: _sort,
          filter: _filter,
          now: CurrentDateScope.now(context),
        );
        const bottomClearance = 24.0;
        final hasFilters =
            _filter != ProductListFilter.all ||
            _query.isNotEmpty ||
            _category != null ||
            widget.expirationDate != null;
        return CustomScrollView(
          key: const Key('products-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (MediaQuery.viewInsetsOf(context).bottom == 0) ...[
                      PageHeading(
                        title: widget.expirationDate == null
                            ? context.tr('I tuoi prodotti', 'Your products')
                            : widget.expirationDate ==
                                  CivilDate.fromDateTime(
                                    CurrentDateScope.now(context),
                                  )
                            ? context.tr('Scadono oggi', 'Expiring today')
                            : context.tr(
                                'Scadenze del ${_formatDate(context, widget.expirationDate!)}',
                                'Expirations on ${_formatDate(context, widget.expirationDate!)}',
                              ),
                        subtitle: context.tr(
                          'Tutto ciò che hai, in ordine di scadenza.',
                          'Everything you have, ordered by expiration date.',
                        ),
                      ),
                      if (widget.expirationDate != null) ...[
                        const SizedBox(height: 12),
                        _ExpiryDateFilter(
                          date: widget.expirationDate!,
                          onClear: () => context.go('/products'),
                        ),
                      ],
                      const SizedBox(height: 18),
                    ],
                    SearchBar(
                      controller: _searchController,
                      hintText: context.tr(
                        'Cerca un prodotto',
                        'Search for a product',
                      ),
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        if (_query.isNotEmpty)
                          IconButton(
                            key: const Key('clear-product-search'),
                            tooltip: context.tr(
                              'Cancella ricerca',
                              'Clear search',
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _query = normalizeForSearch(value)),
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                    ),
                    if (MediaQuery.viewInsetsOf(context).bottom == 0) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 7,
                        runSpacing: 4,
                        children: [
                          for (final filter in ProductListFilter.values)
                            ChoiceChip(
                              key: Key('status-filter-${filter.name}'),
                              label: Text(switch (filter) {
                                ProductListFilter.all => context.tr(
                                  'Tutti',
                                  'All',
                                ),
                                ProductListFilter.dueSoon => context.tr(
                                  'In scadenza',
                                  'Expiring soon',
                                ),
                                ProductListFilter.expired => context.tr(
                                  'Scaduti',
                                  'Expired',
                                ),
                                ProductListFilter.archived => context.tr(
                                  'Archivio',
                                  'Archive',
                                ),
                              }),
                              selected: _filter == filter,
                              onSelected: (_) =>
                                  setState(() => _filter = filter),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.zero,
                        child: Flex(
                          direction:
                              MediaQuery.textScalerOf(context).scale(14) > 21
                              ? Axis.vertical
                              : Axis.horizontal,
                          children: [
                            Flexible(
                              flex:
                                  MediaQuery.textScalerOf(context).scale(14) >
                                      21
                                  ? 0
                                  : 1,
                              child: _FilterMenu<ProductCategory>(
                                label:
                                    _category?.localizedLabel(
                                      context.strings.languageCode,
                                    ) ??
                                    context.tr('Categoria', 'Category'),
                                value: _category,
                                values: selectableProductCategories,
                                labelFor: (value) => value.localizedLabel(
                                  context.strings.languageCode,
                                ),
                                onSelected: (value) {
                                  FocusScope.of(context).unfocus();
                                  setState(() => _category = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 8, height: 8),
                            Flexible(
                              flex:
                                  MediaQuery.textScalerOf(context).scale(14) >
                                      21
                                  ? 0
                                  : 1,
                              child: PopupMenuButton<ProductSort>(
                                tooltip: context.tr(
                                  'Ordina prodotti',
                                  'Sort products',
                                ),
                                initialValue: _sort,
                                onSelected: (value) {
                                  FocusScope.of(context).unfocus();
                                  setState(() => _sort = value);
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: ProductSort.expiration,
                                    child: Text(
                                      context.tr('Scadenza', 'Expiration'),
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: ProductSort.name,
                                    child: Text(context.tr('Nome', 'Name')),
                                  ),
                                  PopupMenuItem(
                                    value: ProductSort.newest,
                                    child: Text(
                                      context.tr('Più recenti', 'Newest'),
                                    ),
                                  ),
                                ],
                                child: _FilterButton(
                                  icon: Icons.sort_rounded,
                                  label: _sortLabel(context),
                                  active: _sort != ProductSort.expiration,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            context.strings.isEnglish
                                ? hasFilters
                                      ? '${filtered.length} of ${loadedItems.length} products'
                                      : filtered.length == 1
                                      ? '1 product'
                                      : '${filtered.length} products'
                                : hasFilters
                                ? '${filtered.length} di ${loadedItems.length} prodotti'
                                : filtered.length == 1
                                ? '1 prodotto'
                                : '${filtered.length} prodotti',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                        if (hasFilters)
                          TextButton.icon(
                            key: const Key('reset-product-filters'),
                            onPressed: _clearFilters,
                            icon: const Icon(
                              Icons.filter_alt_off_outlined,
                              size: 18,
                            ),
                            label: Text(
                              context.tr('Azzera filtri', 'Reset filters'),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomClearance),
                  child: _EmptyProducts(
                    hasFilters: hasFilters,
                    onClear: _clearFilters,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, index) {
                    final product = filtered[index];
                    return ProductCard(
                      product: product,
                      onTap: () => context.push('/products/${product.id}'),
                    );
                  },
                ),
              ),
            if (filtered.isNotEmpty)
              SliverToBoxAdapter(child: SizedBox(height: bottomClearance)),
          ],
        );
      },
    );
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();
    _searchController.clear();
    setState(() {
      _query = '';
      _category = null;
      _filter = ProductListFilter.all;
    });
    if (widget.expirationDate != null) context.go('/products');
  }

  String _sortLabel(BuildContext context) => switch (_sort) {
    ProductSort.expiration => context.tr('Scadenza', 'Expiration'),
    ProductSort.name => context.tr('Nome', 'Name'),
    ProductSort.newest => context.tr('Recenti', 'Newest'),
  };
}

class _ExpiryDateFilter extends StatelessWidget {
  const _ExpiryDateFilter({required this.date, required this.onClear});

  final CivilDate date;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => GlassSurface(
    key: const Key('expiry-date-filter'),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    borderRadius: const BorderRadius.all(Radius.circular(18)),
    child: Row(
      children: [
        Icon(
          Icons.event_available_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            context.tr(
              'Prodotti con scadenza ${_formatDate(context, date)}',
              'Products expiring on ${_formatDate(context, date)}',
            ),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          tooltip: context.tr('Rimuovi filtro data', 'Remove date filter'),
          onPressed: onClear,
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    ),
  );
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onSelected,
  });

  final String label;
  final T? value;
  final List<T> values;
  final String Function(T) labelFor;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) => PopupMenuButton<({T? category})>(
    tooltip: context.tr('Filtra per categoria', 'Filter by category'),
    onSelected: (selection) => onSelected(selection.category),
    itemBuilder: (_) => [
      PopupMenuItem(
        value: (category: null),
        child: Text(context.tr('Tutte le categorie', 'All categories')),
      ),
      ...values.map(
        (value) => PopupMenuItem(
          value: (category: value),
          child: Text(labelFor(value)),
        ),
      ),
    ],
    child: _FilterButton(
      icon: value == null
          ? Icons.filter_alt_outlined
          : Icons.check_circle_rounded,
      label: label,
      active: value != null,
    ),
  );
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: active
            ? scheme.primary.withValues(alpha: .15)
            : Colors.white.withValues(alpha: .025),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: active
              ? scheme.primary.withValues(alpha: .35)
              : scheme.outlineVariant.withValues(alpha: .24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.hasFilters, required this.onClear});

  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: GlassSurface(
        key: const Key('empty-products-panel'),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              hasFilters
                  ? context.tr('Nessun risultato', 'No results')
                  : context.tr('Ancora nessun prodotto', 'No products yet'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? context.tr(
                      'Prova a cambiare la ricerca o a rimuovere i filtri.',
                      'Try changing your search or removing the filters.',
                    )
                  : context.tr(
                      'Tocca Aggiungi per registrare una scadenza.',
                      'Tap Add to record an expiration date.',
                    ),
              textAlign: TextAlign.center,
            ),
            if (hasFilters) ...[
              const SizedBox(height: 18),
              FilledButton.tonalIcon(
                key: const Key('empty-reset-product-filters'),
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: Text(
                  context.tr('Mostra tutti i prodotti', 'Show all products'),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
