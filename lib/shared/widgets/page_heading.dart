import 'package:flutter/material.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:go_router/go_router.dart';

/// Content occupies the former brand row; settings keeps its top-right anchor.
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(
                    eyebrow!.toUpperCase(),
                    key: eyebrowKey,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 7),
                ],
                Text(title, style: AppTheme.pageTitle(context)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            key: const Key('open-settings'),
            tooltip: context.tr('Impostazioni', 'Settings'),
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.tune_outlined, size: 22),
          ),
        ],
      ),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}
