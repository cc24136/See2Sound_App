import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class UploadPanel extends StatefulWidget {
  const UploadPanel({
    super.key,
    required this.onTap,
    required this.highContrast,
    required this.visualFocus,
  });

  final VoidCallback onTap;
  final bool highContrast;
  final bool visualFocus;

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

    return FocusTraversalOrder(
      order: const NumericFocusOrder(4),
      child: FocusableActionDetector(
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
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: isHovered
                  ? AppColors.panelHover
                  : panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: showFocus ? accent : border,
                width: showFocus || widget.highContrast ? 3 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.upload_file_rounded,
                  size: 64,
                  color: accent,
                ),
                const SizedBox(height: 18),
                Text(
                  'Importar Arquivo',
                  style: TextStyle(
                    color: text,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Selecione um vídeo para iniciar a geração da audiodescrição',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Pressione Enter ou Espaço para selecionar',
                  style: TextStyle(
                    color: secondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}