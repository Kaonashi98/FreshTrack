import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:freshtrack/shared/widgets/product_card.dart';
import 'package:go_router/go_router.dart';

enum ProductSort { expiration, name, newest }

bool _sameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({this.expirationDate, super.key});

  final DateTime? expirationDate;

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  final _searchController = SearchController();
  String _query = '';
  ProductCategory? _category;
  ProductSort _sort = ProductSort.expiration;

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
      error: (_, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Non è stato possibile caricare i prodotti.'),
        ),
      ),
      data: (loadedItems) {
        final filtered = _filterAndSort(loadedItems);
        final hasFilters = _query.isNotEmpty || _category != null;
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
                          : _sameDate(widget.expirationDate!, DateTime.now())
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
                          setState(() => _query = value.trim().toLowerCase()),
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
                child: _EmptyProducts(hasFilters: hasFilters),
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
            const SliverToBoxAdapter(child: SizedBox(height: 108)),
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

  List<Product> _filterAndSort(List<Product> products) {
    final filtered = products
        .where(
          (product) =>
              product.name.toLowerCase().contains(_query) &&
              (_category == null || product.category == _category) &&
              (widget.expirationDate == null ||
                  (product.status == ProductStatus.available &&
                      _sameDate(
                        product.expirationDate,
                        widget.expirationDate!,
                      ))),
        )
        .toList();
    switch (_sort) {
      case ProductSort.expiration:
        filtered.sort(
          (first, second) =>
              first.expirationDate.compareTo(second.expirationDate),
        );
      case ProductSort.name:
        filtered.sort(
          (first, second) =>
              first.name.toLowerCase().compareTo(second.name.toLowerCase()),
        );
      case ProductSort.newest:
        filtered.sort(
          (first, second) => second.createdAt.compareTo(first.createdAt),
        );
    }
    return filtered;
  }
}

class _ExpiryDateFilter extends StatelessWidget {
  const _ExpiryDateFilter({required this.date, required this.onClear});

  final DateTime date;
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
  const _EmptyProducts({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: GlassSurface(
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
                  : 'Aggiungi il primo prodotto dalla Dashboard.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}
