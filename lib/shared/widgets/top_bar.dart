import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../features/app_shell/app_shell.dart';
import 'gradient_text.dart';

class TopBar extends StatelessWidget {
  const TopBar({
    super.key,
    required this.currentPage,
    required this.highContrast,
    required this.visualFocus,
    required this.onChangePage,
  });

  final AppPage currentPage;
  final bool highContrast;
  final bool visualFocus;
  final ValueChanged<AppPage> onChangePage;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(highContrast);
    final text = AppColors.textPrimaryFor(highContrast);
    final border = AppColors.borderFor(highContrast);

    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: BoxDecoration(
        color: AppColors.topBarFor(highContrast),
        border: Border(
          bottom: BorderSide(
            color: border,
            width: highContrast ? 2 : 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/logo.png',
            width: 48,
            height: 48,
            fit: BoxFit.contain,
          ),

          const SizedBox(width: 12),

          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'See2Sound',
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'ver 0.1',
                style: TextStyle(
                  color: AppColors.textSecondaryFor(highContrast),
                  fontSize: 11,
                  height: 1,
                ),
              ),
            ],
          ),

          const Spacer(),

          _TopBarButton(
            order: 1,
            label: 'Gerar audiodescrição',
            selected: currentPage == AppPage.generate,
            highContrast: highContrast,
            visualFocus: visualFocus,
            onTap: () => onChangePage(AppPage.generate),
          ),

          const SizedBox(width: 10),

          _TopBarButton(
            order: 2,
            label: 'Suas audiodescrições',
            selected: currentPage == AppPage.library,
            highContrast: highContrast,
            visualFocus: visualFocus,
            onTap: () => onChangePage(AppPage.library),
          ),

          const SizedBox(width: 12),

          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: IconButton(
              tooltip: 'Abrir configurações',
              onPressed: () => onChangePage(AppPage.settings),
              icon: Icon(
                Icons.settings_outlined,
                color: currentPage == AppPage.settings ? accent : text,
                size: 30,
              ),
              focusColor: visualFocus ? accent.withValues(alpha: 0.25) : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarButton extends StatelessWidget {
  const _TopBarButton({
    required this.order,
    required this.label,
    required this.selected,
    required this.highContrast,
    required this.visualFocus,
    required this.onTap,
  });

  final double order;
  final String label;
  final bool selected;
  final bool highContrast;
  final bool visualFocus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(highContrast);
    final text = AppColors.textPrimaryFor(highContrast);

    final shouldShowSelectedBox = selected && visualFocus;
    final shouldUseGradientText = selected && !highContrast;

    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: selected ? accent : text,
          backgroundColor: shouldShowSelectedBox
              ? accent.withValues(alpha: highContrast ? 0.24 : 0.12)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: shouldShowSelectedBox
                ? BorderSide(
                    color: accent,
                    width: highContrast ? 2 : 1,
                  )
                : BorderSide.none,
          ),
        ).copyWith(
          overlayColor: WidgetStatePropertyAll(
            visualFocus ? accent.withValues(alpha: 0.18) : null,
          ),
        ),
        child: shouldUseGradientText
            ? GradientText(
                text: label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: selected ? accent : text,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
      ),
    );
  }
}