import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

import 'media_file_validation.dart';

enum MediaInitializationStage { validatingFiles, video, audio, ready, failed }

class SynchronizedMediaController extends ChangeNotifier {
  SynchronizedMediaController({
    required String videoPath,
    required String audioPath,
    this.driftThreshold = const Duration(milliseconds: 250),
    this.initializationTimeout = const Duration(seconds: 30),
    this.loadTimeout = const Duration(seconds: 12),
    this.commandTimeout = const Duration(seconds: 15),
    @visibleForTesting VideoPlayerController Function(File)? videoFactory,
    @visibleForTesting AudioPlayer Function()? audioFactory,
  }) : _videoPath = videoPath,
       _audioPath = audioPath,
       _videoFactory = videoFactory ?? VideoPlayerController.file,
       _audioFactory = audioFactory ?? AudioPlayer.new;

  final String _videoPath;
  final String _audioPath;
  final Duration driftThreshold;
  final Duration initializationTimeout;
  final Duration loadTimeout;
  final Duration commandTimeout;
  final VideoPlayerController Function(File) _videoFactory;
  final AudioPlayer Function() _audioFactory;
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  VideoPlayerController get videoController => _videoController!;
  AudioPlayer get audioPlayer => _audioPlayer!;

  Timer? _driftTimer;
  bool _initialized = false;
  bool _disposed = false;
  bool _initializationFailed = false;
  bool _videoListenerAttached = false;
  bool _correctingDrift = false;
  bool _handlingEnd = false;
  Future<void> _commands = Future<void>.value();
  Future<void>? _initialization;
  Future<void>? _release;
  final _initializationError = Completer<void>();
  StreamSubscription<PlayerException>? _audioErrors;
  String? _errorMessage;
  MediaInitializationStage _stage = MediaInitializationStage.validatingFiles;
  double _volume = 1;
  double _playbackSpeed = 1;

  bool get isInitialized => _initialized;
  bool get isPlaying =>
      _initialized && !_disposed && videoController.value.isPlaying;
  Duration get position => _initialized && !_disposed
      ? videoController.value.position
      : Duration.zero;
  Duration get duration => _initialized && !_disposed
      ? videoController.value.duration
      : Duration.zero;
  double get volume => _volume;
  double get playbackSpeed => _playbackSpeed;
  String? get errorMessage => _errorMessage;
  MediaInitializationStage get initializationStage => _stage;
  String get initializationMessage => switch (_stage) {
    MediaInitializationStage.validatingFiles => 'Verificando os arquivos...',
    MediaInitializationStage.video => 'Preparando o vídeo...',
    MediaInitializationStage.audio => 'Preparando a audiodescrição...',
    MediaInitializationStage.ready => 'Pronto para reprodução.',
    MediaInitializationStage.failed =>
      _errorMessage ?? 'Não foi possível preparar a reprodução.',
  };
  bool get _aborted => _disposed || _initializationFailed;

  Future<void> initialize() => _initialization ??= _initializeBounded();

  Future<void> _initializeBounded() async {
    if (_disposed) return;
    try {
      await Future.any<void>([
        _initializeMedia(),
        _initializationError.future,
      ]).timeout(initializationTimeout);
    } catch (error, stackTrace) {
      if (_disposed) return;
      final failedStage = _stage;
      _initializationFailed = true;
      _initialized = false;
      _errorMessage = _initializationMessage(error, failedStage);
      _stage = MediaInitializationStage.failed;
      debugPrint(
        '[See2Sound] Falha ao inicializar mídia (${failedStage.name}): $error',
      );
      debugPrint('$stackTrace');
      _notify();
      unawaited(_releaseMedia());
      throw PlaybackFileException(_errorMessage!);
    }
  }

