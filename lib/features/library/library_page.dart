import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

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
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final panel = AppColors.panelFor(highContrast);
    final border = AppColors.borderFor(highContrast);
    final accent = AppColors.accentFor(highContrast);

    final items = [
      const _AudioDescriptionItemData(
        title: 'Apresentação See2Sound.mp4',
        description: 'Audiodescrição gerada',
        duration: '02:57',
        date: 'Hoje',
        status: AudioDescriptionStatus.ready,
      ),
      const _AudioDescriptionItemData(
        title: 'Trecho de documentário.mp4',
        description: 'Pronto para iniciar',
        duration: '08:33',
        date: 'Ontem',
        status: AudioDescriptionStatus.notStarted,
      ),
      const _AudioDescriptionItemData(
        title: 'Tutorial de cadastro.mp4',
        description: 'Analisando cenas e pausas',
        duration: '06:18',
        date: 'Ontem',
        status: AudioDescriptionStatus.processing,
      ),
      const _AudioDescriptionItemData(
        title: 'Vídeo institucional.mp4',
        description: 'Audiodescrição gerada',
        duration: '03:42',
        date: '12/05',
        status: AudioDescriptionStatus.ready,
      ),
      const _AudioDescriptionItemData(
        title: 'Aula introdutória.mp4',
        description: 'Pronto para iniciar',
        duration: '11:20',
        date: '10/05',
        status: AudioDescriptionStatus.notStarted,
      ),
    ];

    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(64, 72, 64, 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LibraryHeader(
                highContrast: highContrast,
                visualFocus: visualFocus,
              ),

              const SizedBox(height: 28),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: panel,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: border,
                    width: highContrast ? 2 : 1,
                  ),
                  boxShadow: [
                    if (!highContrast)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                  ],
                ),
                child: Column(
                  children: [
                    _ListHeader(
                      highContrast: highContrast,
                    ),

                    const SizedBox(height: 12),

                    for (int index = 0; index < items.length; index++) ...[
                      _AudioDescriptionTile(
                        order: 4 + index.toDouble(),
                        data: items[index],
                        highContrast: highContrast,
                        visualFocus: visualFocus,
                        onPrimaryAction: () {
                          // Depois: abrir player, iniciar processo ou mostrar progresso.
                        },
                      ),
                      if (index != items.length - 1) const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: accent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'As audiodescrições geradas ficarão salvas aqui para reprodução, revisão ou exportação.',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 14,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.highContrast,
    required this.visualFocus,
  });

  final bool highContrast;
  final bool visualFocus;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final accent = AppColors.accentFor(highContrast);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Suas audiodescrições',
                style: TextStyle(
                  color: text,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Escolha um vídeo salvo para reproduzir, continuar ou revisar.',
                style: TextStyle(
                  color: secondary,
                  fontSize: 17,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),

        FocusTraversalOrder(
          order: const NumericFocusOrder(3),
          child: ElevatedButton.icon(
            onPressed: () {
              // Depois: navegar para tela de importação ou abrir file picker.
            },
            icon: const Icon(Icons.add),
            label: const Text('Novo vídeo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: highContrast ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 16,
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: visualFocus
                    ? BorderSide(
                        color: accent,
                        width: highContrast ? 2 : 1,
                      )
                    : BorderSide.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ListHeader extends StatelessWidget {
  const _ListHeader({
    required this.highContrast,
  });

  final bool highContrast;

  @override
  Widget build(BuildContext context) {
    final secondary = AppColors.textSecondaryFor(highContrast);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(
              'Arquivo',
              style: TextStyle(
                color: secondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Status',
              style: TextStyle(
                color: secondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text(
              'Duração',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: secondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(
              'Ação',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

enum AudioDescriptionStatus {
  ready,
  processing,
  notStarted,
}

class _AudioDescriptionItemData {
  const _AudioDescriptionItemData({
    required this.title,
    required this.description,
    required this.duration,
    required this.date,
    required this.status,
  });

  final String title;
  final String description;
  final String duration;
  final String date;
  final AudioDescriptionStatus status;
}

class _AudioDescriptionTile extends StatefulWidget {
  const _AudioDescriptionTile({
    required this.order,
    required this.data,
    required this.highContrast,
    required this.visualFocus,
    required this.onPrimaryAction,
  });

  final double order;
  final _AudioDescriptionItemData data;
  final bool highContrast;
  final bool visualFocus;
  final VoidCallback onPrimaryAction;

  @override
  State<_AudioDescriptionTile> createState() => _AudioDescriptionTileState();
}

class _AudioDescriptionTileState extends State<_AudioDescriptionTile> {
  bool focused = false;
  bool hovered = false;

  String get statusLabel {
    switch (widget.data.status) {
      case AudioDescriptionStatus.ready:
        return 'Pronto';
      case AudioDescriptionStatus.processing:
        return 'Processando';
      case AudioDescriptionStatus.notStarted:
        return 'Não iniciado';
    }
  }

  String get buttonLabel {
    switch (widget.data.status) {
      case AudioDescriptionStatus.ready:
        return 'Reproduzir';
      case AudioDescriptionStatus.processing:
        return 'Progresso';
      case AudioDescriptionStatus.notStarted:
        return 'Iniciar';
    }
  }

  IconData get statusIcon {
    switch (widget.data.status) {
      case AudioDescriptionStatus.ready:
        return Icons.check_circle_outline;
      case AudioDescriptionStatus.processing:
        return Icons.hourglass_top_rounded;
      case AudioDescriptionStatus.notStarted:
        return Icons.play_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(widget.highContrast);
    final text = AppColors.textPrimaryFor(widget.highContrast);
    final secondary = AppColors.textSecondaryFor(widget.highContrast);
    final border = AppColors.borderFor(widget.highContrast);

    final showFocus = widget.visualFocus && focused;

    return FocusTraversalOrder(
      order: NumericFocusOrder(widget.order),
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: hovered
                ? AppColors.panelHover
                : AppColors.backgroundFor(widget.highContrast),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: showFocus ? accent : border,
              width: showFocus || widget.highContrast ? 3 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: widget.highContrast
                            ? LinearGradient(colors: [accent, accent])
                            : AppColors.mainGradient,
                      ),
                      child: Icon(
                        Icons.movie_outlined,
                        color: widget.highContrast ? Colors.black : Colors.white,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.data.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.data.description} • ${widget.data.date}',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: secondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(
                      statusIcon,
                      color: accent,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        statusLabel,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: secondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(
                width: 90,
                child: Text(
                  widget.data.duration,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(width: 16),

              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: widget.onPrimaryAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor:
                        widget.highContrast ? Colors.black : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(buttonLabel),
                ),
              ),

              const SizedBox(width: 8),

              IconButton(
                tooltip: 'Mais opções',
                onPressed: () {
                  // Depois: menu de exportar, renomear, excluir etc.
                },
                icon: Icon(
                  Icons.more_vert,
                  color: secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}