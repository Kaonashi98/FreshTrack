import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF142E44), Color(0xFF0E1B2B)]
              : const [Color(0xFFEAF5FF), Color(0xFFF5F9FC), Color(0xFFF2F9F4)],
          stops: dark ? null : const [0, .48, 1],
        ),
      ),
      child: child,
    );
  }
}
