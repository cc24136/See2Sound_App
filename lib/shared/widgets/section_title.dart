import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    required this.highContrast,
    this.textAlign = TextAlign.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String title;
  final String? subtitle;
  final bool highContrast;
  final TextAlign textAlign;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          title,
          textAlign: textAlign,
          style: TextStyle(
            color: AppColors.textPrimaryFor(highContrast),
            fontSize: 34,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            textAlign: textAlign,
            style: TextStyle(
              color: AppColors.textSecondaryFor(highContrast),
              fontSize: 18,
              height: 1.3,
            ),
          ),
        ],
      ],
    );
  }
}