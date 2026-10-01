import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_design_tokens.dart';

enum AppMessageType { information, success, warning, error }

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    required this.highContrast,
    this.simplified = false,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  final Widget child;
  final bool highContrast;
  final bool simplified;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.panelFor(highContrast),
        borderRadius: AppRadius.card,
        border: Border.all(
          color: AppColors.borderFor(highContrast),
          width: highContrast ? 2 : 1,
        ),
        boxShadow: highContrast || simplified
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: child,
    );
  }
}

class AppStatusMessage extends StatelessWidget {
  const AppStatusMessage({
    super.key,
    required this.type,
    required this.title,
    required this.highContrast,
    this.message,
    this.action,
    this.liveRegion = false,
  });

  final AppMessageType type;
  final String title;
  final String? message;
  final bool highContrast;
  final Widget? action;
  final bool liveRegion;

  Color _color() => switch (type) {
    AppMessageType.information =>
      highContrast ? Colors.cyanAccent : AppColors.info,
    AppMessageType.success => AppColors.successFor(highContrast),
    AppMessageType.warning => AppColors.warningFor(highContrast),
    AppMessageType.error => AppColors.errorFor(highContrast),
  };

  IconData _icon() => switch (type) {
    AppMessageType.information => Icons.info_outline,
    AppMessageType.success => Icons.check_circle_outline,
    AppMessageType.warning => Icons.warning_amber_rounded,
    AppMessageType.error => Icons.error_outline,
  };

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Semantics(
      container: true,
      liveRegion: liveRegion,
      label: message == null ? title : '$title. $message',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: highContrast ? 0.08 : 0.1),
          borderRadius: AppRadius.control,
          border: Border.all(color: color, width: highContrast ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(_icon(), color: color, size: 24)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.label.copyWith(color: color),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      message!,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimaryFor(highContrast),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(width: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.highContrast,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool highContrast;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: '$title. $message',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.accentFor(
                    highContrast,
                  ).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 36,
                  color: AppColors.accentFor(highContrast),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.sectionTitle.copyWith(
                color: AppColors.textPrimaryFor(highContrast),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondaryFor(highContrast),
                ),
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.lg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
