import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GradientText extends StatelessWidget {
    const GradientText({
    super.key,
    required this.text,
    required this.style,
    this.gradient = AppColors.mainGradient,
    });

    final String text;
    final TextStyle style;
    final Gradient gradient;

    @override
    Widget build(BuildContext context) {
        return ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
            return gradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            );
        },
        child: Text(
            text,
            style: style,
        ),
        );
    }
}