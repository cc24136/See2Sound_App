import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../features/app_shell/app_shell.dart';
import 'gradient_text.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
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
    final border = AppColors.borderFor(highContrast);
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final accent = AppColors.accentFor(highContrast);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.topBarFor(highContrast),
        border: Border(
          right: BorderSide(
            color: border,
            width: highContrast ? 2 : 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 112,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
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
                  width: 58,
                  height: 58,
                  fit: BoxFit.contain,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'See2Sound',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: text,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'ver 0.1',
                        style: TextStyle(
                          color: secondary,
                          fontSize: 13,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          _SidebarButton(
            order: 1,
            label: 'Gerar audiodescrição',
            selected: currentPage == AppPage.generate,
            highContrast: highContrast,
            visualFocus: visualFocus,
            onTap: () => onChangePage(AppPage.generate),
          ),

          const SizedBox(height: 10),

          _SidebarButton(
            order: 2,
            label: 'Suas audiodescrições',
            selected: currentPage == AppPage.library,
            highContrast: highContrast,
            visualFocus: visualFocus,
            onTap: () => onChangePage(AppPage.library),
          ),

          const Spacer(),

          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 22,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FocusTraversalOrder(
                order: const NumericFocusOrder(3),
                child: SizedBox(
                  width: 58,
                  height: 58,
                  child: IconButton(
                    tooltip: 'Abrir configurações',
                    onPressed: () => onChangePage(AppPage.settings),
                    icon: Icon(
                      Icons.settings_outlined,
                      color: currentPage == AppPage.settings ? accent : text,
                      size: 34,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          currentPage == AppPage.settings && visualFocus
                              ? accent.withValues(alpha: 0.14)
                              : Colors.transparent,
                      side: currentPage == AppPage.settings && visualFocus
                          ? BorderSide(
                              color: accent,
                              width: highContrast ? 2 : 1,
                            )
                          : BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
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

    final shouldShowBox = selected && visualFocus;
    final shouldUseGradientText = selected && !highContrast;

    return FocusTraversalOrder(
      order: NumericFocusOrder(order),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 58),
            alignment: Alignment.centerLeft,
            foregroundColor: selected ? accent : text,
            backgroundColor: shouldShowBox
                ? accent.withValues(alpha: highContrast ? 0.24 : 0.12)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: shouldShowBox
                  ? BorderSide(
                      color: accent,
                      width: highContrast ? 2 : 1,
                    )
                  : BorderSide.none,
            ),
          ).copyWith(
            overlayColor: WidgetStatePropertyAll(
              accent.withValues(alpha: 0.16),
            ),
          ),
          child: shouldUseGradientText
              ? GradientText(
                  text: label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : Text(
                  label,
                  style: TextStyle(
                    color: selected ? accent : text,
                    fontSize: 16,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}