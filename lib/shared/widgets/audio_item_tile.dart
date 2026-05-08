import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum AudioDescriptionStatus {
  ready,
  processing,
  draft,
}

class AudioItemTile extends StatefulWidget {
  const AudioItemTile({
    super.key,
    required this.order,
    required this.title,
    required this.duration,
    required this.status,
    required this.highContrast,
    required this.visualFocus,
    required this.onPrimaryAction,
  });

  final double order;
  final String title;
  final String duration;
  final AudioDescriptionStatus status;
  final bool highContrast;
  final bool visualFocus;
  final VoidCallback onPrimaryAction;

  @override
  State<AudioItemTile> createState() => _AudioItemTileState();
}

class _AudioItemTileState extends State<AudioItemTile> {
  bool focused = false;
  bool hovered = false;

  String get statusLabel {
    switch (widget.status) {
      case AudioDescriptionStatus.ready:
        return 'Pronto';
      case AudioDescriptionStatus.processing:
        return 'Processando';
      case AudioDescriptionStatus.draft:
        return 'Não iniciado';
    }
  }

  String get buttonLabel {
    switch (widget.status) {
      case AudioDescriptionStatus.ready:
        return 'Reproduzir';
      case AudioDescriptionStatus.processing:
        return 'Ver progresso';
      case AudioDescriptionStatus.draft:
        return 'Iniciar audiodescrição';
    }
  }

  IconData get statusIcon {
    switch (widget.status) {
      case AudioDescriptionStatus.ready:
        return Icons.check_circle_outline;
      case AudioDescriptionStatus.processing:
        return Icons.hourglass_top_rounded;
      case AudioDescriptionStatus.draft:
        return Icons.play_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(widget.highContrast);
    final panel = AppColors.panelFor(widget.highContrast);
    final border = AppColors.borderFor(widget.highContrast);
    final text = AppColors.textPrimaryFor(widget.highContrast);
    final secondary = AppColors.textSecondaryFor(widget.highContrast);

    final showFocus = widget.visualFocus && focused;

    return FocusTraversalOrder(
      order: NumericFocusOrder(widget.order),
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) {
          setState(() {
            focused = value;
          });
        },
        onShowHoverHighlight: (value) {
          setState(() {
            hovered = value;
          });
        },
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPrimaryAction();
              return null;
            },
          ),
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hovered ? AppColors.panelHover : panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: showFocus ? accent : border,
              width: showFocus || widget.highContrast ? 3 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: LinearGradient(
                    colors: widget.highContrast
                        ? [accent, accent]
                        : [AppColors.accent, AppColors.accentDark],
                  ),
                ),
                child: Icon(
                  Icons.movie_outlined,
                  color: widget.highContrast ? Colors.black : Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          statusIcon,
                          color: accent,
                          size: 17,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.schedule,
                          color: secondary,
                          size: 16,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          widget.duration,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              ElevatedButton(
                onPressed: widget.onPrimaryAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor:
                      widget.highContrast ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  buttonLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}