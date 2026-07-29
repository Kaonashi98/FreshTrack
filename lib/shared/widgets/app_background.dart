import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF081426)
        : const Color(0xFFF1F5FB),
    child: child,
  );
}
