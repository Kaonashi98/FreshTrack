import 'package:flutter/material.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final index = path.startsWith('/products')
        ? 1
        : path.startsWith('/settings')
        ? 2
        : 0;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: SafeArea(bottom: false, child: child),
      floatingActionButton: index != 0
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/products/new'),
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
}
