import 'package:flutter/material.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';

class PageHeading extends StatelessWidget {
  const PageHeading({
    required this.title,
    this.eyebrow,
    this.subtitle,
    this.eyebrowKey,
    super.key,
  });
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Key? eyebrowKey;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      eyebrow!.toUpperCase(),
                      key: eyebrowKey,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                        letterSpacing: .8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(title, style: AppTheme.pageTitle(context)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            key: const Key('open-settings'),
            tooltip: context.tr('Impostazioni', 'Settings'),
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.tune_rounded, size: 22),
          ),
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 10),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.35,
          ),
        ),
      ],
    ],
  );
}
