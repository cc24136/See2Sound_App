import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:video_player/video_player.dart';
import 'package:see2sound_app/features/player/media_file_validation.dart';
import 'package:see2sound_app/features/player/synchronized_media_controller.dart';
import 'support/wav_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late File videoFile;
  late File audioFile;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('see2sound-media-init-');
    videoFile = await File('${directory.path}/vídeo.mp4').writeAsBytes([1]);
    audioFile = await File(
      '${directory.path}/descrição.wav',
    ).writeAsBytes(pcmWav());
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  SynchronizedMediaController makeController(
    _TestVideo video,
    _TestAudio audio,
  ) => SynchronizedMediaController(
    videoPath: videoFile.path,
    audioPath: audioFile.path,
    videoFactory: (_) => video,
    audioFactory: () => audio,
    loadTimeout: const Duration(milliseconds: 35),
    initializationTimeout: const Duration(seconds: 1),
  );

  test('arquivo ausente impede criação dos dois players', () async {
    var constructed = false;
    final controller = SynchronizedMediaController(
      videoPath: videoFile.path,
      audioPath: '${directory.path}/ausente.wav',
      videoFactory: (_) {
        constructed = true;
        return _TestVideo();
      },
    );
    await expectLater(
      controller.initialize(),
      throwsA(isA<PlaybackFileException>()),
    );
    expect(constructed, isFalse);
    expect(controller.isInitialized, isFalse);
    expect(controller.initializationStage, MediaInitializationStage.failed);
    controller.dispose();
  });

  test(
    'setFilePath pendente encerra inicialização e não aceita conclusão tardia',
    () async {
      final video = _TestVideo();
      final audio = _TestAudio()..pendingLoad = Completer<Duration?>();
      final controller = makeController(video, audio);
      await expectLater(
        controller.initialize(),
        throwsA(
          isA<PlaybackFileException>().having(
            (e) => e.message,
            'mensagem',
            contains('não respondeu a tempo'),
          ),
        ),
      );
      expect(controller.initializationStage, MediaInitializationStage.failed);
      audio.pendingLoad!.complete(const Duration(seconds: 15));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.isInitialized, isFalse);
      expect(audio.volumeCalls, 0);
      expect(video.disposals, 1);
      expect(audio.disposals, 1);
      controller.dispose();
    },
  );

  test(
    'erro de decodificação assíncrono resolve load mesmo se seu Future não termina',
    () async {
      final video = _TestVideo();
      final audio = _TestAudio()..pendingLoad = Completer<Duration?>();
      final controller = makeController(video, audio);
      final pending = controller.initialize();
      final expectation = expectLater(
        pending,
        throwsA(isA<PlaybackFileException>()),
      );
      await audio.loadEntered.future;
      audio.errors.add(PlayerException(1, 'native failure', null));
      await expectation;
      expect(controller.errorMessage, contains('carregar o áudio'));
      expect(controller.errorMessage, isNot(contains('native failure')));
      controller.dispose();
    },
  );

  test(
    'dispose durante load não inicia volume, timer ou notificações tardias',
    () async {
      final video = _TestVideo();
      final audio = _TestAudio()..pendingLoad = Completer<Duration?>();
      final controller = makeController(video, audio);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final pending = controller.initialize();
      await audio.loadEntered.future;
      final before = notifications;
      controller.dispose();
      audio.pendingLoad!.complete(const Duration(seconds: 15));
      await pending;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(notifications, before);
      expect(audio.volumeCalls, 0);
      expect(video.disposals, 1);
      expect(audio.disposals, 1);
    },
  );

  test(
    'initialize compartilhado e controles preservam sincronização sem bloquear em play',
    () async {
      final video = _TestVideo();
      final audio = _TestAudio();
      final controller = makeController(video, audio);
      final first = controller.initialize();
      final second = controller.initialize();
      expect(identical(first, second), isTrue);
      await first;
      expect(video.value.volume, 0);
      await controller.play().timeout(const Duration(milliseconds: 200));
      expect(controller.isPlaying, isTrue);
      expect(audio.playing, isTrue);
      await controller.pause().timeout(const Duration(milliseconds: 200));
      expect(controller.isPlaying, isFalse);
      expect(audio.playing, isFalse);
      await controller.seekTo(const Duration(seconds: 5));
      expect(video.value.position, const Duration(seconds: 5));
      expect(audio.position, video.value.position);
      await controller.setVolume(0.4);
      await controller.setPlaybackSpeed(1.25);
      expect(audio.currentVolume, 0.4);
      expect(audio.currentSpeed, 1.25);
      expect(video.value.playbackSpeed, 1.25);
      expect(video.value.volume, 0);
      await controller.restart();
      expect(audio.position, Duration.zero);
      controller.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 20));
    },
  );

  test('vídeo pendente também tem timeout e não chega ao áudio', () async {
    final video = _TestVideo()..pendingInitialization = Completer<void>();
    final audio = _TestAudio();
    final controller = makeController(video, audio);
    await expectLater(
      controller.initialize(),
      throwsA(isA<PlaybackFileException>()),
    );
    expect(audio.loadEntered.isCompleted, isFalse);
    video.pendingInitialization!.complete();
    controller.dispose();
    await audio.dispose();
  });
}

