import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'app_design_tokens.dart';

class AppTheme {
  static ThemeData dark({bool highContrast = false}) {
    final accent = AppColors.accentFor(highContrast);
    final background = AppColors.backgroundFor(highContrast);
    final surface = AppColors.panelFor(highContrast);
    final border = AppColors.borderFor(highContrast);
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);

    final scheme = ColorScheme.dark(
      primary: accent,
      onPrimary: highContrast ? Colors.black : Colors.white,
      surface: surface,
      onSurface: text,
      error: AppColors.errorFor(highContrast),
      onError: highContrast ? Colors.black : Colors.white,
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: scheme,
      fontFamily: 'Arial',
      visualDensity: VisualDensity.standard,
      splashFactory: highContrast ? NoSplash.splashFactory : null,
      textTheme: ThemeData.dark().textTheme.apply(
        bodyColor: text,
        displayColor: text,
      ),
      focusColor: AppColors.focusFor(highContrast).withValues(alpha: 0.28),
      hoverColor: accent.withValues(alpha: 0.1),
      dividerColor: border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(
            color: AppColors.focusFor(highContrast),
            width: highContrast ? 3 : 2,
          ),
        ),
        labelStyle: TextStyle(color: secondary),
        hintStyle: TextStyle(color: secondary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: AppTypography.label,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          backgroundColor: accent,
          foregroundColor: highContrast ? Colors.black : Colors.white,
          elevation: highContrast ? 0 : 1,
          textStyle: AppTypography.label,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          foregroundColor: text,
          side: BorderSide(color: border, width: highContrast ? 2 : 1),
          textStyle: AppTypography.label,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      tooltipTheme: TooltipThemeData(
        waitDuration: const Duration(milliseconds: 450),
        textStyle: TextStyle(color: text, fontSize: 13),
        decoration: BoxDecoration(
          color: surface,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        contentTextStyle: TextStyle(color: text),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.control,
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: border, width: highContrast ? 2 : 1),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.control,
          side: BorderSide(color: border),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => dark();
}
