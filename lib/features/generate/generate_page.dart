import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../../core/accessibility/interface_narration_service.dart';
import '../../core/config/api_settings_service.dart';
import '../../core/storage/storage_settings_service.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../shared/widgets/app_components.dart';
import '../../shared/widgets/section_title.dart';
import '../../shared/widgets/upload_panel.dart';
import '../library/services/library_service.dart';
import '../player/player_page.dart';
import 'controllers/generation_controller.dart';
import 'services/see2sound_api_service.dart';

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
    required this.apiSettingsService,
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
  final ApiSettingsService apiSettingsService;
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
      apiService: See2SoundApiService(
        uriBuilder: widget.apiSettingsService.uri,
      ),
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
        _controller.state == GenerationUiState.completedWithoutAudio ||
        _controller.state == GenerationUiState.completedWithoutDescriptions ||
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
      if (fileSize == 0) {
        _controller.selectionCancelled();
        _showMessage('O vídeo selecionado está vazio. Escolha outro arquivo.');
        return;
      }
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
      await video.initialize().timeout(const Duration(seconds: 15));
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

  bool _openingPlayer = false;

  Future<void> _openPlayer() async {
    if (_openingPlayer || !mounted) return;

    _openingPlayer = true;

    try {
      // Utiliza o vídeo com pausas quando existir.
      // Caso contrário, utiliza o vídeo original.
      final videoPath = _controller.playbackVideoPath;

      final audioPath = _controller.audioPath;
      final filename = _controller.filename;

      if (videoPath == null || audioPath == null || filename == null) {
        return;
      }

      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => MediaQuery(
            data: MediaQuery.of(context),
            child: InheritedTheme.captureAll(
              context,
              PlayerPage(
                videoPath: videoPath,
                audioPath: audioPath,
                filename: filename,
                highContrast: widget.highContrast,
                visualFocus: widget.visualFocus,
                backTooltip: 'Voltar para Gerar',
              ),
            ),
          ),
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('[See2Sound] Não foi possível abrir reprodução: $error');

      debugPrint('$stackTrace');

      if (mounted) {
        _showMessage(
          'Não foi possível abrir a reprodução. '
          'Verifique os arquivos e tente novamente.',
        );
      }
    } finally {
      _openingPlayer = false;
    }
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
                  GenerationStatusPanel(
                    reduceMotion:
                        widget.reduceMotion ||
                        MediaQuery.disableAnimationsOf(context),
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

class GenerationStatusPanel extends StatelessWidget {
  const GenerationStatusPanel({
    super.key,
    required this.controller,
    required this.highContrast,
    required this.visualFocus,
    required this.simplifiedInterface,
    required this.onPlay,
    required this.onOpenSettings,
    required this.onOpenLibrary,
    required this.onGenerateAnother,
    this.reduceMotion = false,
  });

  final GenerationController controller;
  final bool highContrast;
  final bool visualFocus;
  final bool simplifiedInterface;
  final VoidCallback onPlay;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenLibrary;
  final VoidCallback onGenerateAnother;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final text = AppColors.textPrimaryFor(highContrast);
    final secondary = AppColors.textSecondaryFor(highContrast);
    final accent = AppColors.accentFor(highContrast);
    final isError = controller.state == GenerationUiState.error;
    final isReady = controller.state == GenerationUiState.ready;
    final completedWithoutDescriptions =
        controller.state == GenerationUiState.completedWithoutDescriptions;
    final completedWithoutAudio =
        controller.state == GenerationUiState.completedWithoutAudio;
    final isCompletedNotice =
        completedWithoutDescriptions || completedWithoutAudio;

    final isApiProgress =
        controller.state == GenerationUiState.queued ||
        controller.state == GenerationUiState.processing ||
        controller.state == GenerationUiState.downloadingAudio;
    final percent = isApiProgress ? controller.progressPercent : null;
    final countAvailable =
        controller.state == GenerationUiState.processing &&
        controller.stageCurrent != null &&
        controller.stageTotal != null &&
        controller.stageTotal! > 0 &&
        controller.stageCurrent! <= controller.stageTotal!;

    return Semantics(
      container: true,
      child: AppCard(
        highContrast: highContrast,
        simplified: simplifiedInterface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (controller.isBusy && !reduceMotion)
                  ExcludeSemantics(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: accent,
                      ),
                    ),
                  )
                else
                  Icon(
                    controller.isBusy
                        ? Icons.hourglass_top
                        : isReady
                        ? Icons.check_circle_outline
                        : isCompletedNotice
                        ? Icons.info_outline
                        : Icons.error_outline,
                    color: isError
                        ? AppColors.errorFor(highContrast)
                        : isReady
                        ? AppColors.successFor(highContrast)
                        : isCompletedNotice
                        ? AppColors.warningFor(highContrast)
                        : accent,
                    size: 26,
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      controller.statusMessage,
                      style: TextStyle(
                        color: text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
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
              if (isApiProgress &&
                  controller.state != GenerationUiState.downloadingAudio) ...[
                Text(
                  'Gerando audiodescrição',
                  style: TextStyle(color: text, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (percent != null) ...[
                Text(
                  '${_formatPercent(percent)}% concluído',
                  style: TextStyle(color: text),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              if (countAvailable) ...[
                Text(
                  '${controller.stageCurrent} de ${controller.stageTotal}',
                  style: TextStyle(color: secondary),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              // Percent changes remain readable without becoming live announcements.
              Semantics(
                label: isApiProgress
                    ? 'Progresso da geração na API'
                    : controller.statusMessage,
                value: percent == null
                    ? 'Em andamento'
                    : '${_formatPercent(percent)}%',
                excludeSemantics: true,
                child: TickerMode(
                  enabled: !reduceMotion,
                  child: _GenerationProgressBar(
                    value: percent == null ? null : percent / 100,
                    highContrast: highContrast,
                    reduceMotion: reduceMotion,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _GenerationSteps(
                state: controller.state,
                highContrast: highContrast,
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
            if (isCompletedNotice) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                completedWithoutDescriptions
                    ? 'A análise foi concluída e não identificou trechos que precisassem de novas descrições.'
                    : 'A análise foi concluída, mas o servidor não disponibilizou o áudio para reprodução.',
                style: TextStyle(color: secondary, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  OutlinedButton.icon(
                    onPressed: onOpenLibrary,
                    icon: const Icon(Icons.video_library_outlined),
                    label: const Text('Abrir biblioteca'),
                  ),
                  FilledButton.icon(
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

class _GenerationProgressBar extends StatefulWidget {
  const _GenerationProgressBar({
    required this.value,
    required this.highContrast,
    required this.reduceMotion,
  });

  final double? value;
  final bool highContrast;
  final bool reduceMotion;

  @override
  State<_GenerationProgressBar> createState() => _GenerationProgressBarState();
}

class _GenerationProgressBarState extends State<_GenerationProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow;

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _GenerationProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.value != null && !widget.reduceMotion) {
      if (!_flow.isAnimating) _flow.repeat();
    } else {
      _flow.stop();
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(widget.highContrast);
    final track = AppColors.borderFor(widget.highContrast);
    final radius = BorderRadius.circular(4);
    if (widget.value == null) {
      return LinearProgressIndicator(
        color: accent,
        backgroundColor: track,
        borderRadius: radius,
      );
    }
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: ColoredBox(
          color: track,
          child: AnimatedBuilder(
            animation: _flow,
            // Only the shader changes per frame; the exact fill stays intact.
            child: LinearProgressIndicator(
              value: widget.value,
              color: Colors.white,
              backgroundColor: Colors.transparent,
              borderRadius: radius,
            ),
            builder: (context, child) => ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  LinearGradient(
                    colors: widget.highContrast
                        ? [accent, AppColors.highContrastText, accent]
                        : const [
                            AppColors.accentDark,
                            AppColors.accent,
                            Color(0xFFE879F9),
                            AppColors.accentDark,
                          ],
                    tileMode: TileMode.repeated,
                  ).createShader(
                    Rect.fromLTWH(
                      bounds.left +
                          (widget.reduceMotion ? 0 : _flow.value) *
                              bounds.width,
                      bounds.top,
                      bounds.width,
                      bounds.height,
                    ),
                  ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

String _formatPercent(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);

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
    GenerationUiState.completedWithoutDescriptions ||
    GenerationUiState.completedWithoutAudio => 5,
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
            excludeSemantics: true,
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
                Flexible(
                  child: Text(
                    labels[index],
                    style: TextStyle(
                      color: index <= _currentStep ? accent : secondary,
                      fontSize: 13,
                      fontWeight: index == _currentStep
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
