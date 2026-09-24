import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../core/constants/app_colors.dart';
import 'synchronized_media_controller.dart';

class PlayerPage extends StatefulWidget {
  const PlayerPage({
    super.key,
    required this.videoPath,
    required this.audioPath,
    required this.filename,
    required this.highContrast,
    required this.visualFocus,
  });

  final String videoPath;
  final String audioPath;
  final String filename;
  final bool highContrast;
  final bool visualFocus;

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  late final SynchronizedMediaController _controller;
  Object? _initializationError;
  Duration? _pendingSeek;

  @override
  void initState() {
    super.initState();
    _controller = SynchronizedMediaController(
      videoPath: widget.videoPath,
      audioPath: widget.audioPath,
    )..addListener(_refresh);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _controller.initialize();
    } on Object catch (error) {
      if (mounted) {
        setState(() => _initializationError = error);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final background = AppColors.backgroundFor(widget.highContrast);
    final panel = AppColors.panelFor(widget.highContrast);
    final border = AppColors.borderFor(widget.highContrast);
    final text = AppColors.textPrimaryFor(widget.highContrast);
    final secondary = AppColors.textSecondaryFor(widget.highContrast);
    final accent = AppColors.accentFor(widget.highContrast);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: AppColors.topBarFor(widget.highContrast),
        foregroundColor: text,
        leading: IconButton(
          tooltip: 'Voltar para Gerar',
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
        },
        child: Focus(
          autofocus: true,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: panel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: border,
                      width: widget.highContrast ? 2 : 1,
                    ),
                  ),
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
    if (_initializationError != null) {
      return Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            children: [
              Icon(Icons.error_outline, color: accent, size: 48),
              const SizedBox(height: 16),
              Text(
                'Não foi possível abrir o vídeo e a audiodescrição.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_controller.isInitialized) {
      return Semantics(
        liveRegion: true,
        label: 'Preparando reprodução',
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            children: [
              CircularProgressIndicator(color: accent),
              const SizedBox(height: 16),
              Text('Preparando reprodução...', style: TextStyle(color: text)),
            ],
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
      children: [
        Semantics(
          label: 'Vídeo ${widget.filename} com audiodescrição',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: AspectRatio(
              aspectRatio: video.aspectRatio == 0 ? 16 / 9 : video.aspectRatio,
              child: ColoredBox(
                color: Colors.black,
                child: VideoPlayer(_controller.videoController),
              ),
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
        Wrap(
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
              onPressed: () => _controller.seekBy(const Duration(seconds: -5)),
              highContrast: widget.highContrast,
              visualFocus: widget.visualFocus,
            ),
            Semantics(
              button: true,
              label: _controller.isPlaying ? 'Pausar' : 'Reproduzir',
              child: Tooltip(
                message: _controller.isPlaying ? 'Pausar' : 'Reproduzir',
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
            Icon(Icons.volume_up, color: secondary),
            SizedBox(
              width: 150,
              child: Semantics(
                label: 'Volume da audiodescrição',
                value: '${(_controller.volume * 100).round()} por cento',
                child: Slider(
                  value: _controller.volume,
                  activeColor: accent,
                  onChanged: _controller.setVolume,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Atalhos: Espaço reproduz ou pausa; setas esquerda e direita deslocam 5 segundos.',
          textAlign: TextAlign.center,
          style: TextStyle(color: secondary, fontSize: 13),
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
      button: true,
      label: semanticLabel,
      child: IconButton(
        tooltip: tooltip,
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
