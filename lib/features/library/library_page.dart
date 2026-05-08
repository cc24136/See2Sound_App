import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/audio_item_tile.dart';
import '../../shared/widgets/page_container.dart';
import '../../shared/widgets/section_title.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({
    super.key,
    required this.highContrast,
    required this.visualFocus,
  });

  final bool highContrast;
  final bool visualFocus;

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Suas audiodescrições',
            subtitle:
                'Gerencie os vídeos importados e inicie a geração de audiodescrição.',
            highContrast: highContrast,
          ),

          const SizedBox(height: 24),

          _ImportNewVideoCard(
            highContrast: highContrast,
            visualFocus: visualFocus,
          ),

          const SizedBox(height: 18),

          AudioItemTile(
            order: 5,
            title: 'Apresentação See2Sound.mp4',
            duration: '02:57',
            status: AudioDescriptionStatus.ready,
            highContrast: highContrast,
            visualFocus: visualFocus,
            onPrimaryAction: () {},
          ),

          const SizedBox(height: 12),

          AudioItemTile(
            order: 6,
            title: 'Trecho de documentário.mp4',
            duration: '08:33',
            status: AudioDescriptionStatus.draft,
            highContrast: highContrast,
            visualFocus: visualFocus,
            onPrimaryAction: () {},
          ),

          const SizedBox(height: 12),

          AudioItemTile(
            order: 7,
            title: 'Tutorial de cadastro.mp4',
            duration: '06:18',
            status: AudioDescriptionStatus.processing,
            highContrast: highContrast,
            visualFocus: visualFocus,
            onPrimaryAction: () {},
          ),
        ],
      ),
    );
  }
}

class _ImportNewVideoCard extends StatefulWidget {
  const _ImportNewVideoCard({
    required this.highContrast,
    required this.visualFocus,
  });

  final bool highContrast;
  final bool visualFocus;

  @override
  State<_ImportNewVideoCard> createState() => _ImportNewVideoCardState();
}

class _ImportNewVideoCardState extends State<_ImportNewVideoCard> {
  bool focused = false;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(widget.highContrast);
    final text = AppColors.textPrimaryFor(widget.highContrast);
    final secondary = AppColors.textSecondaryFor(widget.highContrast);
    final border = AppColors.borderFor(widget.highContrast);

    return FocusTraversalOrder(
      order: const NumericFocusOrder(4),
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) {
          setState(() {
            focused = value;
          });
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              return null;
            },
          ),
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.panelFor(widget.highContrast),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.visualFocus && focused ? accent : border,
              width: widget.visualFocus && focused ? 3 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.add_circle_outline,
                color: accent,
                size: 34,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Importar novo vídeo',
                      style: TextStyle(
                        color: text,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Adicione um novo arquivo para gerar audiodescrição.',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload_file),
                label: const Text('Selecionar arquivo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor:
                      widget.highContrast ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
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