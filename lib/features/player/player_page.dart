import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_design_tokens.dart';
import '../../shared/widgets/app_components.dart';
import '../../shared/widgets/video_viewport.dart';
import 'synchronized_media_controller.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.videoPath,
    required this.audioPath,
    required this.filename,
    required this.highContrast,
    required this.visualFocus,
    this.backTooltip = 'Voltar',
  });

  final String videoPath;
  final String audioPath;
  final String filename;
  final bool highContrast;
  final bool visualFocus;
  final String backTooltip;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> with WidgetsBindingObserver {
  late SynchronizedMediaController _controller;
  Object? _initializationError;
  Duration? _pendingSeek;
  bool _expandedVideo = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _createController();
  }

  void _createController() {
    _initializationError = null;
    _pendingSeek = null;
    _controller = SynchronizedMediaController(
      videoPath: widget.videoPath,
      audioPath: widget.audioPath,
    )..addListener(_refresh);
    unawaited(_initialize(_controller));
  }

  Future<void> _initialize(SynchronizedMediaController controller) async {
    try {
      await controller.initialize();
    } on Object catch (error, stackTrace) {
      debugPrint('[See2Sound] Erro ao inicializar player: $error');
      debugPrint('$stackTrace');
      if (mounted && identical(controller, _controller)) {
        setState(() => _initializationError = error);
      }
    }
  }

  void _replaceController() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _createController();
  }

  @override
  void didUpdateWidget(covariant PlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoPath != widget.videoPath ||
        oldWidget.audioPath != widget.audioPath) {
      _replaceController();
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_controller.pause());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final background = AppColors.backgroundFor(widget.highContrast);
    final text = AppColors.textPrimaryFor(widget.highContrast);
    final secondary = AppColors.textSecondaryFor(widget.highContrast);
    final accent = AppColors.accentFor(widget.highContrast);

    return Scaffold(
      backgroundColor: background,
      appBar: _expandedVideo
          ? null
          : AppBar(
              backgroundColor: AppColors.topBarFor(widget.highContrast),
              foregroundColor: text,
              leading: IconButton(
                tooltip: widget.backTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
              ),
              title: Text(
                widget.filename,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space):
              _controller.togglePlayback,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              _controller.seekBy(const Duration(seconds: -5)),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              _controller.seekBy(const Duration(seconds: 5)),
          const SingleActivator(LogicalKeyboardKey.escape): () {
            if (_expandedVideo) setState(() => _expandedVideo = false);
          },
        },
        child: Focus(
          autofocus: true,
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(
                _expandedVideo || MediaQuery.sizeOf(context).width < 600
                    ? 8
                    : 32,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _expandedVideo ? 1600 : 1080,
                ),
                child: AppCard(
                  highContrast: widget.highContrast,
                  padding: EdgeInsets.all(_expandedVideo ? 8 : 20),
                  child: _buildContent(text, secondary, accent),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color text, Color secondary, Color accent) {
    if (_initializationError != null || _controller.errorMessage != null) {
      return Semantics(
        liveRegion: true,
        child: VideoViewport(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Icon(Icons.error_outline, color: accent, size: 40),
                ),
                const SizedBox(height: 12),
                Text(
                  _controller.errorMessage ??
                      'Não foi possível abrir o vídeo e a audiodescrição. Verifique os arquivos e o formato de vídeo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => setState(_replaceController),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_controller.isInitialized) {
      return Semantics(
        liveRegion: true,
        label: _controller.initializationMessage,
        excludeSemantics: true,
        child: VideoViewport(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                CircularProgressIndicator(color: accent),
                const SizedBox(height: 16),
                Flexible(
                  child: Text(
                    _controller.initializationMessage,
                    style: TextStyle(color: text),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final video = _controller.videoController.value;
    if (video.hasError) {
      return Text(
        'Erro durante a reprodução do vídeo.',
        style: TextStyle(color: text),
      );
    }

    final duration = _controller.duration;
    final shownPosition = _pendingSeek ?? _controller.position;
    final maxMillis = duration.inMilliseconds
        .toDouble()
        .clamp(1, double.infinity)
        .toDouble();
    final positionMillis = shownPosition.inMilliseconds
        .toDouble()
        .clamp(0, maxMillis)
        .toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!_expandedVideo) ...[
          Text(
            widget.filename,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.sectionTitle.copyWith(color: text),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        Semantics(
          label: 'Vídeo ${widget.filename} com audiodescrição',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: VideoViewport(
              videoSize: video.size,
              child: VideoPlayer(_controller.videoController),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          label:
              'Posição ${_formatDuration(shownPosition)} de ${_formatDuration(duration)}',
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: accent,
              thumbColor: accent,
              overlayColor: accent.withValues(alpha: 0.18),
              inactiveTrackColor: secondary.withValues(alpha: 0.3),
            ),
            child: Slider(
              value: positionMillis,
              min: 0,
              max: maxMillis,
              semanticFormatterCallback: (value) =>
                  _formatDuration(Duration(milliseconds: value.round())),
              onChanged: (value) {
                setState(() {
                  _pendingSeek = Duration(milliseconds: value.round());
                });
              },
              onChangeEnd: (value) async {
                final target = Duration(milliseconds: value.round());
                await _controller.seekTo(target);
                if (mounted) setState(() => _pendingSeek = null);
              },
            ),
          ),
        ),
        Row(
          children: [
            Text(_formatDuration(shownPosition), style: TextStyle(color: text)),
            const Spacer(),
            Text(_formatDuration(duration), style: TextStyle(color: secondary)),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _ControlButton(
                tooltip: 'Reiniciar',
                semanticLabel: 'Reiniciar vídeo',
                icon: Icons.replay,
                onPressed: _controller.restart,
                highContrast: widget.highContrast,
                visualFocus: widget.visualFocus,
              ),
              _ControlButton(
                tooltip: 'Voltar 5 segundos',
                semanticLabel: 'Voltar cinco segundos',
                icon: Icons.replay_5,
                onPressed: () =>
                    _controller.seekBy(const Duration(seconds: -5)),
                highContrast: widget.highContrast,
                visualFocus: widget.visualFocus,
              ),
              Semantics(
                button: true,
                label: _controller.isPlaying ? 'Pausar' : 'Reproduzir',
                child: Tooltip(
                  message: _controller.isPlaying ? 'Pausar' : 'Reproduzir',
                  excludeFromSemantics: true,
                  child: ElevatedButton(
                    onPressed: _controller.togglePlayback,
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(18),
                      backgroundColor: accent,
                      foregroundColor: widget.highContrast
                          ? Colors.black
                          : Colors.white,
                    ),
                    child: Icon(
                      _controller.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 32,
                    ),
                  ),
                ),
              ),
              _ControlButton(
                tooltip: 'Avançar 5 segundos',
                semanticLabel: 'Avançar cinco segundos',
                icon: Icons.forward_5,
                onPressed: () => _controller.seekBy(const Duration(seconds: 5)),
                highContrast: widget.highContrast,
                visualFocus: widget.visualFocus,
              ),
              _ControlButton(
                tooltip: 'Ir para o fim',
                semanticLabel: 'Ir para o fim do vídeo',
                icon: Icons.skip_next,
                onPressed: () => _controller.seekTo(_controller.duration),
                highContrast: widget.highContrast,
                visualFocus: widget.visualFocus,
              ),
              Icon(Icons.volume_up, color: secondary),
              SizedBox(
                width: 150,
                child: Semantics(
                  label: 'Volume do áudio final com audiodescrição',
                  value: '${(_controller.volume * 100).round()} por cento',
                  child: Slider(
                    value: _controller.volume,
                    activeColor: accent,
                    onChanged: _controller.setVolume,
                  ),
                ),
              ),
              Tooltip(
                message: 'Velocidade de reprodução',
                child: Semantics(
                  label: 'Velocidade de reprodução',
                  value: '${_controller.playbackSpeed} vezes',
                  child: DropdownButton<double>(
                    value: _controller.playbackSpeed,
                    items: const [0.75, 1.0, 1.25, 1.5, 2.0]
                        .map(
                          (speed) => DropdownMenuItem(
                            value: speed,
                            child: Text('${speed}x'),
                          ),
                        )
                        .toList(),
                    onChanged: (speed) {
                      if (speed != null) _controller.setPlaybackSpeed(speed);
                    },
                  ),
                ),
              ),
              _ControlButton(
                tooltip: _expandedVideo
                    ? 'Sair da tela ampliada'
                    : 'Ampliar vídeo',
                semanticLabel: _expandedVideo
                    ? 'Sair da tela ampliada'
                    : 'Ampliar vídeo',
                icon: _expandedVideo ? Icons.fullscreen_exit : Icons.fullscreen,
                onPressed: () =>
                    setState(() => _expandedVideo = !_expandedVideo),
                highContrast: widget.highContrast,
                visualFocus: widget.visualFocus,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppStatusMessage(
          type: AppMessageType.information,
          title: 'Áudio sincronizado',
          message:
              'O vídeo original está silenciado. O volume controla a mixagem final com áudio original e audiodescrição. Espaço reproduz ou pausa; ← e → deslocam 5 segundos.',
          highContrast: widget.highContrast,
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}

class _ControlButton extends StatelessWidget {
  const _ControlButton({
    required this.tooltip,
    required this.semanticLabel,
    required this.icon,
    required this.onPressed,
    required this.highContrast,
    required this.visualFocus,
  });

  final String tooltip;
  final String semanticLabel;
  final IconData icon;
  final VoidCallback onPressed;
  final bool highContrast;
  final bool visualFocus;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accentFor(highContrast);
    return Semantics(
      child: IconButton(
        tooltip: semanticLabel,
        onPressed: onPressed,
        icon: Icon(icon),
        color: accent,
        style: IconButton.styleFrom(
          side: visualFocus ? BorderSide(color: accent) : null,
        ),
      ),
    );
  }
}
