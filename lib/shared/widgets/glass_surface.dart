import 'package:flutter/material.dart';

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0xFF8FB6F5).withValues(alpha: .20)
        : const Color(0xFFD7E4F8).withValues(alpha: .84);
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [Color(0xFF1A2B48), Color(0xFF111F36)]
          : const [Color(0xFFFDFEFF), Color(0xFFF4F7FC)],
    );

    Widget content = Padding(padding: padding, child: child);
    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      );
    }

    return Padding(
      padding: margin,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: borderRadius,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF020817,
              ).withValues(alpha: isDark ? .22 : .05),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(borderRadius: borderRadius, child: content),
      ),
    );
  }
}
