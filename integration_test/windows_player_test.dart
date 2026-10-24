import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:see2sound_app/features/player/synchronized_media_controller.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const audioPath = String.fromEnvironment('SEE2SOUND_NATIVE_AUDIO');
  testWidgets('Windows: carrega WAV real com espaços e acentos', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('Verificação nativa de áudio')),
      ),
    );
    expect(Platform.isWindows, isTrue);
    expect(File(audioPath).isAbsolute, isTrue);
    expect(await File(audioPath).exists(), isTrue);
    expect(await File(audioPath).length(), greaterThan(44));
    final player = AudioPlayer();
    final errors = player.errorStream.listen(
      (error) => debugPrint(
        'NATIVE_AUDIO_ERROR code=${error.code} message=${error.message}',
      ),
    );
    try {
      final duration = await player
          .setFilePath(audioPath)
          .timeout(const Duration(seconds: 12));
      expect(duration, isNotNull);
      expect(duration!.inMilliseconds, greaterThan(14000));
      unawaited(player.play());
      await Future<void>.delayed(const Duration(milliseconds: 900));
      expect(player.position, greaterThan(Duration.zero));
      await player.pause().timeout(const Duration(seconds: 3));
    } finally {
      await errors.cancel();
      await player.dispose().timeout(const Duration(seconds: 5));
    }
  });
  const videoPath = String.fromEnvironment('SEE2SOUND_NATIVE_VIDEO');
  testWidgets(
    'Windows: vídeo e WAV reais sincronizados, controles e troca de controller',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Verificação nativa de sincronização')),
        ),
      );
      final controller = SynchronizedMediaController(
        videoPath: videoPath,
        audioPath: audioPath,
      );
      try {
        await controller.initialize();
        expect(controller.isInitialized, isTrue);
        expect(controller.videoController.value.volume, 0);
        await controller.play();
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        expect(controller.position, greaterThan(Duration.zero));
        expect(controller.audioPlayer.position, greaterThan(Duration.zero));
        await controller.pause();
        expect(controller.isPlaying, isFalse);
        expect(controller.audioPlayer.playing, isFalse);
        await controller.seekTo(const Duration(seconds: 5));
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(
          (controller.audioPlayer.position - controller.position).abs(),
          lessThan(const Duration(milliseconds: 700)),
        );
        await controller.setVolume(0.4);
        await controller.setPlaybackSpeed(1.25);
        expect(controller.audioPlayer.volume, closeTo(0.4, 0.001));
        expect(controller.audioPlayer.speed, 1.25);
        expect(controller.videoController.value.playbackSpeed, 1.25);
        expect(controller.videoController.value.volume, 0);
        await controller.play();
        await controller.audioPlayer.seek(
          Duration.zero,
        ); // Deliberately introduce measurable drift.
        await Future<void>.delayed(const Duration(milliseconds: 1600));
        await controller.pause();
        expect(
          (controller.audioPlayer.position - controller.position).abs(),
          lessThan(const Duration(milliseconds: 750)),
        );
        await controller.seekTo(controller.duration);
        await Future<void>.delayed(const Duration(milliseconds: 250));
        await controller.play();
        await Future<void>.delayed(const Duration(milliseconds: 700));
        expect(controller.position, lessThan(const Duration(seconds: 3)));
        await controller.pause();
        await controller.restart();
        expect(
          controller.audioPlayer.position,
          lessThan(const Duration(milliseconds: 300)),
        );
      } finally {
        controller.dispose();
      }
      final next = SynchronizedMediaController(
        videoPath: videoPath,
        audioPath: audioPath,
      );
      try {
        await next.initialize();
        await next.play();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        expect(next.audioPlayer.position, greaterThan(Duration.zero));
        await next.pause();
      } finally {
        next.dispose();
      }
    },
  );

  testWidgets(
    'Windows: arquivo ausente e WAV incompatível não deixam load pendente',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Verificação nativa de erros')),
        ),
      );
      final directory = await Directory.systemTemp.createTemp(
        'see2sound-native-errors-',
      );
      final invalid = await File(
        '${directory.path}/inválido.wav',
      ).writeAsString('arquivo inválido');
      try {
        for (final path in ['${directory.path}/ausente.wav', invalid.path]) {
          final player = AudioPlayer();
          try {
            await expectLater(
              player.setFilePath(path).timeout(const Duration(seconds: 12)),
              throwsA(isA<PlayerException>()),
            );
          } finally {
            await player.dispose().timeout(const Duration(seconds: 5));
          }
        }
      } finally {
        await directory.delete(recursive: true);
      }
    },
  );
}
