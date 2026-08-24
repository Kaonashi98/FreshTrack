import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/domain/common/civil_date.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:freshtrack/shared/widgets/product_card.dart';
import 'package:freshtrack/shared/text/search_normalization.dart';
import 'package:go_router/go_router.dart';

enum ProductSort { expiration, name, newest }

// MainShell uses extendBody so the content continues underneath the 80dp
// NavigationBar. The additional 28dp keeps cards and the empty-state panel
// visually clear of that overlay without coupling this screen to Scaffold's
// post-layout geometry.
const _shellBottomContentClearance = 108.0;

List<Product> filterAndSortProducts(
  List<Product> products, {
  String query = '',
  ProductCategory? category,
  CivilDate? expirationDate,
  ProductSort sort = ProductSort.expiration,
}) {
  final normalizedQuery = normalizeForSearch(query);
  final filtered = products
      .where(
        (product) =>
            normalizeForSearch(product.name).contains(normalizedQuery) &&
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

String _formatDate(CivilDate date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

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
  var _openingProductForm = false;

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
              const Text('Non è stato possibile caricare i prodotti.'),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(productsProvider),
                child: const Text('Riprova'),
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
        );
        final hasFilters =
            _query.isNotEmpty ||
            _category != null ||
            widget.expirationDate != null;
        return CustomScrollView(
          key: const Key('products-scroll'),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.expirationDate == null
                          ? 'I tuoi prodotti'
                          : widget.expirationDate ==
                                CivilDate.fromDateTime(DateTime.now())
                          ? 'Scadono oggi'
                          : 'Scadenze del ${_formatDate(widget.expirationDate!)}',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (widget.expirationDate != null) ...[
                      const SizedBox(height: 12),
                      _ExpiryDateFilter(
                        date: widget.expirationDate!,
                        onClear: () => context.go('/products'),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SearchBar(
                      controller: _searchController,
                      hintText: 'Cerca per nome',
                      leading: const Icon(Icons.search_rounded),
                      trailing: [
                        if (_query.isNotEmpty)
                          IconButton(
                            key: const Key('clear-product-search'),
                            tooltip: 'Cancella ricerca',
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
                    const SizedBox(height: 12),
                    GlassSurface(
                      padding: const EdgeInsets.all(6),
                      borderRadius: const BorderRadius.all(Radius.circular(20)),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FilterMenu<ProductCategory>(
                              label: _category?.label ?? 'Categoria',
                              value: _category,
                              values: selectableProductCategories,
                              labelFor: (value) => value.label,
                              onSelected: (value) {
                                FocusScope.of(context).unfocus();
                                setState(() => _category = value);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: PopupMenuButton<ProductSort>(
                              tooltip: 'Ordina prodotti',
                              initialValue: _sort,
                              onSelected: (value) {
                                FocusScope.of(context).unfocus();
                                setState(() => _sort = value);
                              },
                              itemBuilder: (_) => const [
                                PopupMenuItem(
                                  value: ProductSort.expiration,
                                  child: Text('Scadenza'),
                                ),
                                PopupMenuItem(
                                  value: ProductSort.name,
                                  child: Text('Nome'),
                                ),
                                PopupMenuItem(
                                  value: ProductSort.newest,
                                  child: Text('Più recenti'),
                                ),
                              ],
                              child: _FilterButton(
                                icon: Icons.sort_rounded,
                                label: _sortLabel,
                                active: _sort != ProductSort.expiration,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        filtered.length == 1
                            ? '1 prodotto'
                            : '${filtered.length} prodotti',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  // MainShell extends beneath the navigation bar. Reserving
                  // its area keeps the empty panel centered in visible space.
                  padding: const EdgeInsets.only(
                    bottom: _shellBottomContentClearance,
                  ),
                  child: _EmptyProducts(
                    hasFilters: hasFilters,
                    onAdd: _openProductForm,
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
              const SliverToBoxAdapter(
                child: SizedBox(height: _shellBottomContentClearance),
              ),
          ],
        );
      },
    );
  }

  String get _sortLabel => switch (_sort) {
    ProductSort.expiration => 'Scadenza',
    ProductSort.name => 'Nome',
    ProductSort.newest => 'Recenti',
  };

  Future<void> _openProductForm() async {
    if (_openingProductForm) return;
    _openingProductForm = true;
    try {
      await context.push<void>('/products/new');
    } finally {
      _openingProductForm = false;
    }
  }
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
            'Prodotti con scadenza ${_formatDate(date)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        IconButton(
          tooltip: 'Rimuovi filtro data',
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
  Widget build(BuildContext context) => PopupMenuButton<T?>(
    tooltip: 'Filtra per categoria',
    onSelected: onSelected,
    itemBuilder: (_) => [
      PopupMenuItem<T?>(value: null, child: const Text('Tutte le categorie')),
      ...values.map(
        (value) =>
            PopupMenuItem<T?>(value: value, child: Text(labelFor(value))),
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
      height: 44,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.hasFilters, required this.onAdd});

  final bool hasFilters;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: GlassSurface(
        key: const Key('empty-products-panel'),
        padding: const EdgeInsets.all(26),
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
              hasFilters ? 'Nessun risultato' : 'La dispensa è vuota',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              hasFilters
                  ? 'Prova a cambiare la ricerca o a rimuovere i filtri.'
                  : 'Inizia registrando una scadenza.',
              textAlign: TextAlign.center,
            ),
            if (!hasFilters) ...[
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const Key('empty-products-add'),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Aggiungi prodotto'),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