// Test doubles exist only in this test file. Production always uses native plugins.
class _TestVideo extends VideoPlayerController {
  _TestVideo() : super.asset('test-only');
  Completer<void>? pendingInitialization;
  int disposals = 0;
  @override
  Future<void> initialize() async {
    if (pendingInitialization != null) await pendingInitialization!.future;
    if (disposals > 0) return;
    value = const VideoPlayerValue(
      duration: Duration(seconds: 15),
      size: Size(1920, 1080),
      isInitialized: true,
    );
  }

  @override
  Future<void> setVolume(double v) async {
    value = value.copyWith(volume: v);
  }

  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> seekTo(Duration p) async {
    value = value.copyWith(position: p);
  }

  @override
  Future<void> setPlaybackSpeed(double s) async {
    value = value.copyWith(playbackSpeed: s);
  }

  @override
  Future<void> dispose() async {
    if (disposals++ == 0) await super.dispose();
  }
}

class _TestAudio extends AudioPlayer {
  _TestAudio()
    : super(
        handleInterruptions: false,
        handleAudioSessionActivation: false,
        androidApplyAudioAttributes: false,
      );
  final errors = StreamController<PlayerException>.broadcast();
  final loadEntered = Completer<void>();
  Completer<Duration?>? pendingLoad;
  Completer<void>? _play;
  Duration _position = Duration.zero;
  bool _playing = false;
  int disposals = 0;
  int volumeCalls = 0;
  double currentVolume = 1;
  double currentSpeed = 1;
  @override
  Stream<PlayerException> get errorStream => errors.stream;
  @override
  Duration get position => _position;
  @override
  bool get playing => _playing;
  @override
  Future<Duration?> setFilePath(
    String path, {
    Duration? initialPosition,
    bool preload = true,
    dynamic tag,
  }) async {
    if (!loadEntered.isCompleted) loadEntered.complete();
    return pendingLoad == null
        ? const Duration(seconds: 15)
        : pendingLoad!.future;
  }

  @override
  Future<void> play() {
    _playing = true;
    _play = Completer<void>();
    return _play!.future;
  }

  @override
  Future<void> pause() async {
    _playing = false;
    if (_play != null && !_play!.isCompleted) _play!.complete();
  }

  @override
  Future<void> stop() => pause();
  @override
  Future<void> seek(Duration? p, {int? index}) async {
    _position = p ?? Duration.zero;
  }

  @override
  Future<void> setVolume(double v) async {
    volumeCalls++;
    currentVolume = v;
  }

  @override
  Future<void> setSpeed(double s) async {
    currentSpeed = s;
  }

  @override
  Future<void> dispose() async {
    if (disposals++ > 0) return;
    await errors.close();
    await super.dispose();
  }
}
