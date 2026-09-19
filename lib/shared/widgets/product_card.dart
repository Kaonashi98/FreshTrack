import 'dart:io';
import 'package:flutter/material.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/domain/products/expiration_service.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/l10n/app_strings.dart';
import 'package:freshtrack/shared/widgets/current_date_scope.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    this.onTap,
    this.embedded = false,
    this.showDate = true,
    super.key,
  });
  final Product product;
  final VoidCallback? onTap;
  final bool embedded;
  final bool showDate;
  @override
  Widget build(BuildContext context) {
    final info = ExpirationService.evaluate(
      now: CurrentDateScope.now(context),
      expirationDate: product.expirationDate,
    );
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final large =
        MediaQuery.textScalerOf(context).scale(14) > 18 ||
        MediaQuery.sizeOf(context).width < 350;
    final date = product.expirationDate.toLocalDateTime();
    final (color, label) = product.status != ProductStatus.available
        ? (
            scheme.onSurfaceVariant,
            product.localizedStatusLabel(context.strings.languageCode),
          )
        : switch (info.state) {
            ExpirationState.expired => (
              AppTheme.dangerText(context),
              context.tr('Scaduto', 'Expired'),
            ),
            ExpirationState.expiresToday => (
              AppTheme.warningText(context),
              context.tr('Scade oggi', 'Expires today'),
            ),
            ExpirationState.dueSoon => (
              scheme.primary,
              info.daysRemaining == 1
                  ? context.tr('Domani', 'Tomorrow')
                  : context.tr(
                      'Tra ${info.daysRemaining} giorni',
                      'In ${info.daysRemaining} days',
                    ),
            ),
            ExpirationState.fresh => (
              scheme.primary,
              context.tr('Disponibile', 'Available'),
            ),
          };
    final dateText = DateFormat(
      date.year == CurrentDateScope.now(context).year ? 'd MMM' : 'd MMM yyyy',
      context.strings.languageCode,
    ).format(date);
    final status = Text(
      '$label · $dateText',
      style: text.bodySmall?.copyWith(color: color),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: embedded ? 0 : 10),
      child: Material(
        color: embedded ? Colors.transparent : scheme.surface,
        shape: embedded
            ? null
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: scheme.outlineVariant),
              ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: 15,
              horizontal: embedded ? 0 : 14,
            ),
            child: Row(
              children: [
                ProductThumbnail(product: product),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: large ? null : 2,
                        overflow: large ? null : TextOverflow.ellipsis,
                        style: text.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.quantityText} ${product.unit.localizedLabel(context.strings.languageCode)}',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (large && showDate) ...[
                        const SizedBox(height: 6),
                        status,
                      ],
                    ],
                  ),
                ),
                if (showDate && !large) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 82,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          label,
                          textAlign: TextAlign.right,
                          style: text.labelSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateText,
                          textAlign: TextAlign.right,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (!showDate) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({required this.product, this.size = 48, super.key});
  final Product product;
  final double size;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fallback = ColoredBox(
      color: scheme.secondaryContainer,
      child: Icon(
        switch (product.category) {
          ProductCategory.food => Icons.restaurant_rounded,
          ProductCategory.beverages => Icons.local_drink_rounded,
          ProductCategory.medicines => Icons.medication_rounded,
          ProductCategory.personalCare => Icons.spa_rounded,
          ProductCategory.cleaning => Icons.cleaning_services_rounded,
          ProductCategory.other => Icons.category_rounded,
        },
        color: scheme.onSecondaryContainer,
        size: size * .48,
      ),
    );
    final pixels = (size * MediaQuery.devicePixelRatioOf(context)).ceil();
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * .29),
      child: SizedBox(
        width: size,
        height: size,
        child: product.imagePath == null
            ? fallback
            : Image.file(
                File(product.imagePath!),
                fit: BoxFit.cover,
                cacheWidth: pixels,
                cacheHeight: pixels,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }
}
