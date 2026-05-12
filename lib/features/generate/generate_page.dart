import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/upload_panel.dart';

class GeneratePage extends StatelessWidget {
  const GeneratePage({
    super.key,
    required this.highContrast,
    required this.visualFocus,
  });

  final bool highContrast;
  final bool visualFocus;

  @override
  Widget build(BuildContext context) {
    final panel = AppColors.panelFor(highContrast);
    final border = AppColors.borderFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final accent = AppColors.accentFor(highContrast);

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(64, 86, 64, 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SectionTitle(
                title: 'Bem-vindo ao See2Sound',
                subtitle:
                    'Importe um novo arquivo para gerar uma nova audiodescrição.',
                highContrast: highContrast,
                textAlign: TextAlign.center,
                crossAxisAlignment: CrossAxisAlignment.center,
              ),

              const SizedBox(height: 42),

              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                ),
                child: UploadPanel(
                  highContrast: highContrast,
                  visualFocus: visualFocus,
                  onTap: () {
                    // Depois entra o seletor de arquivo.
                  },
                ),
              ),

              const SizedBox(height: 24),

              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 900,
                ),
                child: _FormatInfoBar(
                  panel: panel,
                  border: border,
                  secondary: secondary,
                  accent: accent,
                  highContrast: highContrast,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatInfoBar extends StatelessWidget {
  const _FormatInfoBar({
    required this.panel,
    required this.border,
    required this.secondary,
    required this.accent,
    required this.highContrast,
  });

  final Color panel;
  final Color border;
  final Color secondary;
  final Color accent;
  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: border,
          width: highContrast ? 2 : 1,
        ),
        boxShadow: [
          if (!highContrast)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: accent,
            size: 22,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              'Formatos recomendados: MP4, MOV ou AVI. A audiodescrição será gerada respeitando os intervalos de fala do vídeo.',
              style: TextStyle(
                color: secondary,
                fontSize: 15,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}