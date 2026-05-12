import 'package:flutter/material.dart';

class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.centerVertically = false,
    this.maxWidth = 1200,
  });

  final Widget child;
  final bool centerVertically;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    if (centerVertically) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}