import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SettingPanel extends StatelessWidget {
  const SettingPanel({
    super.key,
    required this.child,
    required this.highContrast,
  });

  final Widget child;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panelFor(highContrast),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.borderFor(highContrast),
          width: highContrast ? 2 : 1,
        ),
      ),
      child: child,
    );
  }
}