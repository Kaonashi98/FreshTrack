import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freshtrack/presentation/providers/product_providers.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({required this.child, super.key});
  final Widget child;
  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  bool _openingProduct = false;
  void _openProduct() {
    if (_openingProduct) return;
    _openingProduct = true;
    try {
      context.push<void>('/products/add');
    } finally {
      // Protegge i tap dello stesso frame. Il selettore viene sostituito dal
      // modulo, quindi il suo Future non descrive la chiusura dell'intero flusso.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openingProduct = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final products = ref.watch(productsProvider);
    final loaded = products is AsyncData;
    final scheme = Theme.of(context).colorScheme;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 21;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (!loaded && !path.startsWith('/settings'))
              Positioned(
                top: 14,
                right: 20,
                child: IconButton(
                  key: const Key('open-settings'),
                  tooltip: context.tr('Impostazioni', 'Settings'),
                  onPressed: () => context.go('/settings'),
                  icon: const Icon(Icons.tune_outlined, size: 22),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Material(
        color: scheme.surface,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              key: const Key('main-navigation'),
              children: [
                Expanded(
                  child: _Destination(
                    label: context.tr('Oggi', 'Today'),
                    icon: Icons.home_outlined,
                    selected: path == '/dashboard',
                    onTap: () => context.go('/dashboard'),
                  ),
                ),
                Expanded(
                  flex: largeText ? 1 : 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child:
                        loaded &&
                            !path.startsWith('/settings') &&
                            MediaQuery.viewInsetsOf(context).bottom == 0
                        ? FilledButton(
                            key: const Key('add-product'),
                            onPressed: _openProduct,
                            child: largeText
                                ? Icon(
                                    Icons.add_rounded,
                                    semanticLabel: context.tr(
                                      'Aggiungi prodotto',
                                      'Add product',
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add_rounded, size: 19),
                                      SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          context.tr('Aggiungi', 'Add'),
                                        ),
                                      ),
                                    ],
                                  ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                Expanded(
                  child: _Destination(
                    label: context.tr('Prodotti', 'Products'),
                    icon: Icons.inventory_2_outlined,
                    selected: path.startsWith('/products'),
                    onTap: () => context.go('/products'),
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

class _Destination extends StatelessWidget {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : scheme.onSurfaceVariant;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 23, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
