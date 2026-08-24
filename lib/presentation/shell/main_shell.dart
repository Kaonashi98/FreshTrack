import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:go_router/go_router.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  var _openingProductForm = false;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = path.startsWith('/products')
        ? 1
        : path.startsWith('/settings')
        ? 2
        : 0;
    final scheme = Theme.of(context).colorScheme;
    final loadedProducts = switch (ref.watch(productsProvider)) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final showAddProductFab = switch (index) {
      0 => loadedProducts != null,
      1 => loadedProducts?.isNotEmpty ?? false,
      _ => false,
    };
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: SafeArea(bottom: false, child: widget.child),
      floatingActionButton: !showAddProductFab
          ? null
          : FloatingActionButton.extended(
              key: const Key('add-product'),
              tooltip: 'Aggiungi prodotto',
              onPressed: _openProductForm,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Aggiungi'),
            ),
      bottomNavigationBar: GlassSurface(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: NavigationBar(
          selectedIndex: index,
          backgroundColor: Colors.transparent,
          indicatorColor: scheme.primary.withValues(alpha: .15),
          onDestinationSelected: (value) {
            if (value == 0) context.go('/dashboard');
            if (value == 1) context.go('/products');
            if (value == 2) context.go('/settings');
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.space_dashboard_outlined),
              selectedIcon: Icon(Icons.space_dashboard_rounded),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2_rounded),
              label: 'Prodotti',
            ),
            NavigationDestination(
              icon: Icon(Icons.tune_outlined),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Impostazioni',
            ),
          ],
        ),
      ),
    );
  }

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
