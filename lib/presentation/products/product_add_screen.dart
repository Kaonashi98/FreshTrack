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
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Text(
            context.tr('Aggiungi un prodotto', 'Add a product'),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('Da dove iniziamo?', 'Where shall we start?'),
            style: AppTheme.pageTitle(context),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(
              'Scegli il modo più comodo per te.',
              'Choose the easiest option for you.',
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
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.photo_camera_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  context.tr(
                    'Puoi fotografare la data di scadenza durante l’inserimento.',
                    'You can photograph the expiration date while adding the product.',
                  ),
                ),
              ),
            ],
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
    final color = primary ? scheme.onPrimary : scheme.onSurface;
    return Material(
      color: primary ? scheme.primary : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: primary ? scheme.primary : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 27, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(color: color),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: primary ? color : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
