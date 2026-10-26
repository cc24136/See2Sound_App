import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:video_player/video_player.dart';
import 'package:see2sound_app/features/player/synchronized_media_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const videoPath = String.fromEnvironment('SEE2SOUND_NATIVE_VIDEO');
  const audioPath = String.fromEnvironment('SEE2SOUND_NATIVE_AUDIO');
  const extraPaths = String.fromEnvironment('SEE2SOUND_NATIVE_EXTRA_VIDEOS');
  testWidgets(
    'Windows: abrir, reproduzir e descartar repetidamente com textura visível',
    (tester) async {
      for (var cycle = 0; cycle < 20; cycle++) {
        final controller = SynchronizedMediaController(
          videoPath: videoPath,
          audioPath: audioPath,
        );
        MediaInitializationStage? lastStage;
        controller.addListener(() {
          if (controller.initializationStage != lastStage) {
            lastStage = controller.initializationStage;
            debugPrint('LIFECYCLE_STAGE cycle=$cycle stage=$lastStage');
          }
        });
        try {
          await controller.initialize();
          await tester.pumpWidget(
            MaterialApp(
              home: Center(
                child: SizedBox(
                  width: 640,
                  height: 360,
                  child: VideoPlayer(controller.videoController),
                ),
              ),
            ),
          );
          await controller.play();
          await Future<void>.delayed(const Duration(milliseconds: 900));
          debugPrint(
            'VIDEO_STATE cycle=$cycle value=${controller.videoController.value} nativePosition=${await controller.videoController.position} audio=${controller.audioPlayer.position}',
          );
          expect(controller.duration, greaterThan(Duration.zero));
          expect(controller.audioPlayer.position, greaterThan(Duration.zero));
          expect(
            controller.position,
            greaterThan(Duration.zero),
            reason: 'cycle $cycle',
          );
          if (cycle.isEven) {
            await controller.pause();
            await controller.seekTo(const Duration(seconds: 1));
            await controller.play();
          }
        } finally {
          await controller.close();
          await tester.pumpWidget(const MaterialApp(home: SizedBox()));
        }
        await Future<void>.delayed(const Duration(milliseconds: 150));
        debugPrint('LIFECYCLE_CYCLE_OK $cycle');
      }
    },
  );
  testWidgets(
    'Windows: vídeo inválido não derruba o processo e próximo vídeo funciona',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'see2sound-video-invalid-',
      );
      final invalid = await File(
        '${directory.path}/invalid.mp4',
      ).writeAsString('invalid video');
      try {
        final video = VideoPlayerController.file(invalid);
        try {
          await expectLater(
            video.initialize().timeout(const Duration(seconds: 12)),
            throwsA(anything),
          );
        } finally {
          await video.dispose().timeout(const Duration(seconds: 8));
        }
        final next = VideoPlayerController.file(File(videoPath));
        try {
          await next.initialize().timeout(const Duration(seconds: 12));
          await next.play();
          await Future<void>.delayed(const Duration(milliseconds: 900));
          expect(next.value.isInitialized, isTrue);
          expect(next.value.position, greaterThan(Duration.zero));
        } finally {
          await next.dispose().timeout(const Duration(seconds: 8));
        }
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
  testWidgets('Windows: fechar durante inicialização e reabrir', (
    tester,
  ) async {
    for (var cycle = 0; cycle < 5; cycle++) {
      final controller = SynchronizedMediaController(
        videoPath: videoPath,
        audioPath: audioPath,
      );
      final pending = controller.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await controller.close();
      await pending;
    }
    final next = SynchronizedMediaController(
      videoPath: videoPath,
      audioPath: audioPath,
    );
    try {
      await next.initialize();
      await next.play();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect(next.position, greaterThan(Duration.zero));
      expect(next.audioPlayer.position, greaterThan(Duration.zero));
    } finally {
      await next.close();
    }
  });
  testWidgets('Windows: vídeos adicionais UHD e retrato', (tester) async {
    for (final path in extraPaths.split(';')) {
      final video = VideoPlayerController.file(File(path));
      try {
        await video.initialize().timeout(const Duration(seconds: 12));
        expect(video.value.duration, greaterThan(Duration.zero));
        await video.setVolume(0);
        await tester.pumpWidget(MaterialApp(home: VideoPlayer(video)));
        await video.play();
        await Future<void>.delayed(const Duration(milliseconds: 900));
        expect(video.value.position, greaterThan(Duration.zero));
        await video.pause();
        await video.seekTo(const Duration(seconds: 1));
      } finally {
        await video.dispose().timeout(const Duration(seconds: 8));
        await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      }
    }
  }, skip: extraPaths.isEmpty);
}