  String _initializationMessage(Object error, MediaInitializationStage stage) {
    if (error is PlaybackFileException) return error.message;
    if (error is TimeoutException) {
      return stage == MediaInitializationStage.audio
          ? 'O áudio da audiodescrição não respondeu a tempo. Tente abrir o vídeo novamente.'
          : 'A preparação do vídeo demorou mais que o esperado. Tente novamente.';
    }
    return stage == MediaInitializationStage.audio
        ? 'Não foi possível carregar o áudio da audiodescrição. Verifique o arquivo WAV ou gere o áudio novamente.'
        : 'Não foi possível carregar o vídeo. Verifique o arquivo e o formato de vídeo.';
  }

  void _setStage(MediaInitializationStage stage) {
    _stage = stage;
    _notify();
  }

  Future<void> _initializeMedia() async {
    final video = await validatePlaybackFile(_videoPath, audio: false);
    if (_aborted) return;
    final audio = await validatePlaybackFile(_audioPath, audio: true);
    if (_aborted) return;
    debugPrint('[See2Sound] Vídeo local validado: ${video.path}');
    debugPrint('[See2Sound] WAV local validado: ${audio.path}');

    _videoController = _videoFactory(video);
    _setStage(MediaInitializationStage.video);
    if (_aborted) return;
    await videoController.initialize().timeout(loadTimeout);
    if (_aborted) return;
    await videoController.setVolume(0).timeout(loadTimeout);
    if (_aborted) return;

    _audioPlayer = _audioFactory();
    _audioErrors = audioPlayer.errorStream.listen((error) {
      if (_aborted) return;
      if (!_initialized) {
        if (!_initializationError.isCompleted) {
          _initializationError.completeError(error);
        }
      } else {
        unawaited(_handleError(error, StackTrace.current));
      }
    });
    _setStage(MediaInitializationStage.audio);
    if (_aborted) return;
    // Pass the OS path unchanged. just_audio builds the file URI; the Windows
    // implementation must decode it without double-escaping spaces/Unicode.
    final audioDuration = await audioPlayer
        .setFilePath(audio.path)
        .timeout(loadTimeout);
    if (_aborted) return;
    if (audioDuration == null || audioDuration <= Duration.zero) {
      throw const PlaybackFileException(
        'O áudio da audiodescrição não possui uma duração válida. Gere o áudio novamente.',
      );
    }
    await audioPlayer.setVolume(_volume).timeout(loadTimeout);
    if (_aborted) return;
    _initialized = true;
    videoController.addListener(_onVideoChanged);
    _videoListenerAttached = true;
    _driftTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _run(_correctDrift),
    );
    _setStage(MediaInitializationStage.ready);
  }

  Future<void> _run(Future<void> Function() command) {
    _commands = _commands.then((_) async {
      if (!_initialized || _disposed || _errorMessage != null) return;
      try {
        await command().timeout(commandTimeout);
      } catch (error, stackTrace) {
        await _handleError(error, stackTrace);
      }
    });
    return _commands;
  }

  Future<void> _handleError(Object error, StackTrace stackTrace) async {
    debugPrint('[See2Sound] Falha na reprodução: $error');
    debugPrint('$stackTrace');
    if (_disposed || _errorMessage != null) return;
    _errorMessage =
        'Não foi possível continuar a reprodução da audiodescrição. Tente abrir o vídeo novamente.';
    _driftTimer?.cancel();
    _notify();
    await Future.wait([
      _safely(() => videoController.pause(), const Duration(seconds: 3)),
      _safely(() => audioPlayer.pause(), const Duration(seconds: 3)),
    ]);
    unawaited(_releaseMedia());
  }

  Future<void> togglePlayback() => _run(() => isPlaying ? _pause() : _play());
  Future<void> play() => _run(_play);
  Future<void> pause() => _run(_pause);
  Future<void> seekTo(Duration position) => _run(() => _seekTo(position));

  Future<void> _play() async {
    if (_disposed) return;
    final currentPosition = videoController.value.position;
    final videoDuration = videoController.value.duration;
    if (videoController.value.isCompleted ||
        (videoDuration > Duration.zero && currentPosition >= videoDuration)) {
      await _seekTo(Duration.zero);
    } else {
      await audioPlayer.seek(currentPosition);
    }
    if (_disposed || _errorMessage != null) return;
    await videoController.play();
    if (_disposed || _errorMessage != null) return;
    // just_audio.play completes on pause/end, so it must not block the command queue.
    unawaited(
      audioPlayer.play().catchError(
        (Object error, StackTrace stackTrace) =>
            _handleError(error, stackTrace),
      ),
    );
    _notify();
  }

  Future<void> _pause() async {
    if (_disposed) return;
    await videoController.pause();
    if (_disposed) return;
    await audioPlayer.pause();
    _notify();
  }

  Future<void> _seekTo(Duration requestedPosition) async {
    if (_disposed) return;
    final boundedPosition = _boundedPosition(requestedPosition);
    await videoController.seekTo(boundedPosition);
    if (_disposed) return;
    await audioPlayer.seek(boundedPosition);
    _notify();
  }

  Future<void> seekBy(Duration offset) =>
      _run(() => _seekTo(position + offset));
  Future<void> restart() => seekTo(Duration.zero);

  Future<void> setVolume(double value) => _run(() async {
    _volume = value.clamp(0, 1);
    await audioPlayer.setVolume(_volume);
    _notify();
  });

  Future<void> setPlaybackSpeed(double value) => _run(() async {
    _playbackSpeed = value.clamp(0.5, 2);
    await Future.wait([
      videoController.setPlaybackSpeed(_playbackSpeed),
      audioPlayer.setSpeed(_playbackSpeed),
    ]);
    _notify();
  });

  Duration _boundedPosition(Duration requestedPosition) {
    if (requestedPosition < Duration.zero) return Duration.zero;
    if (duration > Duration.zero && requestedPosition > duration) {
      return duration;
    }
    return requestedPosition;
  }

  void _onVideoChanged() {
    if (_disposed || !_initialized || _errorMessage != null) return;
    final value = videoController.value;
    if (value.hasError) {
      unawaited(
        _handleError(StateError('Video playback failed'), StackTrace.current),
      );
      return;
    }
    if (value.isCompleted && !_handlingEnd) {
      _handlingEnd = true;
      unawaited(
        _run(() async {
          try {
            if (_disposed || !videoController.value.isCompleted) return;
            await audioPlayer.pause();
          } finally {
            _handlingEnd = false;
          }
        }),
      );
    }
    _notify();
  }

  Future<void> _correctDrift() async {
    if (_disposed || !isPlaying || _correctingDrift) return;
    if (!requiresDriftCorrection(
      videoPosition: videoController.value.position,
      audioPosition: audioPlayer.position,
      threshold: driftThreshold,
    )) {
      return;
    }
    _correctingDrift = true;
    try {
      await audioPlayer.seek(videoController.value.position);
    } finally {
      _correctingDrift = false;
    }
  }

  @visibleForTesting
  static bool requiresDriftCorrection({
    required Duration videoPosition,
    required Duration audioPosition,
    required Duration threshold,
  }) => (videoPosition - audioPosition).abs() > threshold;

  Future<void> _safely(Future<void> Function() action, Duration timeout) async {
    try {
      await action().timeout(timeout);
    } catch (error) {
      debugPrint('[See2Sound] Falha ao interromper/liberar mídia: $error');
    }
  }

  Future<void> _releaseMedia() => _release ??= () async {
    _driftTimer?.cancel();
    if (_videoListenerAttached) {
      _videoController?.removeListener(_onVideoChanged);
      _videoListenerAttached = false;
    }
    final errors = _audioErrors;
    _audioErrors = null;
    if (errors != null) {
      await _safely(errors.cancel, const Duration(seconds: 3));
    }
    await Future.wait([
      if (_videoController != null)
        _safely(_videoController!.dispose, const Duration(seconds: 5)),
      if (_audioPlayer != null)
        _safely(_audioPlayer!.dispose, const Duration(seconds: 5)),
    ]);
  }();

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    if (!_initializationError.isCompleted) _initializationError.complete();
    unawaited(_releaseMedia());
    super.dispose();
  }
}
