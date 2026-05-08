import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
    static ThemeData get darkTheme {
        return ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Arial',
        colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.panel,
        ),
        );
    }
}