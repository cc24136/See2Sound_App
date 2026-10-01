import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../features/app_shell/app_shell.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.currentPage,
    required this.highContrast,
    required this.visualFocus,
    required this.compact,
    required this.reduceMotion,
    required this.simplifiedInterface,
    required this.onChangePage,
  });

  final AppPage currentPage;
  final bool highContrast;
  final bool visualFocus;
  final bool compact;
  final bool reduceMotion;
  final bool simplifiedInterface;
  final ValueChanged<AppPage> onChangePage;

  @override
  Widget build(BuildContext context) {
    final border = AppColors.borderFor(highContrast);
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);

    return Semantics(
      container: true,
      label: 'Navegação principal',
      child: AnimatedContainer(
        duration: AppDurations.adaptive(reduceMotion),
        width: compact ? 76 : 264,
        decoration: BoxDecoration(
          color: AppColors.topBarFor(highContrast),
          border: Border(
            right: BorderSide(color: border, width: highContrast ? 2 : 1),
          ),
        ),
        child: Column(
          children: [
            SizedBox(
              height: 104,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 22),
                child: Row(
                  mainAxisAlignment: compact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: compact ? 44 : 52,
                        height: compact ? 44 : 52,
                      ),
                    ),
                    if (!compact) ...[
                      const SizedBox(width: AppSpacing.sm),
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
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Audiodescrição acessível',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: secondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Divider(height: highContrast ? 2 : 1),
            const SizedBox(height: AppSpacing.md),
            _NavigationButton(
              order: 1,
              icon: Icons.auto_awesome_outlined,
              label: 'Gerar audiodescrição',
              selected: currentPage == AppPage.generate,
              compact: compact,
              highContrast: highContrast,
              visualFocus: visualFocus,
              reduceMotion: reduceMotion,
              simplifiedInterface: simplifiedInterface,
              onTap: () => onChangePage(AppPage.generate),
            ),
            _NavigationButton(
              order: 2,
              icon: Icons.video_library_outlined,
              label: 'Suas audiodescrições',
              selected: currentPage == AppPage.library,
              compact: compact,
              highContrast: highContrast,
              visualFocus: visualFocus,
              reduceMotion: reduceMotion,
              simplifiedInterface: simplifiedInterface,
              onTap: () => onChangePage(AppPage.library),
            ),
            const Spacer(),
            _NavigationButton(
              order: 3,
              icon: Icons.settings_outlined,
              label: 'Configurações',
              selected: currentPage == AppPage.settings,
              compact: compact,
              highContrast: highContrast,
              visualFocus: visualFocus,
              reduceMotion: reduceMotion,
              simplifiedInterface: simplifiedInterface,
              onTap: () => onChangePage(AppPage.settings),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatefulWidget {
  const _NavigationButton({
    required this.order,
    required this.icon,
    required this.label,
    required this.selected,
    required this.compact,
    required this.highContrast,
    required this.visualFocus,
    required this.reduceMotion,
    required this.simplifiedInterface,
    required this.onTap,
  });

  final double order;
  final IconData icon;
  final String label;
  final bool selected;
  final bool compact;
  final bool highContrast;
  final bool visualFocus;
  final bool reduceMotion;
  final bool simplifiedInterface;
  final VoidCallback onTap;

  @override
  State<_NavigationButton> createState() => _NavigationButtonState();
}

class _NavigationButtonState extends State<_NavigationButton> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(widget.highContrast);
    final focus = AppColors.focusFor(widget.highContrast);
    final foreground = widget.selected
        ? accent
        : AppColors.textPrimaryFor(widget.highContrast);
    final showFocus = widget.visualFocus && _focused;
    final content = Row(
      mainAxisAlignment: widget.compact
          ? MainAxisAlignment.center
          : MainAxisAlignment.start,
      children: [
        ExcludeSemantics(child: Icon(widget.icon, color: foreground, size: 24)),
        if (!widget.compact) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              widget.label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: 15,
                fontWeight: widget.selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );

    return FocusTraversalOrder(
      order: NumericFocusOrder(widget.order),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Semantics(
          button: true,
          selected: widget.selected,
          label: widget.label,
          child: Tooltip(
            message: widget.compact ? widget.label : '',
            child: FocusableActionDetector(
              onShowFocusHighlight: (value) => setState(() => _focused = value),
              onShowHoverHighlight: (value) => setState(() => _hovered = value),
              mouseCursor: SystemMouseCursors.click,
              actions: {
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    widget.onTap();
                    return null;
                  },
                ),
              },
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: AppRadius.control,
                  child: AnimatedContainer(
                    duration: AppDurations.adaptive(widget.reduceMotion),
                    constraints: const BoxConstraints(minHeight: 52),
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.compact ? 10 : 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: widget.selected
                          ? accent.withValues(
                              alpha: widget.highContrast ? 0.2 : 0.13,
                            )
                          : _hovered && !widget.simplifiedInterface
                          ? AppColors.panelHover
                          : Colors.transparent,
                      borderRadius: AppRadius.control,
                      border: Border.all(
                        color: showFocus
                            ? focus
                            : widget.selected
                            ? accent
                            : Colors.transparent,
                        width: showFocus || widget.highContrast ? 2 : 1,
                      ),
                    ),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
