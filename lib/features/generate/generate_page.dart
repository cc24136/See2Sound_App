import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/upload_panel.dart';
import '../player/player_page.dart';
import 'controllers/generation_controller.dart';

class GeneratePage extends StatefulWidget {
  const GeneratePage({
    super.key,
    required this.highContrast,
    required this.visualFocus,
  });

  final bool highContrast;
  final bool visualFocus;

  @override
  State<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  late final GenerationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GenerationController()..addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  Future<void> _selectVideo() async {
    if (_controller.isBusy) return;
    _controller.beginSelection();
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: const ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v'],
      );
      if (!mounted) return;
      if (file == null) {
        _controller.selectionCancelled();
        return;
      }

      final path = file.path;
      if (path == null || path.isEmpty) {
        _controller.selectionCancelled();
        _showMessage('Não foi possível acessar o arquivo selecionado.');
        return;
      }

      await _controller.startGeneration(videoPath: path, filename: file.name);
    } on Object {
      if (!mounted) return;
      _controller.selectionCancelled();
      _showMessage('Não foi possível abrir o seletor de arquivos.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openPlayer() async {
    final videoPath = _controller.videoPath;
    final audioPath = _controller.audioPath;
    final filename = _controller.filename;
    if (videoPath == null || audioPath == null || filename == null) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PlayerPage(
          videoPath: videoPath,
          audioPath: audioPath,
          filename: filename,
          highContrast: widget.highContrast,
          visualFocus: widget.visualFocus,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final panel = AppColors.panelFor(widget.highContrast);
    final border = AppColors.borderFor(widget.highContrast);
    final secondary = AppColors.textSecondaryFor(widget.highContrast);
    final accent = AppColors.accentFor(widget.highContrast);

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
                highContrast: widget.highContrast,
                textAlign: TextAlign.center,
                crossAxisAlignment: CrossAxisAlignment.center,
              ),
              const SizedBox(height: 42),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: UploadPanel(
                  highContrast: widget.highContrast,
                  visualFocus: widget.visualFocus,
                  enabled: !_controller.isBusy,
                  title: _controller.state == GenerationUiState.ready
                      ? 'Importar outro arquivo'
                      : 'Importar Arquivo',
                  subtitle: _controller.filename == null
                      ? 'Selecione um vídeo para iniciar a geração da audiodescrição'
                      : _controller.filename!,
                  hint: _controller.isBusy
                      ? 'Aguarde a conclusão do processamento'
                      : 'Pressione Enter ou Espaço para selecionar',
                  onTap: _selectVideo,
                ),
              ),
              if (_controller.state != GenerationUiState.idle) ...[
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: _GenerationStatusPanel(
                    controller: _controller,
                    highContrast: widget.highContrast,
                    visualFocus: widget.visualFocus,
                    onPlay: _openPlayer,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: _FormatInfoBar(
                  panel: panel,
                  border: border,
                  secondary: secondary,
                  accent: accent,
                  highContrast: widget.highContrast,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GenerationStatusPanel extends StatelessWidget {
  const _GenerationStatusPanel({
    required this.controller,
    required this.highContrast,
    required this.visualFocus,
    required this.onPlay,
  });

  final GenerationController controller;
  final bool highContrast;
  final bool visualFocus;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final panel = AppColors.panelFor(highContrast);
    final border = AppColors.borderFor(highContrast);
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final accent = AppColors.accentFor(highContrast);
    final isError = controller.state == GenerationUiState.error;
    final isReady = controller.state == GenerationUiState.ready;

    return Semantics(
      liveRegion: true,
      label: controller.statusMessage,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isError ? Colors.redAccent : border,
            width: highContrast || isError ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (controller.isBusy)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: accent,
                    ),
                  )
                else
                  Icon(
                    isReady ? Icons.check_circle_outline : Icons.error_outline,
                    color: isError ? Colors.redAccent : accent,
                    size: 26,
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    controller.statusMessage,
                    style: TextStyle(
                      color: text,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (controller.connectionMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                controller.connectionMessage!,
                style: TextStyle(color: secondary, height: 1.35),
              ),
            ],
            if (isReady && controller.metadata != null) ...[
              const SizedBox(height: 16),
              _MetadataSummary(
                total: controller.metadata!.totalDescriptions,
                inserted: controller.metadata!.insertedDescriptions,
                skipped: controller.metadata!.skippedDescriptions,
                color: secondary,
              ),
            ],
            if (isReady) ...[
              const SizedBox(height: 18),
              FocusTraversalOrder(
                order: const NumericFocusOrder(5),
                child: ElevatedButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Reproduzir'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: highContrast ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9),
                      side: visualFocus
                          ? BorderSide(color: accent, width: 2)
                          : BorderSide.none,
                    ),
                  ),
                ),
              ),
            ],
            if (isError) ...[
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: controller.retry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: highContrast ? Colors.black : Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetadataSummary extends StatelessWidget {
  const _MetadataSummary({
    required this.total,
    required this.inserted,
    required this.skipped,
    required this.color,
  });

  final int total;
  final int inserted;
  final int skipped;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Audiodescrição concluída',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text('$total descrições geradas', style: TextStyle(color: color)),
        Text('$inserted inseridas', style: TextStyle(color: color)),
        Text(
          '$skipped ignoradas por falta de espaço',
          style: TextStyle(color: color),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: highContrast ? 2 : 1),
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
          Icon(Icons.info_outline, color: accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Formatos aceitos: MP4, MOV, AVI, MKV, WEBM e M4V. A audiodescrição será gerada respeitando os intervalos de fala do vídeo.',
              style: TextStyle(color: secondary, fontSize: 15, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
