import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../../core/accessibility/interface_narration_service.dart';
import '../../core/storage/storage_settings_service.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../shared/widgets/app_components.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/upload_panel.dart';
import '../library/services/library_service.dart';
import '../player/player_page.dart';
import 'controllers/generation_controller.dart';

class GeneratePage extends StatefulWidget {
  const GeneratePage({
    super.key,
    required this.highContrast,
    required this.visualFocus,
    required this.storageSettingsService,
    required this.libraryService,
    required this.reduceMotion,
    required this.simplifiedInterface,
    required this.narrationService,
    required this.onOpenSettings,
    required this.onOpenLibrary,
  });

  final bool highContrast;
  final bool visualFocus;
  final StorageSettingsService storageSettingsService;
  final LibraryService libraryService;
  final bool reduceMotion;
  final bool simplifiedInterface;
  final InterfaceNarrationService narrationService;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLibrary;

  @override
  State<GeneratePage> createState() => _GeneratePageState();
}

class _GeneratePageState extends State<GeneratePage> {
  late final GenerationController _controller;
  int? _selectedFileSize;
  GenerationUiState? _lastAnnouncedState;

  @override
  void initState() {
    super.initState();
    _controller = GenerationController(
      storageSettingsService: widget.storageSettingsService,
      libraryService: widget.libraryService,
    )..addListener(_refresh);
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    if (_lastAnnouncedState == _controller.state) return;
    _lastAnnouncedState = _controller.state;
    if (_controller.state == GenerationUiState.ready ||
        _controller.state == GenerationUiState.error) {
      unawaited(
        widget.narrationService.announce(context, _controller.statusMessage),
      );
    }
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

      final fileSize = await File(path).length();
      if (!mounted) return;
      setState(() => _selectedFileSize = fileSize);
      final duration = await _readDuration(path);
      if (!mounted) return;
      await _controller.startGeneration(
        videoPath: path,
        filename: file.name,
        videoDuration: duration,
      );
    } on Object {
      if (!mounted) return;
      _controller.selectionCancelled();
      _showMessage('Não foi possível abrir o seletor de arquivos.');
    }
  }

  Future<Duration?> _readDuration(String path) async {
    final video = VideoPlayerController.file(File(path));
    try {
      await video.initialize();
      return video.value.duration;
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Não foi possível ler a duração do vídeo: $error');
      debugPrint('$stackTrace');
      return null;
    } finally {
      await video.dispose();
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
          backTooltip: 'Voltar para Gerar',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: AppSpacing.pagePadding(constraints.maxWidth),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle(
                  title: 'Gerar audiodescrição',
                  subtitle: 'Selecione um vídeo para começar.',
                  highContrast: widget.highContrast,
                ),
                const SizedBox(height: AppSpacing.xl),
                UploadPanel(
                  highContrast: widget.highContrast,
                  visualFocus: widget.visualFocus,
                  reduceMotion:
                      widget.reduceMotion ||
                      MediaQuery.disableAnimationsOf(context),
                  simplifiedInterface: widget.simplifiedInterface,
                  enabled: !_controller.isBusy,
                  title: _controller.state == GenerationUiState.ready
                      ? 'Selecionar outro vídeo'
                      : 'Selecionar vídeo',
                  subtitle: _controller.filename == null
                      ? 'Clique ou use o teclado para escolher um arquivo'
                      : _selectedFileDescription(),
                  hint: _controller.isBusy
                      ? 'Aguarde a conclusão do processamento'
                      : 'Enter ou Espaço para selecionar • MP4, MOV, AVI, MKV, WEBM e M4V',
                  onTap: _selectVideo,
                ),
                if (_controller.state != GenerationUiState.idle) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _GenerationStatusPanel(
                    controller: _controller,
                    highContrast: widget.highContrast,
                    visualFocus: widget.visualFocus,
                    simplifiedInterface: widget.simplifiedInterface,
                    onPlay: _openPlayer,
                    onOpenSettings: widget.onOpenSettings,
                    onOpenLibrary: widget.onOpenLibrary,
                    onGenerateAnother: _selectVideo,
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppStatusMessage(
                  type: AppMessageType.information,
                  title: 'Formatos aceitos',
                  message:
                      'MP4, MOV, AVI, MKV, WEBM e M4V. O áudio final inclui o som original e a audiodescrição.',
                  highContrast: widget.highContrast,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _selectedFileDescription() {
    final parts = <String>[_controller.filename ?? 'Vídeo selecionado'];
    if (_selectedFileSize != null) parts.add(_formatBytes(_selectedFileSize!));
    final duration = _controller.videoDuration;
    if (duration != null) parts.add(_formatDuration(duration));
    return parts.join(' • ');
  }

  String _formatBytes(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return duration.inHours > 0
        ? '${duration.inHours}:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}

class _GenerationStatusPanel extends StatelessWidget {
  const _GenerationStatusPanel({
    required this.controller,
    required this.highContrast,
    required this.visualFocus,
    required this.simplifiedInterface,
    required this.onPlay,
    required this.onOpenSettings,
    required this.onOpenLibrary,
    required this.onGenerateAnother,
  });

  final GenerationController controller;
  final bool highContrast;
  final bool visualFocus;
  final bool simplifiedInterface;
  final VoidCallback onPlay;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLibrary;
  final VoidCallback onGenerateAnother;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final accent = AppColors.accentFor(highContrast);
    final isError = controller.state == GenerationUiState.error;
    final isReady = controller.state == GenerationUiState.ready;

    return Semantics(
      liveRegion: true,
      label: controller.statusMessage,
      child: AppCard(
        highContrast: highContrast,
        simplified: simplifiedInterface,
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
                    color: isError
                        ? AppColors.errorFor(highContrast)
                        : isReady
                        ? AppColors.successFor(highContrast)
                        : accent,
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
            if (controller.isBusy) ...[
              const SizedBox(height: AppSpacing.md),
              const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.md),
              _GenerationSteps(
                state: controller.state,
                highContrast: highContrast,
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
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  FocusTraversalOrder(
                    order: const NumericFocusOrder(5),
                    child: FilledButton.icon(
                      onPressed: onPlay,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Reproduzir'),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onOpenLibrary,
                    icon: const Icon(Icons.video_library_outlined),
                    label: const Text('Abrir biblioteca'),
                  ),
                  TextButton.icon(
                    onPressed: onGenerateAnother,
                    icon: const Icon(Icons.add),
                    label: const Text('Gerar outra'),
                  ),
                ],
              ),
            ],
            if (isError) ...[
              const SizedBox(height: 18),
              if (controller.requiresStorageConfiguration)
                ElevatedButton.icon(
                  onPressed: onOpenSettings,
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Ir para Configurações'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: highContrast ? Colors.black : Colors.white,
                  ),
                )
              else
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

class _GenerationSteps extends StatelessWidget {
  const _GenerationSteps({required this.state, required this.highContrast});

  final GenerationUiState state;
  final bool highContrast;

  int get _currentStep => switch (state) {
    GenerationUiState.selecting => 0,
    GenerationUiState.uploading => 1,
    GenerationUiState.queued => 2,
    GenerationUiState.processing => 3,
    GenerationUiState.downloadingAudio => 4,
    GenerationUiState.ready => 5,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    const labels = [
      'Selecionando vídeo',
      'Enviando vídeo',
      'Aguardando processamento',
      'Analisando cenas e áudio • gerando audiodescrição e voz',
      'Finalizando e salvando áudio',
    ];
    final accent = AppColors.accentFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (var index = 0; index < labels.length; index++)
          Semantics(
            label:
                '${labels[index]}, ${index < _currentStep
                    ? 'concluído'
                    : index == _currentStep
                    ? 'em andamento'
                    : 'pendente'}',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    index < _currentStep
                        ? Icons.check_circle
                        : index == _currentStep
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 17,
                    color: index <= _currentStep ? accent : secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  labels[index],
                  style: TextStyle(
                    color: index <= _currentStep ? accent : secondary,
                    fontSize: 13,
                    fontWeight: index == _currentStep
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
