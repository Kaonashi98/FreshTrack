import 'package:flutter/material.dart';
import 'package:freshtrack/core/theme/app_theme.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ColoredBox(color: AppTheme.background(context), child: child);
}
