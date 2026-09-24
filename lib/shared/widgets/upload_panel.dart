import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class UploadPanel extends StatefulWidget {
  const UploadPanel({
    super.key,
    required this.onTap,
    required this.highContrast,
    required this.visualFocus,
    this.enabled = true,
    this.title = 'Importar Arquivo',
    this.subtitle =
        'Selecione um vídeo para iniciar a geração da audiodescrição',
    this.hint = 'Pressione Enter ou Espaço para selecionar',
    this.icon = Icons.upload_file_rounded,
  });

  final VoidCallback onTap;
  final bool highContrast;
  final bool visualFocus;
  final bool enabled;
  final String title;
  final String subtitle;
  final String hint;
  final IconData icon;

  @override
  State<UploadPanel> createState() => _UploadPanelState();
}

class _UploadPanelState extends State<UploadPanel> {
  bool isFocused = false;
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(widget.highContrast);
    final panel = AppColors.panelFor(widget.highContrast);
    final border = AppColors.borderFor(widget.highContrast);
    final text = AppColors.textPrimaryFor(widget.highContrast);
    final secondary = AppColors.textSecondaryFor(widget.highContrast);

    final showFocus = widget.visualFocus && isFocused;

    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.title,
      hint: widget.enabled ? widget.subtitle : 'Aguarde o processamento atual',
      child: FocusTraversalOrder(
        order: const NumericFocusOrder(4),
        child: FocusableActionDetector(
          enabled: widget.enabled,
          onShowFocusHighlight: (value) {
            setState(() {
              isFocused = value;
            });
          },
          onShowHoverHighlight: (value) {
            setState(() {
              isHovered = value;
            });
          },
          mouseCursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                if (widget.enabled) widget.onTap();
                return null;
              },
            ),
          },
          child: InkWell(
            onTap: widget.enabled ? widget.onTap : null,
            borderRadius: BorderRadius.circular(18),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              constraints: const BoxConstraints(minHeight: 360),
              width: double.infinity,
              decoration: BoxDecoration(
                color: isHovered && widget.enabled
                    ? AppColors.panelHover
                    : panel,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: showFocus ? accent : border,
                  width: showFocus || widget.highContrast ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return widget.highContrast
                          ? LinearGradient(
                              colors: [accent, accent],
                            ).createShader(bounds)
                          : AppColors.mainGradient.createShader(bounds);
                    },
                    child: Icon(widget.icon, size: 82, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: text,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: secondary, fontSize: 18),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.hint,
                    style: TextStyle(color: secondary, fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
