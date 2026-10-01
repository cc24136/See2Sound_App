import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';

class SynchronizedMediaController extends ChangeNotifier {
  SynchronizedMediaController({
    required String videoPath,
    required String audioPath,
    this.driftThreshold = const Duration(milliseconds: 250),
  }) : videoController = VideoPlayerController.file(File(videoPath)),
       audioPlayer = AudioPlayer(),
       _audioPath = audioPath;

  final VideoPlayerController videoController;
  final AudioPlayer audioPlayer;
  final String _audioPath;
  final Duration driftThreshold;

  Timer? _driftTimer;
  bool _initialized = false;
  bool _disposed = false;
  bool _correctingDrift = false;
  bool _handlingEnd = false;
  double _volume = 1;
  double _playbackSpeed = 1;

  bool get isInitialized => _initialized;
  bool get isPlaying => _initialized && videoController.value.isPlaying;
  Duration get position =>
      _initialized ? videoController.value.position : Duration.zero;
  Duration get duration =>
      _initialized ? videoController.value.duration : Duration.zero;
  double get volume => _volume;
  double get playbackSpeed => _playbackSpeed;

  Future<void> initialize() async {
    await videoController.initialize();
    await videoController.setVolume(0);
    await audioPlayer.setFilePath(_audioPath);
    await audioPlayer.setVolume(_volume);

    if (_disposed) return;
    _initialized = true;
    videoController.addListener(_onVideoChanged);
    _driftTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _correctDrift(),
    );
    notifyListeners();
  }

  Future<void> togglePlayback() => isPlaying ? pause() : play();

  Future<void> play() async {
    if (!_initialized || _disposed) return;
    final currentPosition = videoController.value.position;
    final videoDuration = videoController.value.duration;
    if (videoDuration > Duration.zero &&
        currentPosition >= videoDuration - const Duration(milliseconds: 200)) {
      await seekTo(Duration.zero);
    } else {
      await audioPlayer.seek(currentPosition);
    }

    unawaited(audioPlayer.play());
    await videoController.play();
    if (!_disposed) notifyListeners();
  }

  Future<void> pause() async {
    if (!_initialized || _disposed) return;
    await videoController.pause();
    await audioPlayer.pause();
    if (!_disposed) notifyListeners();
  }

  Future<void> seekTo(Duration requestedPosition) async {
    if (!_initialized || _disposed) return;
    final boundedPosition = _boundedPosition(requestedPosition);
    await videoController.seekTo(boundedPosition);
    await audioPlayer.seek(boundedPosition);
    if (!_disposed) notifyListeners();
  }

  Future<void> seekBy(Duration offset) => seekTo(position + offset);

  Future<void> restart() => seekTo(Duration.zero);

  Future<void> setVolume(double value) async {
    _volume = value.clamp(0, 1);
    await audioPlayer.setVolume(_volume);
    if (!_disposed) notifyListeners();
  }

  Future<void> setPlaybackSpeed(double value) async {
    if (!_initialized || _disposed) return;
    _playbackSpeed = value.clamp(0.5, 2);
    await Future.wait([
      videoController.setPlaybackSpeed(_playbackSpeed),
      audioPlayer.setSpeed(_playbackSpeed),
    ]);
    if (!_disposed) notifyListeners();
  }

  Duration _boundedPosition(Duration requestedPosition) {
    if (requestedPosition < Duration.zero) return Duration.zero;
    final videoDuration = duration;
    if (videoDuration > Duration.zero && requestedPosition > videoDuration) {
      return videoDuration;
    }
    return requestedPosition;
  }

  void _onVideoChanged() {
    if (_disposed || !_initialized) return;
    final value = videoController.value;
    if (value.hasError) {
      notifyListeners();
      return;
    }

    final reachedEnd =
        value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 100);
    if (reachedEnd && !_handlingEnd) {
      _handlingEnd = true;
      unawaited(
        audioPlayer.pause().whenComplete(() {
          _handlingEnd = false;
        }),
      );
    }
    notifyListeners();
  }

  Future<void> _correctDrift() async {
    if (_disposed ||
        !_initialized ||
        !videoController.value.isPlaying ||
        _correctingDrift) {
      return;
    }

    final difference = (videoController.value.position - audioPlayer.position)
        .abs();
    if (difference <= driftThreshold) return;

    _correctingDrift = true;
    try {
      await audioPlayer.seek(videoController.value.position);
    } finally {
      _correctingDrift = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _driftTimer?.cancel();
    if (_initialized) videoController.removeListener(_onVideoChanged);
    unawaited(videoController.dispose());
    unawaited(audioPlayer.dispose());
    super.dispose();
  }
}
