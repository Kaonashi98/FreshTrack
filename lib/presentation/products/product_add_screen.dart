import 'package:flutter/material.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';

class ProductAddScreen extends StatelessWidget {
  const ProductAddScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          Text(
            context.tr('Aggiungi un prodotto', 'Add a product'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF123E78), Color(0xFF087650)],
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.add_shopping_cart_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  context.tr('Da dove iniziamo?', 'Where shall we start?'),
                  style: AppTheme.pageTitle(
                    context,
                  )?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    'Scegli il modo più comodo per te.',
                    'Choose the easiest option for you.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: .9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _AddChoice(
            key: const Key('add-by-barcode'),
            primary: true,
            icon: Icons.qr_code_scanner_rounded,
            title: context.tr('Scansiona il codice', 'Scan the code'),
            description: context.tr(
              'Cerca il prodotto dal codice a barre.',
              'Look up the product by barcode.',
            ),
            onTap: () => context.pushReplacement('/products/new?scan=true'),
          ),
          const SizedBox(height: 12),
          _AddChoice(
            key: const Key('add-manually'),
            primary: false,
            icon: Icons.edit_outlined,
            title: context.tr('Inserisci a mano', 'Enter manually'),
            description: context.tr(
              'Bastano un nome e una scadenza.',
              'A name and expiration date are enough.',
            ),
            onTap: () => context.pushReplacement('/products/new'),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.photo_camera_outlined,
                  size: 21,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr(
                      'Puoi fotografare la data di scadenza durante l’inserimento.',
                      'You can photograph the expiration date while adding the product.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _AddChoice extends StatelessWidget {
  const _AddChoice({
    required this.primary,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
    super.key,
  });
  final bool primary;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = primary ? scheme.primary : scheme.secondary;
    return Material(
      color: scheme.surface,
      elevation: Theme.of(context).brightness == Brightness.dark ? 0 : 2,
      shadowColor: const Color(0xFF2D6685).withValues(alpha: .12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: primary
                      ? scheme.primaryContainer
                      : scheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, size: 27, color: accent),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
