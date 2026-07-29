import 'dart:io';

import 'package:flutter/material.dart';
import 'package:freshtrack/core/theme/app_theme.dart';
import 'package:freshtrack/domain/products/expiration_service.dart';
import 'package:freshtrack/domain/products/product.dart';
import 'package:freshtrack/shared/widgets/glass_surface.dart';
import 'package:intl/intl.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, this.onTap, super.key});

  final Product product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final info = ExpirationService.evaluate(
      expirationDate: product.expirationDate,
    );
    final (color, label) = _expirationStyle(context, info);
    final thumbnailColor = _categoryColor(context, product.category);
    final scheme = Theme.of(context).colorScheme;
    return GlassSurface(
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          _ProductThumbnail(product: product, color: thumbnailColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${product.quantity.toStringAsFixed(product.quantity % 1 == 0 ? 0 : 1)} ${product.unit.label} · ${product.category.label}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: .35),
                            blurRadius: 7,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        '$label · ${DateFormat('dd/MM/yyyy').format(product.expirationDate)}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: .10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 19,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(BuildContext context, ProductCategory category) {
    final color = switch (category) {
      ProductCategory.food => const Color(0xFFF97316),
      ProductCategory.beverages => const Color(0xFF0EA5E9),
      ProductCategory.medicines => const Color(0xFF8B5CF6),
      ProductCategory.personalCare => const Color(0xFFEC4899),
      ProductCategory.cleaning => const Color(0xFF06B6D4),
      ProductCategory.other => const Color(0xFF64748B),
    };
    return Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(color, Colors.white, .28)!
        : color;
  }

  (Color, String) _expirationStyle(BuildContext context, ExpirationInfo info) {
    final scheme = Theme.of(context).colorScheme;
    if (product.status != ProductStatus.available) {
      return (scheme.outline, product.status.label);
    }
    return switch (info.state) {
      ExpirationState.expired => (AppTheme.danger, 'Scaduto'),
      ExpirationState.expiresToday => (AppTheme.danger, 'Scade oggi'),
      ExpirationState.dueSoon => (
        AppTheme.warning,
        'Tra ${info.daysRemaining} giorni',
      ),
      ExpirationState.fresh => (scheme.primary, 'Fresco'),
    };
  }
}

class _ProductThumbnail extends StatelessWidget {
  const _ProductThumbnail({required this.product, required this.color});

  final Product product;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: .22), color.withValues(alpha: .09)],
        ),
      ),
      child: Icon(_categoryIcon(product.category), color: color),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox.square(
        dimension: 58,
        child: product.imagePath == null
            ? fallback
            : Image.file(
                File(product.imagePath!),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => fallback,
              ),
      ),
    );
  }

  IconData _categoryIcon(ProductCategory category) => switch (category) {
    ProductCategory.food => Icons.restaurant_rounded,
    ProductCategory.beverages => Icons.local_drink_rounded,
    ProductCategory.medicines => Icons.medication_rounded,
    ProductCategory.personalCare => Icons.spa_rounded,
    ProductCategory.cleaning => Icons.cleaning_services_rounded,
    ProductCategory.other => Icons.category_rounded,
  };
}
