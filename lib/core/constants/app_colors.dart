import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF15161A);
  static const topBar = Color(0xFF101115);
  static const panel = Color(0xFF23252B);
  static const panelHover = Color(0xFF2C2F37);
  static const border = Color(0xFF4A4D57);

  static const accent = Color(0xFFA259FF);
  static const accentDark = Color(0xFF7E3FF2);

  static const textPrimary = Color(0xFFE8E8E8);
  static const textSecondary = Color(0xFFC4C7CF);
  static const textMuted = Color(0xFFA7ABB5);
  static const success = Color(0xFF5ED69A);
  static const warning = Color(0xFFFFCA6A);
  static const error = Color(0xFFFF7B86);
  static const info = Color(0xFF82B7FF);
  static const disabled = Color(0xFF777B85);
  static const focus = Color(0xFFC78BFF);

  // Gradiente padrão do See2Sound
  static const gradientStart = Color(0xFF8E26CF);
  static const gradientMiddle = Color(0xFF5525CE);
  static const gradientEnd = Color(0xFF2500DE);

  static const LinearGradient mainGradient = LinearGradient(
    colors: [gradientStart, gradientMiddle, gradientEnd],
  );

  // Alto contraste
  static const highContrastBackground = Color(0xFF000000);
  static const highContrastTopBar = Color(0xFF050505);
  static const highContrastPanel = Color(0xFF101010);
  static const highContrastBorder = Color(0xFFFFFFFF);
  static const highContrastAccent = Color(0xFFFFD400);
  static const highContrastText = Color(0xFFFFFFFF);

  static Color backgroundFor(bool highContrast) {
    return highContrast ? highContrastBackground : background;
  }

  static Color topBarFor(bool highContrast) {
    return highContrast ? highContrastTopBar : topBar;
  }

  static Color panelFor(bool highContrast) {
    return highContrast ? highContrastPanel : panel;
  }

  static Color borderFor(bool highContrast) {
    return highContrast ? highContrastBorder : border;
  }

  static Color accentFor(bool highContrast) {
    return highContrast ? highContrastAccent : accent;
  }

  static Color textPrimaryFor(bool highContrast) {
    return highContrast ? highContrastText : textPrimary;
  }

  static Color textSecondaryFor(bool highContrast) {
    return highContrast ? highContrastText : textSecondary;
  }

  static Color successFor(bool highContrast) {
    return highContrast ? const Color(0xFF00FF85) : success;
  }

  static Color warningFor(bool highContrast) {
    return highContrast ? const Color(0xFFFFFF00) : warning;
  }

  static Color errorFor(bool highContrast) {
    return highContrast ? const Color(0xFFFF6B6B) : error;
  }

  static Color focusFor(bool highContrast) {
    return highContrast ? highContrastAccent : focus;
  }
}
