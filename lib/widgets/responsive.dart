import 'package:flutter/material.dart';

class Responsive extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const Responsive({
    super.key,
    required this.child,
    this.maxWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.shortestSide >= 600;

  static int gridColumns(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 900) return 3;
    if (width >= 600) return 2;
    return 1;
  }

  static double contentMaxWidth(BuildContext context) =>
      isTablet(context) ? 600 : double.infinity;
}
