import 'package:flutter/material.dart';

class AppColors {
    static const background = Color(0xFF1E1F22);
    static const topBar = Color(0xFF181A1F);
    static const panel = Color(0xFF2B2D30);
    static const panelHover = Color(0xFF31343A);
    static const border = Color(0xFF3C3F41);

    static const accent = Color(0xFFA259FF);
    static const accentDark = Color(0xFF7E3FF2);

    static const textPrimary = Color(0xFFE8E8E8);
    static const textSecondary = Color(0xFFB7B9BD);
    static const textMuted = Color(0xFF8B8D91);

    // Gradiente padrão do See2Sound
    static const gradientStart = Color(0xFF8E26CF);
    static const gradientMiddle = Color(0xFF5525CE);
    static const gradientEnd = Color(0xFF2500DE);

    static const LinearGradient mainGradient = LinearGradient(
        colors: [
        gradientStart,
        gradientMiddle,
        gradientEnd,
        ],
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
}